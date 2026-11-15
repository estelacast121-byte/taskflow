import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taskflow/datos/tareas_api.dart';
import 'package:taskflow/estado/tareas_remotas_provider.dart';
import 'package:taskflow/modelos/tarea.dart';

void main() {
  test('carga, POST fallido conserva lista, creación y recarga', () async {
    var fallaPost = true;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response('[{"id":1,"title":"Original"}]', 200);
      }
      return fallaPost
          ? http.Response('', 500)
          : http.Response('{"id":201,"title":"Nueva"}', 201);
    });
    final container = ProviderContainer(
      overrides: [httpClientProvider.overrideWithValue(client)],
    );
    addTearDown(() {
      container.dispose();
      client.close();
    });
    expect(container.read(tareasRemotasProvider).isLoading, isTrue);
    await container.read(tareasRemotasProvider.future);
    final notifier = container.read(tareasRemotasProvider.notifier);
    final original = container.read(tareasRemotasProvider).requireValue;
    final nueva = Tarea(titulo: 'Nueva', fechaLimite: DateTime.now());
    await expectLater(notifier.crear(nueva), throwsA(isA<ApiException>()));
    expect(container.read(tareasRemotasProvider).requireValue, same(original));
    fallaPost = false;
    await notifier.crear(nueva);
    expect(container.read(tareasRemotasProvider).requireValue.length, 2);
    expect(original.length, 1);
    final recarga = notifier.recargar();
    expect(container.read(tareasRemotasProvider).isLoading, isTrue);
    await recarga;
    expect(container.read(tareasRemotasProvider).requireValue.length, 1);
  });
  test('error inicial y reintento', () async {
    var falla = true;
    final client = MockClient(
      (_) async => falla ? http.Response('', 500) : http.Response('[]', 200),
    );
    final container = ProviderContainer(
      overrides: [httpClientProvider.overrideWithValue(client)],
    );
    addTearDown(() {
      container.dispose();
      client.close();
    });
    await expectLater(
      container.read(tareasRemotasProvider.future),
      throwsA(isA<ApiException>()),
    );
    expect(container.read(tareasRemotasProvider).hasError, isTrue);
    falla = false;
    await container.read(tareasRemotasProvider.notifier).recargar();
    expect(container.read(tareasRemotasProvider).requireValue, isEmpty);
  });
}
