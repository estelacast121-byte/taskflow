import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'estado_agente.dart';
import 'herramientas_tareas.dart';
import 'modelo_agente.dart';
import 'repositorio_tareas_agente.dart';
import 'servicio_gemini_agente.dart';
import 'modelo_agente_simulado.dart';
import 'registro_agente.dart';

final modeloAgenteProvider = Provider<ModeloAgente>(
  (ref) => const String.fromEnvironment('AGENTE') == 'simulado'
      ? ModeloAgenteSimulado()
      : ServicioGeminiAgente(),
);

final agenteProvider = NotifierProvider<AgenteNotifier, EstadoAgente>(
  AgenteNotifier.new,
);

class AgenteNotifier extends Notifier<EstadoAgente> {
  static const maxIteraciones = 5;
  static const maxLlamadas = 10;
  late HerramientasTareas _herramientas;
  int _version = 0;
  int _siguienteConfirmacion = 0;
  bool _activo = false;
  bool _destruido = false;
  Completer<void>? _cancelacion;
  Completer<bool>? _confirmacion;
  AccionModificacion? _pendiente;

  @override
  EstadoAgente build() {
    _herramientas = HerramientasTareas(
      ref.read(repositorioTareasAgenteProvider),
    );
    ref.onDispose(() {
      _destruido = true;
      _interrumpir();
    });
    return const AgenteInactivo();
  }

  bool _vigente(int version) => !_destruido && _activo && version == _version;

  bool confirmar(int id, {required bool aprobada}) {
    final actual = state;
    if (!_activo ||
        actual is! AgenteEsperandoConfirmacion ||
        actual.confirmacionId != id ||
        _confirmacion == null ||
        _confirmacion!.isCompleted) {
      return false;
    }
    _confirmacion!.complete(aprobada);
    return true;
  }

  void _interrumpir() {
    _version++;
    _activo = false;
    final pendiente = _pendiente;
    _pendiente = null;
    if (pendiente != null) _herramientas.ejecutar(pendiente, aprobada: false);
    final confirmacion = _confirmacion;
    _confirmacion = null;
    if (confirmacion != null && !confirmacion.isCompleted) {
      confirmacion.complete(false);
    }
    final cancelacion = _cancelacion;
    _cancelacion = null;
    if (cancelacion != null && !cancelacion.isCompleted) cancelacion.complete();
  }

  void cancelar() {
    _interrumpir();
    if (!_destruido) state = const AgenteInactivo();
  }

