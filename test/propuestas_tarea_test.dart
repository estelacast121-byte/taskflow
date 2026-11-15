import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:taskflow/datos/propuestas_tarea.dart';

void main() {
  final hoy = DateTime(2026, 11, 15);
  String json({
    Object? titulo = 'Estudiar Flutter',
    Object? descripcion = '',
    Object? fecha,
  }) => jsonEncode({
    'titulo': titulo,
    'descripcion': descripcion,
    'fecha_limite': fecha,
  });
  test('acepta campos válidos y fecha ausente', () {
    final p = PropuestaTarea.desdeJson(json(), hoy: hoy);
    expect(p.titulo, 'Estudiar Flutter');
    expect(p.fechaLimite, isNull);
    expect(
      PropuestaTarea.desdeJson(json(fecha: '2026-11-15'), hoy: hoy).fechaLimite,
      hoy,
    );
    expect(
      PropuestaTarea.desdeJson(json(fecha: '2028-02-29'), hoy: DateTime(2027)).fechaLimite,
      DateTime(2028, 2, 29),
    );
  });
  for (final fecha in [
    '2026-02-30',
    '2026-11-14',
    '2026-13-01',
    '2027-02-29',
    '2029-01-01',
    '15/11/2026',
    '2026-11-16T00:00:00Z',
    123,
  ]) {
    test('rechaza fecha inválida $fecha', () {
      expect(
        () => PropuestaTarea.desdeJson(json(fecha: fecha), hoy: hoy),
        throwsFormatException,
      );
    });
  }
  for (final texto in [
    'no json',
    '[]',
    '{}',
    '{"titulo":"abc","descripcion":""}',
    json(titulo: 7),
    json(titulo: ' '),
    json(titulo: 'ab'),
    json(descripcion: null),
    json(descripcion: List.filled(201, 'a').join()),
    json(titulo: List.filled(61, 'a').join()),
  ]) {
    test('rechaza estructura o campos $texto', () {
      expect(
        () => PropuestaTarea.desdeJson(texto, hoy: hoy),
        throwsFormatException,
      );
    });
  }
  test('no llama a Gemini para nota vacía o demasiado larga', () async {
    var llamadas = 0;
    final servicio = PropuestasTarea(
      generar: (_, _) async {
        llamadas++;
        return json();
      },
    );
    await expectLater(servicio.proponer('  '), throwsA(isA<ErrorPropuesta>()));
    await expectLater(
      servicio.proponer(List.filled(4001, 'a').join()),
      throwsA(isA<ErrorPropuesta>()),
    );
    expect(llamadas, 0);
  });
  test('valida también la respuesta del transporte', () async {
    final servicio = PropuestasTarea(
      generar: (_, _) async => json(fecha: '2026-11-16'),
    );
    expect(
      (await servicio.proponer('Mañana estudiar', hoy: hoy)).fechaLimite,
      DateTime(2026, 11, 16),
    );
  });
  for (final respuesta in [null, '', '[]', '{']) {
    test(
      'respuesta vacía o inválida se transforma en error recuperable $respuesta',
      () async {
        final servicio = PropuestasTarea(generar: (_, _) async => respuesta);
        await expectLater(
          servicio.proponer('Estudiar'),
          throwsA(isA<ErrorPropuesta>()),
        );
      },
    );
  }
  for (final error in [
    http.ClientException('offline'),
    TimeoutException('timeout'),
    FirebaseAIException('denied'),
    Exception('fallo'),
  ]) {
    test('maneja ${error.runtimeType}', () async {
      final servicio = PropuestasTarea(generar: (_, _) async => throw error);
      await expectLater(
        servicio.proponer('Estudiar'),
        throwsA(isA<ErrorPropuesta>()),
      );
    });
  }
  test('aplica timeout a una petición pendiente', () async {
    final servicio = PropuestasTarea(
      generar: (_, _) => Completer<String?>().future,
      espera: const Duration(milliseconds: 1),
    );
    await expectLater(
      servicio.proponer('Estudiar'),
      throwsA(isA<ErrorPropuesta>()),
    );
  });
  test('línea base reconoce ISO, no interpreta mañana', () {
    expect(
      propuestaLocal('Entregar informe el 2026-11-20', hoy: hoy).fechaLimite,
      DateTime(2026, 11, 20),
    );
    expect(
      propuestaLocal('Mañana estudiar Flutter', hoy: hoy).fechaLimite,
      isNull,
    );
    expect(propuestaLocal('Organizar apuntes', hoy: hoy).fechaLimite, isNull);
  });
}
