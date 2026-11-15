class Tarea {
  int? id;
  String titulo;
  String descripcion;
  DateTime fechaLimite;
  bool completada;
  String categoria;
  int _prioridad;

  Tarea({
    this.id,
    required this.titulo,
    this.descripcion = '',
    required this.fechaLimite,
    this.completada = false,
    this.categoria = 'General',
    int prioridad = 2,
    // El nombre público se conserva para reutilizar el formulario.
    // ignore: prefer_initializing_formals
  }) : _prioridad = prioridad;

  int get prioridad => _prioridad;

  set prioridad(int valor) {
    if (valor >= 1 && valor <= 3) _prioridad = valor;
  }

  String get prioridadTexto => switch (_prioridad) {
    1 => 'Baja',
    3 => 'Alta',
    _ => 'Media',
  };

  void completar() => completada = true;

  factory Tarea.fromJson(Map<String, dynamic> json) {
    final titulo = json['title'];
    final id = json['id'];
    final completada = json['completed'];
    if (titulo is! String || titulo.trim().isEmpty) {
      throw const FormatException('El título debe ser un texto no vacío.');
    }
    if (id != null && id is! int) {
      throw const FormatException('El id debe ser un entero.');
    }
    if (completada != null && completada is! bool) {
      throw const FormatException('completed debe ser booleano.');
    }
    return Tarea(
      id: id as int?,
      titulo: titulo.trim(),
      completada: completada as bool? ?? false,
      fechaLimite: DateTime.now().add(const Duration(days: 7)),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': titulo,
    'completed': completada,
    'userId': 1,
  };
}
