import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'task_notifier.dart';
import 'pantallas/escanear_tarea_screen.dart';
import 'pantallas/nota_gemini_screen.dart';
import 'pantallas/asistente_screen.dart';
import 'modelos/tarea.dart' as modelo;
import 'utils/formato.dart';
import 'pantallas/tareas_remotas_screen.dart';
import 'practica/experimento_isolate_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseInicializado = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInicializado = true;
  } catch (e) {
    debugPrint('Firebase no configurado en esta plataforma: $e');
  }

  // Proveedor local de desarrollo: nunca se activa en profile o release.
  if (firebaseInicializado &&
      kDebugMode &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
    );
  }

  runApp(
    const ProviderScope(
      child: TaskFlowApp(),
    ),
  );
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskFlow',
      theme: ThemeData(
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF5F4FA),
      ),
      home: const ResumenDiaScreen(),
    );
  }
}

class ResumenDiaScreen extends ConsumerWidget {
  const ResumenDiaScreen({super.key});

  static const Color moradoOscuro = Color(0xFF2C215C);
  static const Color morado = Color(0xFF453A7A);
  static const Color naranja = Color(0xFFE8A33D);
  static const Color fondoClaro = Color(0xFFF5F4FA);
  static const Color fondoFrase = Color(0xFFEEEBF7);
  static const Color borde = Color(0xFFE4E1F0);
  static const Color textoOscuro = Color(0xFF2B2B2B);
  static const Color textoGris = Color(0xFF6B6B6B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tareas = ref.watch(taskProvider);

    final completadas =
        tareas.where((tarea) => tarea.completada).length;

    final pendientes =
        tareas.where((tarea) => !tarea.completada).length;

    final porcentaje = tareas.isEmpty
        ? 0
        : ((completadas / tareas.length) * 100).round();

    return Scaffold(
      backgroundColor: fondoClaro,

      appBar: AppBar(
        backgroundColor: fondoClaro,
        elevation: 0,
        title: const Text(
          'TaskFlow',
          style: TextStyle(
            color: moradoOscuro,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Nota con Gemini',
            icon: const Icon(Icons.auto_awesome, color: moradoOscuro),
            onPressed: () async {
              final propuesta = await Navigator.push<modelo.Tarea>(context,
                MaterialPageRoute(builder: (_) => const NotaGeminiScreen()));
              if (!context.mounted || propuesta == null) return;
              final actuales = ref.read(taskProvider);
              final id = actuales.fold<int>(0, (max, t) => t.id > max ? t.id : max) + 1;
              ref.read(taskProvider.notifier).agregarTarea(Tarea(
                id: id, titulo: propuesta.titulo,
                detalle: '${formatearFecha(propuesta.fechaLimite)} · ${propuesta.categoria}'
                    '${propuesta.descripcion.isEmpty ? '' : '\n${propuesta.descripcion}'}',
                prioridad: propuesta.prioridadTexto,
              ));
            },
          ),
          IconButton(
            tooltip: 'Tareas en la nube',
            icon: const Icon(Icons.cloud, color: moradoOscuro),
            onPressed: () async {
              await Navigator.push<void>(context, MaterialPageRoute(
                builder: (_) => const TareasRemotasScreen(),
              ));
            },
          ),
          IconButton(
            tooltip: 'Experimento: isolates',
            icon: const Icon(Icons.science_outlined, color: moradoOscuro),
            onPressed: () async {
              await Navigator.push<void>(context, MaterialPageRoute(
                builder: (_) => const ExperimentoIsolateScreen(),
              ));
            },
          ),
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFEEEBF7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'N',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: moradoOscuro,
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: moradoOscuro),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Asistente de tareas'),
              onPressed: () => Navigator.push<void>(context, MaterialPageRoute(
                builder: (_) => const AsistenteScreen())),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: moradoOscuro),
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Escanear tarea'),
              onPressed: () async {
                final propuesta = await Navigator.push<modelo.Tarea>(context,
                  MaterialPageRoute(builder: (_) => const EscanearTareaScreen()));
                if (!context.mounted || propuesta == null) return;
                final actuales = ref.read(taskProvider);
                final id = actuales.fold<int>(0, (max, t) => t.id > max ? t.id : max) + 1;
                ref.read(taskProvider.notifier).agregarTarea(Tarea(
                  id: id, titulo: propuesta.titulo,
                  detalle: '${formatearFecha(propuesta.fechaLimite)} · ${propuesta.categoria}'
                      '${propuesta.descripcion.isEmpty ? '' : '\n${propuesta.descripcion}'}',
                  prioridad: propuesta.prioridadTexto,
                ));
              },
            ),
            const SizedBox(height: 12),
            // RESUMEN
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2C215C),
                        Color(0xFF453A7A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen del día',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$pendientes tareas pendientes',
                        style: const TextStyle(
                          color: Color(0xFFC8C2DD),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completadas tareas completadas',
                        style: const TextStyle(
                          color: Color(0xFFC8C2DD),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: -27,
                  child: Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: naranja,
                          width: 5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$porcentaje%',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: moradoOscuro,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // ESTADÍSTICAS
            Row(
              children: [
                Expanded(
                  child: _tarjetaEstadistica(
                    numero: '${tareas.length}',
                    texto: 'Tareas',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _tarjetaEstadistica(
                    numero: '$completadas',
                    texto: 'Completadas',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _tarjetaEstadistica(
                    numero: '$pendientes',
                    texto: 'Pendientes',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis tareas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textoOscuro,
                  ),
                ),
                Text(
                  '${tareas.length} registradas',
                  style: const TextStyle(
                    color: textoGris,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (tareas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borde),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 42,
                      color: morado,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No hay tareas registradas',
                      style: TextStyle(
                        color: textoGris,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...tareas.map(
                (tarea) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _tarjetaTarea(
                    tarea: tarea,
                    ref: ref,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: fondoFrase,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Organizar cada tarea ayuda a avanzar paso a paso hacia las metas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: morado,
                ),
              ),
            ),
          ],
        ),
      ),

      // AGREGAR TAREA
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: moradoOscuro,
        foregroundColor: Colors.white,
        onPressed: () {
          _mostrarFormulario(context, ref, tareas);
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar tarea'),
      ),

      bottomNavigationBar: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: borde,
              width: 1,
            ),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ItemNavegacion(
              icono: Icons.list_alt,
              texto: 'Tareas',
              activo: true,
            ),
            _ItemNavegacion(
              icono: Icons.water_drop_outlined,
              texto: 'Hábitos',
              activo: false,
            ),
            _ItemNavegacion(
              icono: Icons.person_outline,
              texto: 'Perfil',
              activo: false,
            ),
          ],
        ),
      ),
    );
  }