  /// Devuelve false si hay una ejecución activa o la instrucción está vacía.
  Future<bool> iniciar(String instruccion) async {
    if (_destruido || _activo || instruccion.trim().isEmpty) return false;
    _activo = true;
    ref.read(registroAgenteProvider.notifier).limpiar();
    final version = ++_version;
    final cancelacion = Completer<void>();
    _cancelacion = cancelacion;
    final modelo = ref.read(modeloAgenteProvider);
    final historial = <IntercambioAgente>[];
    final ids = <String>{};
    final modificaciones = <String>{};
    var llamadas = 0;
    try {
      for (var iteracion = 1; iteracion <= maxIteraciones; iteracion++) {
        if (!_vigente(version)) return true;
        state = AgentePensando(iteracion);
        if (!_vigente(version)) return true;
        final respuesta = await Future.any<RespuestaModeloAgente>([
          modelo.consultar(ContextoAgente(instruccion.trim(), historial)),
          cancelacion.future.then<RespuestaModeloAgente>(
            (_) => throw const _Cancelado(),
          ),
        ]);
        if (!_vigente(version)) return true;
        if (respuesta is RespuestaFinal) {
          state = AgenteTerminado(respuesta.mensaje);
          return true;
        }
        final solicitud = respuesta as SolicitudHerramientas;
        final observaciones = <ObservacionHerramienta>[];
        void observar(String nombre, ObservacionHerramienta resultado) {
          observaciones.add(resultado);
          if (_vigente(version)) {
            ref
                .read(registroAgenteProvider.notifier)
                .agregar(ResultadoVisibleAgente(nombre, resultado));
          }
        }

        for (final llamada in solicitud.llamadas) {
          if (!_vigente(version)) return true;
          if (++llamadas > maxLlamadas) {
            state = const AgenteError(
              'Límite de llamadas a herramientas alcanzado.',
            );
            return true;
          }
          state = AgenteEjecutandoHerramienta(llamada.nombre, llamada.id);
          if (!_vigente(version)) return true;
          if (llamada.id.trim().isEmpty || !ids.add(llamada.id)) {
            observar(
              llamada.nombre,
              ObservacionHerramienta(
                llamada.id,
                false,
                'ID de llamada vacío o duplicado.',
              ),
            );
            continue;
          }
          try {
            final accion = _herramientas.preparar(
              llamada.nombre,
              llamada.argumentos,
            );
            switch (accion) {
              case AccionInvalida():
                observar(
                  llamada.nombre,
                  ObservacionHerramienta(
                    llamada.id,
                    false,
                    accion.mensaje,
                    tareas: accion.candidatos
                        .map(
                          (t) => <String, Object?>{
                            'id': t.id,
                            'titulo': t.titulo,
                          },
                        )
                        .toList(),
                  ),
                );
              case AccionLectura():
                observar(
                  llamada.nombre,
                  ObservacionHerramienta(
                    llamada.id,
                    true,
                    'Tareas listadas.',
                    tareas: accion.tareas
                        .map(
                          (t) => <String, Object?>{
                            'id': t.id,
                            'titulo': t.titulo,
                            'detalle': t.detalle,
                            'prioridad': t.prioridad,
                            'completada': t.completada,
                          },
                        )
                        .toList(),
                  ),
                );
              case AccionModificacion():
                final firma = _firma(accion);
                if (!modificaciones.add(firma)) {
                  _herramientas.ejecutar(accion, aprobada: false);
                  observar(
                    llamada.nombre,
                    ObservacionHerramienta(
                      llamada.id,
                      false,
                      'Modificación ya propuesta en esta instrucción; requiere una nueva instrucción.',
                    ),
                  );
                  continue;
                }
                final confirmacion = Completer<bool>();
                _confirmacion = confirmacion;
                _pendiente = accion;
                state = AgenteEsperandoConfirmacion(
                  ++_siguienteConfirmacion,
                  accion,
                );
                final aprobada = await confirmacion.future;
                if (!_vigente(version)) return true;
                _confirmacion = null;
                state = AgenteEjecutandoHerramienta(llamada.nombre, llamada.id);
                if (!_vigente(version)) return true;
                if (!_vigente(version)) return true;
                _pendiente = null;
                final resultado = _herramientas.ejecutar(
                  accion,
                  aprobada: aprobada,
                );
                observar(
                  llamada.nombre,
                  ObservacionHerramienta(
                    llamada.id,
                    resultado.exito,
                    resultado.mensaje,
                  ),
                );
            }
          } catch (_) {
            observar(
              llamada.nombre,
              ObservacionHerramienta(
                llamada.id,
                false,
                'Error al procesar la herramienta.',
              ),
            );
          }
        }
        historial.add(IntercambioAgente(solicitud, observaciones));
      }
      if (_vigente(version)) {
        state = const AgenteError('Límite de cinco iteraciones alcanzado.');
      }
    } on _Cancelado {
      // cancelar ya resolvió cualquier confirmación y actualizó el estado.
    } catch (_) {
      if (_vigente(version)) {
        state = const AgenteError('No se pudo consultar el modelo del agente.');
      }
    } finally {
      if (_version == version) {
        _activo = false;
        _cancelacion = null;
      }
    }
    return true;
  }

  static String _firma(AccionModificacion accion) {
    final claves = accion.argumentos.keys.toList()..sort();
    final datos = <String, Object?>{};
    for (final clave in claves) {
      final valor = accion.argumentos[clave];
      datos[clave] = valor is String
          ? valor.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ')
          : valor;
    }
    return '${accion.herramienta}:${jsonEncode(datos)}';
  }
}

class _Cancelado implements Exception {
  const _Cancelado();
}
