import 'herramientas_tareas.dart';

sealed class EstadoAgente {
  const EstadoAgente();
}

final class AgenteInactivo extends EstadoAgente {
  const AgenteInactivo();
}

final class AgentePensando extends EstadoAgente {
  const AgentePensando(this.iteracion);
  final int iteracion;
}

final class AgenteEjecutandoHerramienta extends EstadoAgente {
  const AgenteEjecutandoHerramienta(this.herramienta, this.llamadaId);
  final String herramienta;
  final String llamadaId;
}

final class AgenteEsperandoConfirmacion extends EstadoAgente {
  const AgenteEsperandoConfirmacion(this.confirmacionId, this.accion);
  final int confirmacionId;
  final AccionModificacion accion;
}

final class AgenteTerminado extends EstadoAgente {
  const AgenteTerminado(this.mensaje);
  final String mensaje;
}

final class AgenteError extends EstadoAgente {
  const AgenteError(this.mensaje);
  final String mensaje;
}
