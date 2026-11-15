import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/propuestas_tarea.dart';
import '../modelos/tarea.dart';
import 'nueva_tarea_screen.dart';

class NotaGeminiScreen extends ConsumerStatefulWidget {
  const NotaGeminiScreen({super.key});
  @override
  ConsumerState<NotaGeminiScreen> createState() => _NotaGeminiScreenState();
}

class _NotaGeminiScreenState extends ConsumerState<NotaGeminiScreen> {
  final _nota = TextEditingController();
  bool _ocupado = false;
  String? _error;
  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _proponer() async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final propuesta = await ref
          .read(propuestasTareaProvider)
          .proponer(_nota.text);
      if (!mounted) return;
      final tarea = await Navigator.push<Tarea>(
        context,
        MaterialPageRoute(
          builder: (_) => NuevaTareaScreen(propuesta: propuesta),
        ),
      );
      if (mounted && tarea != null) Navigator.pop(context, tarea);
    } on ErrorPropuesta catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nota con Gemini')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'La nota se enviará a Gemini mediante Firebase AI Logic. Podrás revisar y editar antes de guardar.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nota,
          enabled: !_ocupado,
          maxLength: 4000,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Nota',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _ocupado ? null : _proponer,
          child: const Text('Proponer tarea'),
        ),
        if (_ocupado)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
        if (_error != null) Text(_error!),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}
