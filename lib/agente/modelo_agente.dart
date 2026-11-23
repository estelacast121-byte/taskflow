import 'dart:convert';

abstract interface class ModeloAgente {
  Future<RespuestaModeloAgente> consultar(ContextoAgente contexto);
}

class ContextoAgente {
  ContextoAgente(this.instruccion, List<IntercambioAgente> intercambios)
    : intercambios = List.unmodifiable(intercambios);
  final String instruccion;
  final List<IntercambioAgente> intercambios;
}

sealed class RespuestaModeloAgente {
  const RespuestaModeloAgente();
}

final class RespuestaFinal extends RespuestaModeloAgente {
  const RespuestaFinal(this.mensaje);
  final String mensaje;
}

final class SolicitudHerramientas extends RespuestaModeloAgente {
  SolicitudHerramientas(List<LlamadaHerramienta> llamadas)
    : llamadas = List.unmodifiable(llamadas);
  final List<LlamadaHerramienta> llamadas;
}

class LlamadaHerramienta {
  LlamadaHerramienta(this.id, this.nombre, Map<String, dynamic> argumentos)
    : _json = jsonEncode(argumentos);
  final String id;
  final String nombre;
  final String _json;
  // Cada acceso devuelve una copia; el modelo no puede alterar una aprobación.
  Map<String, dynamic> get argumentos =>
      jsonDecode(_json) as Map<String, dynamic>;
}

class ObservacionHerramienta {
  ObservacionHerramienta(
    this.llamadaId,
    this.exito,
    this.mensaje, {
    List<Map<String, Object?>> tareas = const [],
  }) : tareas = List.unmodifiable(
         tareas.map((t) => Map<String, Object?>.unmodifiable(t)),
       );
  final String llamadaId;
  final bool exito;
  final String mensaje;
  final List<Map<String, Object?>> tareas;
}

class IntercambioAgente {
  IntercambioAgente(this.solicitud, List<ObservacionHerramienta> observaciones)
    : observaciones = List.unmodifiable(observaciones);
  final SolicitudHerramientas solicitud;
  final List<ObservacionHerramienta> observaciones;
}
