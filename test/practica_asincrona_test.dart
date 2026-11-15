import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/practica/experimento_isolate_screen.dart';
import '../practica_sesion1/1_6_await_olvidado.dart' as guardar;
import '../practica_sesion1/1_7_futures_dependientes.dart' as dependientes;

void main() {
  test('guardar propaga error asíncrono y acepta título válido', () async {
    await expectLater(guardar.guardarTarea(''), throwsException);
    await guardar.guardarTarea('Prueba de asincronía');
  });

  test('pendientes dependientes rechaza perfil vacío', () async {
    await expectLater(dependientes.cargarPendientes(''), throwsArgumentError);
  });

  testWidgets('ambas funciones de CPU producen el mismo resultado', (tester) async {
    await tester.runAsync(() async {
      final reloj = Stopwatch()..start();
      final directo = await sinIsolate();
      final tiempoDirecto = reloj.elapsedMilliseconds;
      reloj.reset();
      final aislado = await conIsolate();
      final tiempoAislado = reloj.elapsedMilliseconds;
      expect(directo, 1199999997);
      expect(aislado, directo);
      // ignore: avoid_print
      print('CPU sin isolate: $tiempoDirecto ms; resultado $directo');
      // ignore: avoid_print
      print('CPU con isolate: $tiempoAislado ms; resultado $aislado');
    });
  });
}
