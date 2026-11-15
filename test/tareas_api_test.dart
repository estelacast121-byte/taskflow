import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taskflow/datos/tareas_api.dart';
import 'package:taskflow/modelos/tarea.dart';

void main() {
  test(
    'GET conserva válidos y descarta registros individuales inválidos',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/todos');
        expect(request.url.queryParameters['_limit'], '15');
        return http.Response(
          jsonEncode([
            {'id': 1, 'title': 'Leer'},
            {'title': ''},
            4,
            {'title': 'Otro', 'completed': true},
          ]),
          200,
        );
      });
      addTearDown(client.close);
      final lista = await TareasApi(client).obtenerTareas();
      expect(lista.map((t) => t.titulo), ['Leer', 'Otro']);
    },
  );
  test('POST envía JSON y procesa 201', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/todos');
      expect(request.headers['content-type'], contains('application/json'));
      expect(jsonDecode(request.body), {
        'title': 'Nueva',
        'completed': false,
        'userId': 1,
      });
      return http.Response('{"id":201,"title":"Nueva","completed":false}', 201);
    });
    addTearDown(client.close);
    expect(
      (await TareasApi(client)
              .crearTarea(Tarea(titulo: 'Nueva', fechaLimite: DateTime.now())))
          .id,
      201,
    );
  });
  for (final codigo in [404, 500]) {
    test('GET HTTP $codigo', () async {
      final client = MockClient((_) async => http.Response('', codigo));
      addTearDown(client.close);
      await expectLater(
        TareasApi(client).obtenerTareas(),
        throwsA(isA<ApiException>().having((e) => e.codigo, 'codigo', codigo)),
      );
    });
  }
  test('error de conexión', () async {
    final client = MockClient(
      (_) async => throw http.ClientException('sin red'),
    );
    addTearDown(client.close);
    await expectLater(
      TareasApi(client).obtenerTareas(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('conexión'),
        ),
      ),
    );
  });
  testWidgets('GET excede timeout de 10 segundos', (tester) async {
    final client = MockClient((_) => Completer<http.Response>().future);
    addTearDown(client.close);
    final comprobacion = expectLater(
      TareasApi(client).obtenerTareas(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('tardó'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 11));
    await comprobacion;
  });
  for (final body in ['no json', '{}']) {
    test('GET rechaza respuesta $body', () async {
      final client = MockClient((_) async => http.Response(body, 200));
      addTearDown(client.close);
      await expectLater(
        TareasApi(client).obtenerTareas(),
        throwsA(isA<ApiException>()),
      );
    });
  }
  for (final caso in [
    (200, '{}'),
    (201, '[]'),
    (201, '{"title":""}'),
    (201, 'no json'),
  ]) {
    test('POST rechaza respuesta ${caso.$1} ${caso.$2}', () async {
      final client = MockClient((_) async => http.Response(caso.$2, caso.$1));
      addTearDown(client.close);
      await expectLater(
        TareasApi(client)
            .crearTarea(Tarea(titulo: 'Nueva', fechaLimite: DateTime.now())),
        throwsA(isA<ApiException>()),
      );
    });
  }
}
