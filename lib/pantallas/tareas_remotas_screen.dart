import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/tareas_api.dart';
import '../estado/tareas_remotas_provider.dart';
import '../modelos/tarea.dart';
import 'nueva_tarea_screen.dart';

class TareasRemotasScreen extends ConsumerWidget {
  const TareasRemotasScreen({super.key});

  Future<void> _nuevaTarea(BuildContext context, WidgetRef ref) async {
    final tarea = await Navigator.push<Tarea>(
      context,
      MaterialPageRoute(builder: (_) => const NuevaTareaScreen()),
    );
    if (!context.mounted || tarea == null) return;
    final avisos = ScaffoldMessenger.of(context);
    avisos.showSnackBar(const SnackBar(content: Text('Enviando tarea...')));
    try {
      await ref.read(tareasRemotasProvider.notifier).crear(tarea);
      if (!context.mounted) return;
      avisos.hideCurrentSnackBar();
      avisos.showSnackBar(
        const SnackBar(
          content: Text(
            'Tarea enviada. JSONPlaceholder no la guarda permanentemente.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!context.mounted) return;
      avisos.hideCurrentSnackBar();
      avisos.showSnackBar(SnackBar(content: Text(error.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tareas = ref.watch(tareasRemotasProvider);
    const morado = Color(0xFF2C215C);
    return Scaffold(
      appBar: AppBar(title: const Text('Tareas en la nube')),
      body: tareas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is ApiException
                      ? error.mensaje
                      : 'No se pudieron cargar las tareas.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    await ref.read(tareasRemotasProvider.notifier).recargar();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (lista) => RefreshIndicator(
          onRefresh: ref.read(tareasRemotasProvider.notifier).recargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No hay tareas en la nube.'),
                ),
              for (final tarea in lista)
                Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: Icon(
                      tarea.completada
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: morado,
                    ),
                    title: Text(tarea.titulo),
                    subtitle: Text(
                      tarea.completada ? 'Completada' : 'Pendiente',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: morado,
        foregroundColor: Colors.white,
        onPressed: tareas.hasValue && !tareas.isLoading
            ? () => _nuevaTarea(context, ref)
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),
    );
  }
}
