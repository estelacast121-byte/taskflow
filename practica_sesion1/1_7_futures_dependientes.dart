// ignore_for_file: avoid_print, file_names
import '1_7_futures_independientes.dart' show cargarPerfil;

Future<int> cargarPendientes(String perfil) async {
  if (perfil.isEmpty) throw ArgumentError('El perfil es obligatorio.');
  await Future<void>.delayed(const Duration(seconds: 3));
  return 7;
}

Future<void> main() async {
  final reloj = Stopwatch()..start();
  final perfil = await cargarPerfil();
  // Esta operación necesita el resultado de la anterior.
  final pendientes = await cargarPendientes(perfil);
  print('Dependiente: ${reloj.elapsedMilliseconds} ms; $perfil, $pendientes');
}
