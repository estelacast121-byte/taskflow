import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/datos/reconocedor_texto.dart';
import 'package:taskflow/main.dart';
import 'package:taskflow/task_notifier.dart';

class ReconocedorFalso implements ReconocedorTexto {
  String? texto = 'Estudiar Flutter\nRepasar ML Kit';
  Object? error;
  Completer<String?>? pendiente;
  @override
  Future<String?> recuperarPendiente() async => null;
  @override
  Future<String?> reconocer(FuenteFoto fuente) async {
    if (error != null) throw error!;
    return pendiente == null ? texto : pendiente!.future;
  }
}

void main() {
  late ReconocedorFalso falso;
  late ProviderContainer container;
  setUp(() {
    falso = ReconocedorFalso();
    container = ProviderContainer(
      overrides: [reconocedorTextoProvider.overrideWithValue(falso)],
    );
  });
  tearDown(() => container.dispose());

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TaskFlowApp(),
      ),
    );
    await tester.tap(find.text('Escanear tarea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seleccionar de la galería'));
    await tester.pumpAndSettle();
  }

  testWidgets('reconocer y cancelar no guarda una tarea', (tester) async {
    await abrir(tester);
    expect(find.text(falso.texto!), findsOneWidget);
    expect(container.read(taskProvider).length, 3);
    await tester.tap(find.text('Revisar propuesta de tarea'));
    await tester.pumpAndSettle();
    expect(container.read(taskProvider).length, 3);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(container.read(taskProvider).length, 3);
  });

  testWidgets('valida, permite corregir y guarda solo al confirmar', (
    tester,
  ) async {
    await abrir(tester);
    await tester.tap(find.text('Revisar propuesta de tarea'));
    await tester.pumpAndSettle();
    final guardar = find.text('Guardar tarea');
    await tester.scrollUntilVisible(guardar, 250, scrollable: find.byType(Scrollable).first);
    await tester.tap(guardar);
    await tester.pumpAndSettle();
    expect(container.read(taskProvider).length, 3);
    expect(find.text('Selecciona una fecha límite.'), findsOneWidget);
    final titulo = find.byType(TextFormField).at(0);
    await tester.scrollUntilVisible(titulo, -250, scrollable: find.byType(Scrollable).first);
    await tester.enterText(titulo, 'Título corregido');
    final fecha = find.byType(TextFormField).at(2);
    await tester.ensureVisible(fecha);
    await tester.tap(fecha);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(guardar, 250, scrollable: find.byType(Scrollable).first);
    await tester.tap(guardar);
    await tester.pumpAndSettle();
    expect(container.read(taskProvider).length, 4);
    final tarea = container.read(taskProvider).last;
    expect(tarea.titulo, 'Título corregido');
    expect(tarea.detalle, contains(falso.texto!));
  });

  testWidgets('imagen vacía y cancelación del selector no proponen tarea', (
    tester,
  ) async {
    falso.texto = '  ';
    await abrir(tester);
    expect(find.textContaining('No se reconoció texto.'), findsOneWidget);
    expect(find.text('Revisar propuesta de tarea'), findsNothing);
    falso.texto = null;
    await tester.tap(find.text('Seleccionar de la galería'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se reconoció texto.'), findsNothing);
    expect(container.read(taskProvider).length, 3);
  });

  testWidgets('error permite reintentar', (tester) async {
    falso.error = Exception('fallo simulado');
    await abrir(tester);
    expect(
      find.textContaining('No se pudo reconocer la imagen.'),
      findsOneWidget,
    );
    falso.error = null;
    await tester.tap(find.text('Tomar fotografía'));
    await tester.pumpAndSettle();
    expect(find.text(falso.texto!), findsOneWidget);
  });

  testWidgets('procesamiento deshabilita botones y cierre es seguro', (
    tester,
  ) async {
    falso.pendiente = Completer<String?>();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TaskFlowApp(),
      ),
    );
    await tester.tap(find.text('Escanear tarea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seleccionar de la galería'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    for (final boton in tester.widgetList<OutlinedButton>(
      find.byType(OutlinedButton),
    )) {
      expect(boton.onPressed, isNull);
    }
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    falso.pendiente!.complete('Texto tardío');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(container.read(taskProvider).length, 3);
  });
}

