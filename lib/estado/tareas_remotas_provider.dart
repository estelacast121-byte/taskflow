import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../datos/tareas_api.dart';
import '../modelos/tarea.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final cliente = http.Client();
  ref.onDispose(cliente.close);
  return cliente;
});

final tareasApiProvider = Provider<TareasApi>((ref) {
  return TareasApi(ref.watch(httpClientProvider));
});

class TareasRemotasNotifier extends AsyncNotifier<List<Tarea>> {
  bool _ocupado = false;

  @override
  Future<List<Tarea>> build() => ref.watch(tareasApiProvider).obtenerTareas();

  Future<void> recargar() async {
    if (_ocupado) return;
    _ocupado = true;
    state = const AsyncLoading();
    try {
      final resultado = await AsyncValue.guard(
        () => ref.read(tareasApiProvider).obtenerTareas(),
      );
      if (ref.mounted) state = resultado;
    } finally {
      _ocupado = false;
    }
  }

  Future<void> crear(Tarea tarea) async {
    if (_ocupado || state.isLoading) {
      throw const ApiException('Espera a que termine la solicitud actual.');
    }
    if (!state.hasValue) {
      throw const ApiException('Primero carga las tareas.');
    }
    _ocupado = true;
    try {
      final creada = await ref.read(tareasApiProvider).crearTarea(tarea);
      if (ref.mounted) state = AsyncData([...state.requireValue, creada]);
    } finally {
      _ocupado = false;
    }
  }
}

final tareasRemotasProvider =
    AsyncNotifierProvider<TareasRemotasNotifier, List<Tarea>>(
      TareasRemotasNotifier.new,
      retry: (intento, error) => null,
    );
