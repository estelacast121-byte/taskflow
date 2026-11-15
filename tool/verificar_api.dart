// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;
import 'package:taskflow/datos/tareas_api.dart';
import 'package:taskflow/modelos/tarea.dart';

Future<void> main() async {
  final cliente = http.Client();
  try {
    final api = TareasApi(cliente);
    final tareas = await api.obtenerTareas();
    print('GET: ${tareas.length} tareas recibidas.');
    final creada = await api.crearTarea(
      Tarea(
        titulo: 'Prueba Semana 14',
        fechaLimite: DateTime.now().add(const Duration(days: 7)),
      ),
    );
    print('POST: id ${creada.id}, título ${creada.titulo}.');
  } finally {
    cliente.close();
  }
}
