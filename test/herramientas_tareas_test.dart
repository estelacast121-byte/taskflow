import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/agente/herramientas_tareas.dart';
import 'package:taskflow/agente/repositorio_tareas_agente.dart';
import 'package:taskflow/task_notifier.dart';

void main() {
  late ProviderContainer container;
  late HerramientasTareas herramientas;
  setUp(() {
    container = ProviderContainer();
    herramientas = HerramientasTareas(
      container.read(repositorioTareasAgenteProvider),
    );
  });
  tearDown(() => container.dispose());
  List<Tarea> tareas() => container.read(taskProvider);
  AccionModificacion preparar(String nombre, Map<String, dynamic> args) =>
      herramientas.preparar(nombre, args) as AccionModificacion;

  test('listar es lectura inmutable sin confirmación ni cambios', () {
    final antes = tareas();
    final accion = herramientas.preparar('listar_tareas', {}) as AccionLectura;
    expect(accion.tareas, antes);
    expect(() => accion.tareas.clear(), throwsUnsupportedError);
    expect(identical(tareas(), antes), true);
  });
  test('preparar las tres modificaciones no cambia el estado', () {
    final antes = tareas();
    preparar('crear_tarea', {'titulo': 'Nueva tarea'});
    preparar('completar_tarea', {'id': 1});
    preparar('eliminar_tarea', {'id': 3});
    expect(identical(tareas(), antes), true);
  });
  test('crear requiere aprobación y no permite ejecutar dos veces', () {
    final accion = preparar('crear_tarea', {
      'titulo': ' Nueva tarea ',
      'detalle': 'Detalle',
      'prioridad': 'Alta',
    });
    expect(
      () => accion.argumentos['titulo'] = 'Cambio',
      throwsUnsupportedError,
    );
    expect(herramientas.ejecutar(accion, aprobada: true).exito, true);
    expect(tareas().last.titulo, 'Nueva tarea');
    expect(tareas().last.detalle, 'Detalle');
    expect(tareas().last.prioridad, 'Alta');
    expect(tareas().last.id, 4);
    expect(herramientas.ejecutar(accion, aprobada: true).exito, false);
    expect(tareas().length, 4);
  });
  for (final nombre in ['crear_tarea', 'completar_tarea', 'eliminar_tarea']) {
    test('rechazar $nombre no modifica y consume la acción', () {
      final antes = tareas();
      final accion = preparar(
        nombre,
        nombre == 'crear_tarea' ? {'titulo': 'Nueva tarea'} : {'id': 1},
      );
      expect(herramientas.ejecutar(accion, aprobada: false).exito, false);
      expect(herramientas.ejecutar(accion, aprobada: true).exito, false);
      expect(identical(tareas(), antes), true);
    });
  }
  test('completar no desmarca una tarea completada', () {
    final accion = preparar('completar_tarea', {'id': 1});
    expect(herramientas.ejecutar(accion, aprobada: true).exito, true);
    expect(tareas().first.completada, true);
    expect(
      herramientas.preparar('completar_tarea', {'id': 1}),
      isA<AccionInvalida>(),
    );
    expect(tareas().first.completada, true);
  });
  test('eliminar elimina una sola tarea', () {
    final accion = preparar('eliminar_tarea', {'id': 1});
    expect(herramientas.ejecutar(accion, aprobada: true).exito, true);
    expect(tareas().map((t) => t.id), [2, 3]);
  });
  for (final nombre in ['completar_tarea', 'eliminar_tarea']) {
    test('$nombre revalida existencia y cambios antes de ejecutar', () {
      final accion = preparar(nombre, {'id': 1});
      container.read(taskProvider.notifier).eliminarTarea(1);
      expect(herramientas.ejecutar(accion, aprobada: true).exito, false);
      final otra = preparar(nombre, {'id': 3});
      container.read(taskProvider.notifier).completarTarea(3);
      expect(herramientas.ejecutar(otra, aprobada: true).exito, false);
      expect(tareas().last.completada, true);
    });
  }
  test('IDs duplicados impiden eliminación masiva indirecta', () {
    container
        .read(taskProvider.notifier)
        .agregarTarea(
          const Tarea(
            id: 1,
            titulo: 'Duplicada',
            detalle: '',
            prioridad: 'Media',
          ),
        );
    expect(
      herramientas.preparar('eliminar_tarea', {'id': 1}),
      isA<AccionInvalida>(),
    );
  });
  test('títulos similares son ambiguos; se resuelve por ID explícito', () {
    container
        .read(taskProvider.notifier)
        .agregarTarea(
          const Tarea(
            id: 4,
            titulo: 'Estudiar Dart',
            detalle: '',
            prioridad: 'Media',
          ),
        );
    container
        .read(taskProvider.notifier)
        .agregarTarea(
          const Tarea(
            id: 5,
            titulo: 'Estudiar Dart avanzado',
            detalle: '',
            prioridad: 'Media',
          ),
        );
    final antes = tareas();
    final accion = herramientas.preparar('eliminar_tarea', {
      'titulo': 'ESTUDIAR DART',
    }) as AccionInvalida;
    expect(accion.candidatos.map((t) => t.id), [4, 5]);
    expect(identical(tareas(), antes), true);
    expect(
      herramientas.preparar('eliminar_tarea', {'id': 4}),
      isA<AccionModificacion>(),
    );
  });
  test('una acción no puede aprobarse mediante otra instancia', () {
    final accion = preparar('eliminar_tarea', {'id': 1});
    final otra = HerramientasTareas(
      container.read(repositorioTareasAgenteProvider),
    );
    expect(otra.ejecutar(accion, aprobada: true).exito, false);
    expect(tareas().length, 3);
  });
  final invalidos = <(String, Map<String, dynamic>)>[
    ('desconocida', {}),
    ('listar_tareas', {'id': 1}),
    ('crear_tarea', {}),
    ('crear_tarea', {'titulo': 1}),
    ('crear_tarea', {'titulo': 'ab'}),
    ('crear_tarea', {'titulo': 'Tarea', 'prioridad': 'Urgente'}),
    ('crear_tarea', {'titulo': 'Tarea', 'fecha_limite': '2026-12-01'}),
    ('crear_tarea', {'titulo': 'Tarea', 'detalle': null}),
    (
      'crear_tarea',
      {'titulo': 'Tarea', 'detalle': List.filled(201, 'x').join()},
    ),
    (
      'eliminar_tarea',
      {
        'ids': [1, 2],
      },
    ),
    (
      'eliminar_tarea',
      {
        'id': [1, 2],
      },
    ),
    ('eliminar_tarea', {'id': 1, 'titulo': 'Tarea'}),
    ('eliminar_tarea', {'id': 1.0}),
    ('completar_tarea', {'id': 999}),
    ('eliminar_tarea', {'titulo': 'No existe'}),
    ('completar_tarea', {'titulo': ''}),
    ('eliminar_tarea', {'id': -1}),
  ];
  for (var i = 0; i < invalidos.length; i++) {
    test('argumentos inválidos $i no modifican tareas', () {
      final antes = tareas();
      expect(
        herramientas.preparar(invalidos[i].$1, invalidos[i].$2),
        isA<AccionInvalida>(),
      );
      expect(identical(tareas(), antes), true);
    });
  }
}
