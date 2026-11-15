import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/task_notifier.dart';

void main() {
  test(
    'estado local conserva copias, permite desmarcar y queda vacío al eliminar',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final inicial = container.read(taskProvider);
      final notifier = container.read(taskProvider.notifier);
      notifier.completarTarea(1);
      expect(inicial.first.completada, isFalse);
      expect(container.read(taskProvider).first.completada, isTrue);
      notifier.completarTarea(1);
      expect(container.read(taskProvider).first.completada, isFalse);
      for (final tarea in inicial) {
        notifier.eliminarTarea(tarea.id);
      }
      expect(container.read(taskProvider), isEmpty);
      notifier.agregarTarea(
        const Tarea(id: 1, titulo: 'Nueva', detalle: 'Hoy', prioridad: 'Media'),
      );
      expect(container.read(taskProvider).single.titulo, 'Nueva');
    },
  );
}