  static void _mostrarFormulario(
    BuildContext context,
    WidgetRef ref,
    List<Tarea> tareas,
  ) {
    final controlador = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva tarea'),
          content: TextField(
            controller: controlador,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre de la tarea',
              hintText: 'Ejemplo: Estudiar Flutter',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
          IconButton(
            tooltip: 'Nota con Gemini',
            icon: const Icon(Icons.auto_awesome, color: moradoOscuro),
            onPressed: () async {
              final propuesta = await Navigator.push<modelo.Tarea>(context,
                MaterialPageRoute(builder: (_) => const NotaGeminiScreen()));
              if (!context.mounted || propuesta == null) return;
              final actuales = ref.read(taskProvider);
              final id = actuales.fold<int>(0, (max, t) => t.id > max ? t.id : max) + 1;
              ref.read(taskProvider.notifier).agregarTarea(Tarea(
                id: id, titulo: propuesta.titulo,
                detalle: '${formatearFecha(propuesta.fechaLimite)} · ${propuesta.categoria}'
                    '${propuesta.descripcion.isEmpty ? '' : '\n${propuesta.descripcion}'}',
                prioridad: propuesta.prioridadTexto,
              ));
            },
          ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final titulo = controlador.text.trim();

                if (titulo.isEmpty) {
                  return;
                }

                final nuevoId = tareas.isEmpty
                    ? 1
                    : tareas
                            .map((tarea) => tarea.id)
                            .reduce((a, b) => a > b ? a : b) +
                        1;

                ref.read(taskProvider.notifier).agregarTarea(
                      Tarea(
                        id: nuevoId,
                        titulo: titulo,
                        detalle: 'Hoy · Universidad',
                        prioridad: 'Media',
                      ),
                    );

                Navigator.pop(context);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  Widget _tarjetaEstadistica({
    required String numero,
    required String texto,
  }) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            numero,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: moradoOscuro,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: textoGris,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaTarea({
    required Tarea tarea,
    required WidgetRef ref,
  }) {
    Color colorPrioridad;
    Color fondoPrioridad;

    if (tarea.prioridad == 'Alta') {
      colorPrioridad = Colors.red;
      fondoPrioridad = const Color(0xFFFFE6E4);
    } else if (tarea.prioridad == 'Media') {
      colorPrioridad = morado;
      fondoPrioridad = const Color(0xFFEEEBF7);
    } else {
      colorPrioridad = textoGris;
      fondoPrioridad = const Color(0xFFE9E9E9);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde),
      ),
      child: Row(
        children: [
          // COMPLETAR
          InkWell(
            onTap: () {
              ref
                  .read(taskProvider.notifier)
                  .completarTarea(tarea.id);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color:
                    tarea.completada ? moradoOscuro : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: tarea.completada
                      ? moradoOscuro
                      : const Color(0xFFB8B1D3),
                  width: 2,
                ),
              ),
              child: tarea.completada
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarea.titulo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: tarea.completada
                        ? TextDecoration.lineThrough
                        : null,
                    color: tarea.completada
                        ? textoGris
                        : textoOscuro,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tarea.detalle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textoGris,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: fondoPrioridad,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tarea.prioridad,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorPrioridad,
                  ),
                ),
              ),

              const SizedBox(height: 5),

              // ELIMINAR
              IconButton(
                tooltip: 'Eliminar tarea',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  ref
                      .read(taskProvider.notifier)
                      .eliminarTarea(tarea.id);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 21,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemNavegacion extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool activo;

  const _ItemNavegacion({
    required this.icono,
    required this.texto,
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    const moradoOscuro = Color(0xFF2C215C);

    return SizedBox(
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icono,
            size: 24,
            color: activo
                ? moradoOscuro
                : const Color(0xFFAAA5BA),
          ),
          const SizedBox(height: 3),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  activo ? FontWeight.bold : FontWeight.normal,
              color: activo
                  ? moradoOscuro
                  : const Color(0xFFAAA5BA),
            ),
          ),
        ],
      ),
    );
  }
}

