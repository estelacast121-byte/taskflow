import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taskflow/estado/tareas_remotas_provider.dart';
import 'package:taskflow/main.dart';
import 'package:taskflow/pantallas/nueva_tarea_screen.dart';
import 'package:taskflow/pantallas/tareas_remotas_screen.dart';
import 'package:taskflow/task_notifier.dart' as local;

void main() {
  testWidgets('pantalla muestra carga, error, reintento, datos y recarga', (
    tester,
  ) async {
    final pendiente = Completer<http.Response>();
    var llamadas = 0;
    final client = MockClient((_) {
      llamadas++;
      if (llamadas == 1) return pendiente.future;
      return Future.value(http.Response('[{"title":"Remota"}]', 200));
    });
    addTearDown(client.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [httpClientProvider.overrideWithValue(client)],
        child: const MaterialApp(home: TareasRemotasScreen()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pendiente.complete(http.Response('', 500));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Remota'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(llamadas, 3);
    await tester.tap(find.text('Nueva tarea'));
    await tester.pumpAndSettle();
    expect(find.byType(NuevaTareaScreen), findsOneWidget);
    await tester.ensureVisible(find.text('Guardar tarea'));
    await tester.tap(find.text('Guardar tarea'));
    await tester.pumpAndSettle();
    expect(find.text('El título es obligatorio.'), findsOneWidget);
    expect(find.text('Selecciona una fecha límite.'), findsOneWidget);
  });

  testWidgets('formulario original envía POST y mantiene las tareas locales', (
    tester,
  ) async {
    var posts = 0;
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        posts++;
        return http.Response('{"id":201,"title":"Desde formulario"}', 201);
      }
      return http.Response('[]', 200);
    });
    final container = ProviderContainer(
      overrides: [httpClientProvider.overrideWithValue(client)],
    );
    addTearDown(() {
      container.dispose();
      client.close();
    });
    final originales = container.read(local.taskProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TaskFlowApp(),
      ),
    );
    await tester.tap(find.byIcon(Icons.cloud));
    await tester.pumpAndSettle();
    expect(find.text('No hay tareas en la nube.'), findsOneWidget);
    await tester.tap(find.text('Nueva tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Desde formulario',
    );
    await tester.tap(find.byType(TextFormField).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar tarea'));
    await tester.tap(find.text('Guardar tarea'));
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(find.text('Desde formulario'), findsOneWidget);
    expect(
      find.text('Tarea enviada. JSONPlaceholder no la guarda permanentemente.'),
      findsOneWidget,
    );
    expect(container.read(local.taskProvider), same(originales));
  });
}
