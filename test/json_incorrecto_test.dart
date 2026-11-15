import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taskflow/datos/tareas_api.dart';
import 'package:taskflow/modelos/tarea.dart';

void main() {
  final casos = <(String, Map<String, dynamic>)>[
    ('1: title ausente', {'id': 1}),
    ('2: title solo espacios', {'title': '   '}),
    ('3: title numérico', {'title': 8}),
    ('4: id de texto', {'title': 'Leer', 'id': '1'}),
    ('5: completed de texto', {'title': 'Leer', 'completed': 'false'}),
  ];

  for (final caso in casos) {
    test('JSON incorrecto ${caso.$1}', () async {
      expect(() => Tarea.fromJson(caso.$2), throwsFormatException);
      final cliente = MockClient(
        (_) async => http.Response(
          jsonEncode([
            caso.$2,
            {'id': 2, 'title': 'Válida'},
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      addTearDown(cliente.close);
      final tareas = await TareasApi(cliente).obtenerTareas();
      expect(tareas.length, 1);
      expect(tareas.single.id, 2);
      expect(tareas.single.titulo, 'Válida');
    });
  }

  test('JSON incorrecto 6: GET con JSON truncado', () async {
    final cliente = MockClient((_) async => http.Response('[{"title":', 200));
    addTearDown(cliente.close);
    await expectLater(
      TareasApi(cliente).obtenerTareas(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.mensaje,
          'mensaje',
          'El servidor devolvió un JSON incorrecto.',
        ),
      ),
    );
  });

  test('JSON incorrecto 7: GET devuelve objeto en lugar de lista', () async {
    final cliente = MockClient(
      (_) async => http.Response('{"title":"Leer"}', 200),
    );
    addTearDown(cliente.close);
    await expectLater(
      TareasApi(cliente).obtenerTareas(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.mensaje,
          'mensaje',
          'Se esperaba una lista de tareas.',
        ),
      ),
    );
  });

  test('JSON incorrecto 8: POST devuelve title null', () async {
    final cliente = MockClient((peticion) async {
      expect(peticion.method, 'POST');
      return http.Response('{"id":201,"title":null}', 201);
    });
    addTearDown(cliente.close);
    await expectLater(
      TareasApi(cliente)
          .crearTarea(Tarea(titulo: 'Leer', fechaLimite: DateTime.now())),
      throwsA(
        isA<ApiException>().having(
          (error) => error.mensaje,
          'mensaje',
          'La tarea recibida tiene datos incorrectos.',
        ),
      ),
    );
  });
}
