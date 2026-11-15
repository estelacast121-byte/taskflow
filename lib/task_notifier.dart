import 'package:flutter_riverpod/flutter_riverpod.dart';

class Tarea {
  final int id;
  final String titulo;
  final String detalle;
  final String prioridad;
  final bool completada;

  const Tarea({
    required this.id,
    required this.titulo,
    required this.detalle,
    required this.prioridad,
    this.completada = false,
  });

  Tarea copyWith({
    int? id,
    String? titulo,
    String? detalle,
    String? prioridad,
    bool? completada,
  }) {
    return Tarea(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      detalle: detalle ?? this.detalle,
      prioridad: prioridad ?? this.prioridad,
      completada: completada ?? this.completada,
    );
  }
}

class TaskNotifier extends Notifier<List<Tarea>> {
  @override
  List<Tarea> build() {
    return const [
      Tarea(
        id: 1,
        titulo: 'Preparar presentación de Flutter',
        detalle: 'Hoy · Universidad',
        prioridad: 'Alta',
      ),
      Tarea(
        id: 2,
        titulo: 'Organizar actividades de la semana',
        detalle: 'Hoy · Personal',
        prioridad: 'Media',
        completada: true,
      ),
      Tarea(
        id: 3,
        titulo: 'Practicar ejercicios de Dart',
        detalle: 'Mañana · Aprendizaje',
        prioridad: 'Baja',
      ),
    ];
  }

  void agregarTarea(Tarea tarea) {
    state = [...state, tarea];
  }

  void completarTarea(int id) {
    state = [
      for (final tarea in state)
        if (tarea.id == id)
          tarea.copyWith(completada: !tarea.completada)
        else
          tarea,
    ];
  }

  void eliminarTarea(int id) {
    state = state.where((tarea) => tarea.id != id).toList();
  }
}

final taskProvider =
    NotifierProvider<TaskNotifier, List<Tarea>>(TaskNotifier.new);