import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/main.dart';
import 'package:taskflow/task_notifier.dart';

void main() {
  testWidgets('agrega, completa y elimina una tarea local', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TaskFlowApp(),
      ),
    );
    expect(find.text('33%'), findsOneWidget);
    expect(container.read(taskProvider).length, 3);
    await tester.tap(find.text('Agregar tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tarea de prueba');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(container.read(taskProvider).length, 4);
    expect(find.text('Tarea de prueba'), findsOneWidget);
    await tester.tap(
      find
          .byWidgetPredicate(
            (widget) =>
                widget is InkWell &&
                widget.child is Container &&
                (widget.child as Container).constraints?.maxWidth == 27,
          )
          .first,
    );
    await tester.pump();
    expect(container.read(taskProvider).first.completada, isTrue);
    await tester.ensureVisible(find.byTooltip('Eliminar tarea').first);
    await tester.tap(find.byTooltip('Eliminar tarea').first);
    await tester.pump();
    expect(container.read(taskProvider).length, 3);
    expect(find.byIcon(Icons.cloud), findsOneWidget);
  });
}

