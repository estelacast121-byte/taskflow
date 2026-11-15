import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/datos/propuestas_tarea.dart';

void main() {
  final hoy = DateTime(2026, 11, 15);
  String json({Object? fecha = '2026-11-16'}) => jsonEncode({
    'titulo': 'TITULO_PRIVADO',
    'descripcion': 'DESCRIPCION_PRIVADA',
    'fecha_limite': fecha,
  });
  test('distingue JSON, campos, formato, calendario y reglas de fecha', () {
    expect(diagnosticarRespuesta(null, hoy: hoy)['texto_presente'], false);
    expect(diagnosticarRespuesta('  ', hoy: hoy)['texto_vacio'], true);
    expect(diagnosticarRespuesta('{', hoy: hoy)['json_valido'], false);
    expect(diagnosticarRespuesta('[]', hoy: hoy)['campos_presentes'], false);
    expect(diagnosticarRespuesta('{}', hoy: hoy)['campos_presentes'], false);
    expect(
      diagnosticarRespuesta(
        json(fecha: '16/11/2026'),
        hoy: hoy,
      )['fecha_formato_valido'],
      false,
    );
    final imposible = diagnosticarRespuesta(
      json(fecha: '2026-02-30'),
      hoy: hoy,
    );
    expect(imposible['fecha_formato_valido'], true);
    expect(imposible['fecha_calendario_valida'], false);
    expect(imposible['propuesta_valida'], false);
    expect(
      diagnosticarRespuesta(
        json(fecha: '2026-11-14'),
        hoy: hoy,
      )['propuesta_valida'],
      false,
    );
    expect(diagnosticarRespuesta(json(), hoy: hoy)['propuesta_valida'], true);
    final sinFecha = diagnosticarRespuesta(json(fecha: null), hoy: hoy);
    expect(sinFecha['fecha_ausente'], true);
    expect(sinFecha['propuesta_valida'], true);
  });

  for (final texto in [
    null,
    ' ',
    'no JSON',
    '{}',
    json(fecha: '2026-02-30'),
    json(),
  ]) {
    test(
      'respuesta tardía se clasifica y nunca completa con una propuesta: $texto',
      () async {
        final logs = <String>[];
        final anterior = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) logs.add(message);
        };
        addTearDown(() => debugPrint = anterior);
        final pendiente = Completer<String?>();
        var propuestasEntregadas = 0;
        final servicio = PropuestasTarea(
          generar: (_, _) => pendiente.future,
          espera: const Duration(milliseconds: 1),
        );
        final solicitud = servicio.proponer('NOTA_PRIVADA', hoy: hoy).then((p) {
          propuestasEntregadas++;
          return p;
        });
        await expectLater(solicitud, throwsA(isA<ErrorPropuesta>()));
        pendiente.complete(texto);
        await Future<void>.delayed(Duration.zero);
        final salida = logs.join('\n');
        expect(salida, contains('respuesta_tardia'));
        expect(
          salida,
          contains(
            texto == json() ? 'clasificacion=valida' : 'clasificacion=invalida',
          ),
        );
        expect(propuestasEntregadas, 0);
        expect(salida, isNot(contains('evento=correcto')));
        for (final secreto in [
          'NOTA_PRIVADA',
          'TITULO_PRIVADO',
          'DESCRIPCION_PRIVADA',
        ]) {
          expect(salida, isNot(contains(secreto)));
        }
      },
    );
  }

  test('metadatos no incluyen contenido ni finishMessage', () {
    final respuesta = GenerateContentResponse([
      Candidate(
        Content.text('CONTENIDO_PRIVADO'),
        null,
        null,
        FinishReason.stop,
        'MENSAJE_PRIVADO',
      ),
    ], null);
    final salida = metadatosDiagnostico(respuesta);
    expect(salida, contains('finalizacion=[stop]'));
    expect(salida, contains('uso_presente=false'));
    expect(salida, isNot(contains('PRIVADO')));
  });
}
