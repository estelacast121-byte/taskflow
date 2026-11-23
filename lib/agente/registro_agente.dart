import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'modelo_agente.dart';

class ResultadoVisibleAgente {
  const ResultadoVisibleAgente(this.herramienta, this.observacion);
  final String herramienta;
  final ObservacionHerramienta observacion;
}

class RegistroAgente extends Notifier<List<ResultadoVisibleAgente>> {
  @override
  List<ResultadoVisibleAgente> build() => const [];
  void limpiar() => state = const [];
  void agregar(ResultadoVisibleAgente resultado) =>
      state = List.unmodifiable([...state, resultado]);
}

final registroAgenteProvider =
    NotifierProvider<RegistroAgente, List<ResultadoVisibleAgente>>(
      RegistroAgente.new,
    );
