// ignore_for_file: prefer_initializing_formals
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../task_notifier.dart';
import '../validacion/validadores_tarea.dart';

/// Adaptador de la lista en memoria. No usa el modelo de formularios ni la API.
class RepositorioTareasAgente {
  RepositorioTareasAgente({
    required List<Tarea> Function() leer,
    required TaskNotifier Function() notifier,
  }) : _leer = leer,
       _notifier = notifier;
  final List<Tarea> Function() _leer;
  final TaskNotifier Function() _notifier;

  List<Tarea> listar() => List.unmodifiable(_leer());

  Tarea crear({
    required String titulo,
    required String detalle,
    required String prioridad,
  }) {
    final error =
        ValidadoresTarea.titulo(titulo) ??
        ValidadoresTarea.descripcion(detalle);
    if (error != null || !['Baja', 'Media', 'Alta'].contains(prioridad)) {
      throw StateError(error ?? 'Prioridad inválida.');
    }
    final id = _leer().fold<int>(0, (max, t) => t.id > max ? t.id : max) + 1;
    final tarea = Tarea(
      id: id,
      titulo: titulo.trim(),
      detalle: detalle.trim(),
      prioridad: prioridad,
    );
    _notifier().agregarTarea(tarea);
    return tarea;
  }

  Tarea _vigente(Tarea esperada) {
    final actuales = _leer().where((t) => t.id == esperada.id).toList();
    if (actuales.length != 1) {
      throw StateError('La tarea ya no existe o su ID es ambiguo.');
    }
    final t = actuales.single;
    if (t.titulo != esperada.titulo ||
        t.detalle != esperada.detalle ||
        t.prioridad != esperada.prioridad ||
        t.completada != esperada.completada ||
        !identical(t, esperada)) {
      throw StateError('La tarea cambió. Prepara y confirma una nueva acción.');
    }
    return t;
  }

  void completar(Tarea esperada) {
    final actual = _vigente(esperada);
    if (actual.completada) throw StateError('La tarea ya está completada.');
    // TaskNotifier alterna: comprobar antes evita volver a marcar pendiente.
    _notifier().completarTarea(actual.id);
  }

  void eliminar(Tarea esperada) {
    final actual = _vigente(esperada);
    _notifier().eliminarTarea(actual.id);
  }
}

final repositorioTareasAgenteProvider = Provider<RepositorioTareasAgente>(
  (ref) => RepositorioTareasAgente(
    leer: () => ref.read(taskProvider),
    notifier: () => ref.read(taskProvider.notifier),
  ),
);
