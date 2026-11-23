import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/agente/agente_notifier.dart';
import 'package:taskflow/agente/estado_agente.dart';
import 'package:taskflow/agente/modelo_agente.dart';
import 'package:taskflow/task_notifier.dart';

class ModeloSimulado implements ModeloAgente {
  ModeloSimulado(this.responder);
  final Future<RespuestaModeloAgente> Function(ContextoAgente, int) responder;
  final contextos = <ContextoAgente>[];
  @override
  Future<RespuestaModeloAgente> consultar(ContextoAgente contexto) {
    contextos.add(contexto);
    return responder(contexto, contextos.length);
  }
}

void main() {
  late ProviderContainer c;
  late AgenteNotifier agente;
  ProviderContainer montar(ModeloSimulado modelo) {
    c = ProviderContainer(
      overrides: [modeloAgenteProvider.overrideWithValue(modelo)],
    );
    agente = c.read(agenteProvider.notifier);
    addTearDown(c.dispose);
    return c;
  }

  SolicitudHerramientas pedir(
    String nombre,
    Map<String, dynamic> args, {
    String id = '1',
  }) => SolicitudHerramientas([LlamadaHerramienta(id, nombre, args)]);
  ModeloSimulado una(RespuestaModeloAgente respuesta) => ModeloSimulado(
    (_, n) async => n == 1 ? respuesta : const RespuestaFinal('Listo'),
  );
  Future<void> avanzar() => Future<void>.delayed(Duration.zero);
  List<Tarea> tareas() => c.read(taskProvider);

  test('lectura sin confirmación devuelve datos al modelo', () async {
    final m = una(pedir('listar_tareas', {}));
    montar(m);
    await agente.iniciar('Lista');
    expect(c.read(agenteProvider), isA<AgenteTerminado>());
    expect(
      m.contextos.last.intercambios.single.observaciones.single.tareas.length,
      3,
    );
    expect(tareas().length, 3);
  });
  test(
    'creación espera aprobación explícita y confirmación es de un solo uso',
    () async {
      final m = una(pedir('crear_tarea', {'titulo': 'Nueva tarea'}));
      montar(m);
      final fin = agente.iniciar('Crear');
      await avanzar();
      final estado = c.read(agenteProvider) as AgenteEsperandoConfirmacion;
      expect(tareas().length, 3);
      expect(
        agente.confirmar(estado.confirmacionId + 1, aprobada: true),
        false,
      );
      expect(agente.confirmar(estado.confirmacionId, aprobada: true), true);
      expect(agente.confirmar(estado.confirmacionId, aprobada: true), false);
      await fin;
      expect(tareas().length, 4);
      expect(
        m.contextos.last.intercambios.single.observaciones.single.exito,
        true,
      );
    },
  );
  for (final nombre in ['crear_tarea', 'eliminar_tarea']) {
    test('$nombre rechazada no modifica e informa al modelo', () async {
      final m = una(
        pedir(
          nombre,
          nombre == 'crear_tarea' ? {'titulo': 'Nueva tarea'} : {'id': 1},
        ),
      );
      montar(m);
      final antes = tareas();
      final fin = agente.iniciar('Acción');
      await avanzar();
      final estado = c.read(agenteProvider) as AgenteEsperandoConfirmacion;
      agente.confirmar(estado.confirmacionId, aprobada: false);
      await fin;
      expect(identical(tareas(), antes), true);
      expect(
        m.contextos.last.intercambios.single.observaciones.single.mensaje,
        contains('rechazada'),
      );
    });
  }
  test(
    'rechazo bloquea reintento con otro ID hasta nueva instrucción',
    () async {
      final m = ModeloSimulado(
        (_, n) async => n <= 2
            ? pedir('crear_tarea', {'titulo': 'Nueva tarea'}, id: '$n')
            : const RespuestaFinal('Fin'),
      );
      montar(m);
      final fin = agente.iniciar('Crear');
      await avanzar();
      final estado = c.read(agenteProvider) as AgenteEsperandoConfirmacion;
      agente.confirmar(estado.confirmacionId, aprobada: false);
      await fin;
      expect(tareas().length, 3);
      expect(
        m.contextos.last.intercambios.last.observaciones.single.mensaje,
        contains('nueva instrucción'),
      );
    },
  );
  for (final nombre in ['inexistente', 'crear_tarea']) {
    test('$nombre inválida se devuelve como observación', () async {
      final m = una(pedir(nombre, {}));
      montar(m);
      await agente.iniciar('Prueba');
      expect(
        m.contextos.last.intercambios.single.observaciones.single.exito,
        false,
      );
      expect(tareas().length, 3);
    });
  }
  test('máximo cinco consultas', () async {
    final m = ModeloSimulado(
      (_, n) async => pedir('listar_tareas', {}, id: '$n'),
    );
    montar(m);
    await agente.iniciar('Continuar');
    expect(m.contextos.length, 5);
    expect(c.read(agenteProvider), isA<AgenteError>());
  });
  test('máximo diez herramientas incluso en una respuesta', () async {
    final m = una(
      SolicitudHerramientas(
        List.generate(11, (i) => LlamadaHerramienta('$i', 'listar_tareas', {})),
      ),
    );
    montar(m);
    var ejecutadas = 0;
    c.listen(agenteProvider, (_, estado) {
      if (estado is AgenteEjecutandoHerramienta) ejecutadas++;
    });
    await agente.iniciar('Listar');
    expect(ejecutadas, 10);
    expect(c.read(agenteProvider), isA<AgenteError>());
    expect(m.contextos.length, 1);
  });
  test(
    'cancelar confirmación rechaza acción y permite nueva instrucción',
    () async {
      final m = una(pedir('eliminar_tarea', {'id': 1}));
      montar(m);
      final fin = agente.iniciar('Eliminar');
      await avanzar();
      final estado = c.read(agenteProvider) as AgenteEsperandoConfirmacion;
      agente.cancelar();
      await fin;
      expect(agente.confirmar(estado.confirmacionId, aprobada: true), false);
      expect(tareas().length, 3);
      expect(c.read(agenteProvider), isA<AgenteInactivo>());
      await agente.iniciar('Otra');
      expect(c.read(agenteProvider), isA<AgenteTerminado>());
    },
  );
  test(
    'resultado tardío tras cancelar no cambia estado ni ejecuta herramientas',
    () async {
      final pendiente = Completer<RespuestaModeloAgente>();
      final m = ModeloSimulado(
        (_, n) => n == 1
            ? pendiente.future
            : Future.value(const RespuestaFinal('Nueva')),
      );
      montar(m);
      final fin = agente.iniciar('Vieja');
      expect(await agente.iniciar('Solapada'), false);
      agente.cancelar();
      await fin;
      await agente.iniciar('Nueva');
      pendiente.complete(pedir('eliminar_tarea', {'id': 1}));
      await avanzar();
      expect((c.read(agenteProvider) as AgenteTerminado).mensaje, 'Nueva');
      expect(tareas().length, 3);
    },
  );
  test(
    'no ejecuta dos veces la misma modificación con IDs diferentes',
    () async {
      final m = una(
        SolicitudHerramientas([
          LlamadaHerramienta('1', 'crear_tarea', {'titulo': 'Nueva tarea'}),
          LlamadaHerramienta('2', 'crear_tarea', {'titulo': 'Nueva tarea'}),
          LlamadaHerramienta('1', 'eliminar_tarea', {'id': 1}),
        ]),
      );
      montar(m);
      final fin = agente.iniciar('Crear');
      await avanzar();
      final estado = c.read(agenteProvider) as AgenteEsperandoConfirmacion;
      agente.confirmar(estado.confirmacionId, aprobada: true);
      await fin;
      expect(tareas().length, 4);
      final obs = m.contextos.last.intercambios.single.observaciones;
      expect(obs.map((o) => o.exito), [true, false, false]);
    },
  );
  test('aprobación revalida tarea cambiada', () async {
    final m = una(pedir('eliminar_tarea', {'id': 1}));
    montar(m);
    final fin = agente.iniciar('Eliminar');
    await avanzar();
    final estado = c.read(agenteProvider) as AgenteEsperandoConfirmacion;
    c.read(taskProvider.notifier).completarTarea(1);
    agente.confirmar(estado.confirmacionId, aprobada: true);
    await fin;
    expect(tareas().length, 3);
    expect(
      m.contextos.last.intercambios.single.observaciones.single.exito,
      false,
    );
  });
  test(
    'cancelar inmediatamente después de aprobar impide la ejecución',
    () async {
      montar(una(pedir('eliminar_tarea', {'id': 1})));
      final fin = agente.iniciar('Eliminar');
      await avanzar();
      final estado = c.read(agenteProvider) as AgenteEsperandoConfirmacion;
      agente.confirmar(estado.confirmacionId, aprobada: true);
      agente.cancelar();
      await fin;
      expect(tareas().length, 3);
      expect(c.read(agenteProvider), isA<AgenteInactivo>());
    },
  );
  test('error de modelo produce estado de error', () async {
    montar(ModeloSimulado((_, _) async => throw StateError('Fallo')));
    await agente.iniciar('Prueba');
    expect(c.read(agenteProvider), isA<AgenteError>());
  });
  test('cancelación desde observador de estado antes de ejecutar', () async {
    montar(una(pedir('eliminar_tarea', {'id': 1})));
    var aprobada = false;
    c.listen(agenteProvider, (_, estado) {
      if (aprobada && estado is AgenteEjecutandoHerramienta) agente.cancelar();
    });
    final fin = agente.iniciar('Eliminar');
    await avanzar();
    final estado = c.read(agenteProvider) as AgenteEsperandoConfirmacion;
    aprobada = true;
    agente.confirmar(estado.confirmacionId, aprobada: true);
    await fin;
    expect(tareas().length, 3);
    expect(c.read(agenteProvider), isA<AgenteInactivo>());
  });
}
