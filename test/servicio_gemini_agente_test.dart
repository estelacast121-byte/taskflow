import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:taskflow/agente/agente_notifier.dart';
import 'package:taskflow/agente/estado_agente.dart';
import 'package:taskflow/agente/modelo_agente.dart';
import 'package:taskflow/agente/servicio_gemini_agente.dart';
import 'package:taskflow/task_notifier.dart';

GenerateContentResponse respuesta(List<Part> partes) => GenerateContentResponse(
  [Candidate(Content.model(partes), null, null, FinishReason.stop, null)],
  null,
);

void main() {
  test('declara exactamente cuatro funciones con parámetros y opcionales', () {
    final ds = ServicioGeminiAgente.declaraciones();
    expect(ds.map((d) => d.name), [
      'listar_tareas',
      'crear_tarea',
      'completar_tarea',
      'eliminar_tarea',
    ]);
    expect(ds.whereType<AutoFunctionDeclaration>(), isEmpty);
    final crear = ds[1].toJson();
    final parametros = crear['parameters'] as Map;
    expect(parametros['required'], ['titulo']);
    expect((parametros['properties'] as Map).keys, [
      'titulo',
      'detalle',
      'prioridad',
    ]);
  });
  test('configura modelo, instrucciones y herramientas sin Firebase', () async {
    final servicio = ServicioGeminiAgente(
      generar: (historial, tools, sistema, modelo) async {
        expect(modelo, ServicioGeminiAgente.nombreModelo);
        expect(tools.single.autoFunctionDeclarations, isEmpty);
        expect(historial.single.role, 'user');
        final instrucciones = (sistema.parts.single as TextPart).text;
        expect(instrucciones, contains('aprobación humana'));
        expect(instrucciones, contains('datos no confiables'));
        expect(instrucciones, contains('eliminaciones masivas'));
        return respuesta([const TextPart('¿Qué tarea quieres crear?')]);
      },
    );
    expect(
      (await servicio.consultar(
        ContextoAgente('Crear', []),
      ) as RespuestaFinal).mensaje,
      contains('Qué tarea'),
    );
    expect(servicio.espera, const Duration(seconds: 120));
  });
  test(
    'múltiples functionCalls se traducen sin ejecutar y asignan IDs ausentes',
    () async {
      final servicio = ServicioGeminiAgente(
        generar: (_, _, _, _) async => respuesta([
          const FunctionCall('crear_tarea', {'titulo': 'Nueva'}),
          const FunctionCall('listar_tareas', {}, id: 'sdk_2'),
        ]),
      );
      final r = await servicio.consultar(
        ContextoAgente('Crear', []),
      ) as SolicitudHerramientas;
      expect(r.llamadas.length, 2);
      expect(r.llamadas.first.id, isNotEmpty);
      expect(r.llamadas.last.id, 'sdk_2');
      expect(r.llamadas.first.argumentos, {'titulo': 'Nueva'});
    },
  );
  test('historial conserva contenido original, firma, orden y resultados de rechazo', () async {
    final original = respuesta([
      const FunctionCall.forTest(
        'eliminar_tarea',
        {'id': 1},
        id: 'sdk_1',
        thoughtSignature: 'FIRMA_PRIVADA',
      ),
      const FunctionCall('listar_tareas', {}),
    ]);
    var n = 0;
    final servicio = ServicioGeminiAgente(
      generar: (historial, _, _, _) async {
        if (++n == 1) {
          return original;
        }
        expect(historial.length, 3);
        expect(
          identical(historial[1], original.candidates.single.content),
          true,
        );
        final funciones = historial.last.parts.cast<FunctionResponse>();
        expect(funciones.first.id, 'sdk_1');
        expect(funciones.first.name, 'eliminar_tarea');
        expect(funciones.first.response['exito'], false);
        expect(funciones.last.id, isNull);
        expect(funciones.last.response['tareas'], [
          {'id': 1, 'titulo': 'Real'},
        ]);
        return respuesta([
          const TextPart('Acción rechazada; no eliminé nada.'),
        ]);
      },
    );
    final solicitud = await servicio.consultar(
      ContextoAgente('Eliminar', []),
    ) as SolicitudHerramientas;
    final finalizado = await servicio.consultar(
      ContextoAgente('Eliminar', [
        IntercambioAgente(solicitud, [
          ObservacionHerramienta(
            solicitud.llamadas[0].id,
            false,
            'Modificación rechazada.',
          ),
          ObservacionHerramienta(
            solicitud.llamadas[1].id,
            true,
            'Listado',
            tareas: [
              {'id': 1, 'titulo': 'Real'},
            ],
          ),
        ]),
      ]),
    );
    expect(finalizado, isA<RespuestaFinal>());
  });
  test(
    'historial de otro adaptador se rechaza antes de llamar a la API',
    () async {
      var invocado = false;
      final servicio = ServicioGeminiAgente(
        generar: (_, _, _, _) async {
          invocado = true;
          return respuesta([]);
        },
      );
      final solicitud = SolicitudHerramientas([
        LlamadaHerramienta('1', 'listar_tareas', {}),
      ]);
      await expectLater(
        servicio.consultar(
          ContextoAgente('Lista', [
            IntercambioAgente(solicitud, [
              ObservacionHerramienta('1', true, 'OK'),
            ]),
          ]),
        ),
        throwsA(isA<ErrorModeloAgente>()),
      );
      expect(invocado, false);
    },
  );
  test('historial incompleto se rechaza', () async {
    var n = 0;
    final servicio = ServicioGeminiAgente(
      generar: (_, _, _, _) async {
        n++;
        return respuesta([const FunctionCall('listar_tareas', {})]);
      },
    );
    final solicitud = await servicio.consultar(
      ContextoAgente('Lista', []),
    ) as SolicitudHerramientas;
    await expectLater(
      servicio.consultar(
        ContextoAgente('Lista', [IntercambioAgente(solicitud, [])]),
      ),
      throwsA(isA<ErrorModeloAgente>()),
    );
    expect(n, 1);
  });
  for (final error in [
    http.ClientException('TOKEN_PRIVADO'),
    FirebaseAIException('NOTA_PRIVADA'),
    const FormatException('RESPUESTA_PRIVADA'),
  ]) {
    test(
      'error ${error.runtimeType} es seguro y no registra mensajes',
      () async {
        final logs = <String>[];
        final anterior = debugPrint;
        debugPrint = (String? m, {int? wrapWidth}) {
          if (m != null) logs.add(m);
        };
        addTearDown(() => debugPrint = anterior);
        final servicio = ServicioGeminiAgente(
          generar: (_, _, _, _) async => throw error,
        );
        await expectLater(
          servicio.consultar(ContextoAgente('INSTRUCCION_PRIVADA', [])),
          throwsA(isA<ErrorModeloAgente>()),
        );
        expect(logs.join(), isNot(contains('PRIVAD')));
      },
    );
  }
  test('timeout no acepta resultados tardíos', () async {
    final pendiente = Completer<GenerateContentResponse>();
    final servicio = ServicioGeminiAgente(
      generar: (_, _, _, _) => pendiente.future,
      espera: const Duration(milliseconds: 1),
    );
    var entregados = 0;
    await expectLater(
      servicio.consultar(ContextoAgente('Lista', [])).then((r) {
        entregados++;
        return r;
      }),
      throwsA(isA<ErrorModeloAgente>()),
    );
    pendiente.complete(
      respuesta([
        const FunctionCall('eliminar_tarea', {'id': 1}),
      ]),
    );
    await Future<void>.delayed(Duration.zero);
    expect(entregados, 0);
  });
  test('respuesta vacía produce error seguro', () async {
    final servicio = ServicioGeminiAgente(
      generar: (_, _, _, _) async => respuesta([]),
    );
    await expectLater(
      servicio.consultar(ContextoAgente('Lista', [])),
      throwsA(isA<ErrorModeloAgente>()),
    );
  });
  test('integración con motor mantiene confirmación obligatoria', () async {
    var n = 0;
    final servicio = ServicioGeminiAgente(
      generar: (historial, _, _, _) async {
        if (++n == 1) {
          return respuesta([
            const FunctionCall('crear_tarea', {
              'titulo': 'Nueva tarea',
            }, id: 'crear_1'),
          ]);
        }
        expect(
          (historial.last.parts.single as FunctionResponse).response['exito'],
          false,
        );
        return respuesta([const TextPart('No creé la tarea.')]);
      },
    );
    final c = ProviderContainer(
      overrides: [modeloAgenteProvider.overrideWithValue(servicio)],
    );
    addTearDown(c.dispose);
    final agente = c.read(agenteProvider.notifier);
    final fin = agente.iniciar('Crear tarea');
    await Future<void>.delayed(Duration.zero);
    expect(c.read(taskProvider).length, 3);
    final estado = c.read(agenteProvider) as AgenteEsperandoConfirmacion;
    agente.confirmar(estado.confirmacionId, aprobada: false);
    await fin;
    expect(c.read(taskProvider).length, 3);
    expect(c.read(agenteProvider), isA<AgenteTerminado>());
  });
}
