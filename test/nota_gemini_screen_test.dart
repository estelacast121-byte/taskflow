import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/datos/propuestas_tarea.dart';
import 'package:taskflow/pantallas/nota_gemini_screen.dart';

void main() {
  testWidgets('carga, revisión editable y cancelación sin guardar', (
    tester,
  ) async {
    final pendiente = Completer<String?>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          propuestasTareaProvider.overrideWithValue(
            PropuestasTarea(generar: (_, _) => pendiente.future),
          ),
        ],
        child: const MaterialApp(home: NotaGeminiScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Organizar apuntes');
    await tester.tap(find.text('Proponer tarea'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    pendiente.complete(
      '{"titulo":"Organizar apuntes","descripcion":"Clasificar por materia","fecha_limite":null}',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Revisa y corrige'), findsOneWidget);
    expect(find.text('Clasificar por materia'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'Título corregido',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Proponer tarea'), findsOneWidget);
  });
  testWidgets('error permite reintentar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          propuestasTareaProvider.overrideWithValue(
            PropuestasTarea(generar: (_, _) async => '[]'),
          ),
        ],
        child: const MaterialApp(home: NotaGeminiScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Organizar apuntes');
    await tester.tap(find.text('Proponer tarea'));
    await tester.pumpAndSettle();
    expect(find.textContaining('propuesta inválida'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
