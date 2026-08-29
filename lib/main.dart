import 'package:flutter/material.dart';

void main() {
  runApp(const TaskFlowApp());
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

class ResumenDiaScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoClaro,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BARRA SUPERIOR
              SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TaskFlow',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: moradoOscuro,
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEEBF7),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'A',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: moradoOscuro,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // TARJETA DE CABECERA
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 108,
                    padding: const EdgeInsets.all(16),
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
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Buenos días, Ana',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Viernes 22 de agosto',
                          style: TextStyle(
                            color: Color(0xFFC8C2DD),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '3 tareas pendientes para hoy',
                          style: TextStyle(
                            color: Color(0xFFC8C2DD),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // INSIGNIA 60 %
                  Positioned(
                    right: 10,
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
                        child: const Text(
                          '60%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: moradoOscuro,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 44),

              // TARJETAS DE ESTADÍSTICAS
              Row(
                children: [
                  Expanded(
                    child: _tarjetaEstadistica(
                      numero: '12',
                      texto: 'Tareas',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _tarjetaEstadistica(
                      numero: '7',
                      texto: 'Completadas',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _tarjetaEstadistica(
                      numero: '5',
                      texto: 'Racha semanal',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ENCABEZADO DE SECCIÓN
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tareas de hoy',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textoOscuro,
                    ),
                  ),
                  Text(
                    'Ver todas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: naranja,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // PRIMERA TAREA
              Container(
                width: double.infinity,
                height: 104,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borde),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFB8B1D3),
                          width: 2,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Expanded permite que el contenido se adapte
                    // al espacio disponible dentro del Row.
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Terminar el laboratorio de layouts y composición visual',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textoOscuro,
                            ),
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: textoGris,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Hoy · Universidad',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textoGris,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6E4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Alta',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // SEGUNDA TAREA
              _tarjetaTarea(
                titulo: 'Revisar los pull requests',
                detalle: 'Hoy · Trabajo',
                prioridad: 'Media',
                completada: true,
              ),

              const SizedBox(height: 12),

              // TERCERA TAREA
              _tarjetaTarea(
                titulo: 'Leer la documentación',
                detalle: 'Mañana · Aprendizaje',
                prioridad: 'Baja',
                completada: false,
              ),

              const SizedBox(height: 18),

              // TARJETA DE FRASE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: fondoFrase,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“',
                      style: TextStyle(
                        fontSize: 42,
                        height: 0.8,
                        color: Color(0xFFB7B0D1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'La disciplina es el puente entre las metas\n'
                            'y los logros que realmente importan.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                              color: morado,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            '— Jim Rohn',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: moradoOscuro,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // BARRA INFERIOR
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
              icono: Icons.water_drop,
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

  Widget _tarjetaEstadistica({
    required String numero,
    required String texto,
  }) {
    return Container(
      height: 68,
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
    required String titulo,
    required String detalle,
    required String prioridad,
    required bool completada,
  }) {
    Color colorPrioridad;
    Color fondoPrioridad;

    if (prioridad == 'Media') {
      colorPrioridad = morado;
      fondoPrioridad = const Color(0xFFEEEBF7);
    } else {
      colorPrioridad = textoGris;
      fondoPrioridad = const Color(0xFFE9E9E9);
    }

    return Container(
      width: double.infinity,
      height: 84,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde),
      ),
      child: Row(
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: completada ? moradoOscuro : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: completada
                    ? moradoOscuro
                    : const Color(0xFFB8B1D3),
                width: 2,
              ),
            ),
            child: completada
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 17,
                  )
                : null,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration:
                        completada ? TextDecoration.lineThrough : null,
                    color: completada ? textoGris : textoOscuro,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: textoGris,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      detalle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textoGris,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: fondoPrioridad,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              prioridad,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorPrioridad,
              ),
            ),
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