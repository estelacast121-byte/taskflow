import '../task_notifier.dart';
import '../validacion/validadores_tarea.dart';
import 'repositorio_tareas_agente.dart';

sealed class AccionPreparada {
  const AccionPreparada();
}

final class AccionInvalida extends AccionPreparada {
  AccionInvalida(this.mensaje, {List<Tarea> candidatos = const []})
    : candidatos = List.unmodifiable(candidatos);
  final String mensaje;
  final List<Tarea> candidatos;
}

final class AccionLectura extends AccionPreparada {
  AccionLectura._(List<Tarea> tareas) : tareas = List.unmodifiable(tareas);
  final List<Tarea> tareas;
}

final class AccionModificacion extends AccionPreparada {
  const AccionModificacion._(
    this.herramienta,
    this.resumen,
    this.argumentos,
    this._ejecutar,
  );
  final String herramienta;
  final String resumen;
  final Map<String, Object?> argumentos;
  final void Function() _ejecutar;
}

class ResultadoHerramienta {
  const ResultadoHerramienta(this.exito, this.mensaje);
  final bool exito;
  final String mensaje;
}

class HerramientasTareas {
  HerramientasTareas(this.repositorio);
  final RepositorioTareasAgente repositorio;
  final Set<AccionModificacion> _pendientes = {};

  AccionPreparada preparar(String nombre, Map<String, dynamic> argumentos) {
    if (nombre == 'listar_tareas') {
      if (argumentos.isNotEmpty) {
        return AccionInvalida('listar_tareas no acepta argumentos.');
      }
      return AccionLectura._(repositorio.listar());
    }
    if (nombre == 'crear_tarea') {
      if (argumentos.keys.any(
        (k) => !['titulo', 'detalle', 'prioridad'].contains(k),
      )) {
        return AccionInvalida('Campos permitidos: titulo, detalle, prioridad.');
      }
      final titulo = argumentos['titulo'];
      final detalle = argumentos.containsKey('detalle')
          ? argumentos['detalle']
          : '';
      final prioridad = argumentos.containsKey('prioridad')
          ? argumentos['prioridad']
          : 'Media';
      if (titulo is! String || detalle is! String || prioridad is! String) {
        return AccionInvalida('Título, detalle y prioridad deben ser textos.');
      }
      final error =
          ValidadoresTarea.titulo(titulo) ??
          ValidadoresTarea.descripcion(detalle);
      if (error != null) return AccionInvalida(error);
      if (!['Baja', 'Media', 'Alta'].contains(prioridad)) {
        return AccionInvalida('Prioridad inválida.');
      }
      return _modificacion(
        nombre,
        'Crear: ${titulo.trim()}',
        {
          'titulo': titulo.trim(),
          'detalle': detalle.trim(),
          'prioridad': prioridad,
        },
        () => repositorio.crear(
          titulo: titulo,
          detalle: detalle,
          prioridad: prioridad,
        ),
      );
    }
    if (nombre != 'completar_tarea' && nombre != 'eliminar_tarea') {
      return AccionInvalida('Herramienta desconocida.');
    }
    if (argumentos.length != 1 ||
        !(argumentos.containsKey('id') || argumentos.containsKey('titulo'))) {
      return AccionInvalida(
        'Indica un único id o titulo; no se admiten acciones masivas.',
      );
    }
    final tareas = repositorio.listar();
    final List<Tarea> candidatas;
    if (argumentos.containsKey('id')) {
      final id = argumentos['id'];
      if (id is! int || id <= 0) {
        return AccionInvalida('El id debe ser un entero positivo.');
      }
      candidatas = tareas.where((t) => t.id == id).toList();
    } else {
      final titulo = argumentos['titulo'];
      if (titulo is! String || titulo.trim().isEmpty || titulo.length > 60) {
        return AccionInvalida(
          'Indica un título no vacío de hasta 60 caracteres.',
        );
      }
      final busqueda = _normalizar(titulo);
      candidatas = tareas
          .where((t) => _normalizar(t.titulo).contains(busqueda))
          .toList();
    }
    if (candidatas.isEmpty) return AccionInvalida('No se encontró la tarea.');
    if (candidatas.length != 1) {
      return AccionInvalida(
        'Título o ID ambiguo. Selecciona un ID único.',
        candidatos: candidatas,
      );
    }
    final tarea = candidatas.single;
    if (nombre == 'completar_tarea' && tarea.completada) {
      return AccionInvalida('La tarea ya está completada.');
    }
    return _modificacion(
      nombre,
      '${nombre == 'eliminar_tarea' ? 'Eliminar' : 'Completar'} #${tarea.id}: ${tarea.titulo}',
      {'id': tarea.id},
      () {
        if (nombre == 'eliminar_tarea') {
          repositorio.eliminar(tarea);
        } else {
          repositorio.completar(tarea);
        }
      },
    );
  }

  AccionModificacion _modificacion(
    String nombre,
    String resumen,
    Map<String, Object?> argumentos,
    void Function() ejecutar,
  ) {
    final accion = AccionModificacion._(
      nombre,
      resumen,
      Map.unmodifiable(argumentos),
      ejecutar,
    );
    _pendientes.add(accion);
    return accion;
  }

  /// La futura UI debe pasar aprobada=true solo tras una confirmación humana.
  /// Aprobar/rechazar consume la acción: no puede ejecutarse dos veces.
  ResultadoHerramienta ejecutar(
    AccionModificacion accion, {
    required bool aprobada,
  }) {
    if (!_pendientes.remove(accion)) {
      return const ResultadoHerramienta(
        false,
        'Acción desconocida o ya consumida.',
      );
    }
    if (!aprobada) {
      return const ResultadoHerramienta(false, 'Modificación rechazada.');
    }
    try {
      accion._ejecutar();
      return const ResultadoHerramienta(true, 'Modificación realizada.');
    } on StateError catch (error) {
      return ResultadoHerramienta(false, error.message.toString());
    }
  }

  static String _normalizar(String texto) {
    var normal = texto.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    const acentos = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
    };
    acentos.forEach(
      (original, reemplazo) => normal = normal.replaceAll(original, reemplazo),
    );
    return normal;
  }
}
