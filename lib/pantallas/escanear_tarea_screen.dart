import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/reconocedor_texto.dart';
import '../modelos/tarea.dart';
import 'nueva_tarea_screen.dart';

class EscanearTareaScreen extends ConsumerStatefulWidget {
  const EscanearTareaScreen({super.key});
  @override
  ConsumerState<EscanearTareaScreen> createState() =>
      _EscanearTareaScreenState();
}

class _EscanearTareaScreenState extends ConsumerState<EscanearTareaScreen> {
  bool _ocupado = false;
  String? _texto;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _procesar(null));
  }

  Future<void> _procesar(FuenteFoto? fuente) async {
    if (_ocupado || !mounted) return;
    setState(() {
      _ocupado = true;
      _texto = null;
      _mensaje = null;
    });
    try {
      final servicio = ref.read(reconocedorTextoProvider);
      final texto = await (fuente == null
          ? servicio.recuperarPendiente()
          : servicio.reconocer(fuente));
      if (!mounted) return;
      setState(() {
        _texto = texto;
        if (texto != null && texto.trim().isEmpty) {
          _mensaje =
              'No se reconoció texto. Prueba una foto más clara y recta.';
        }
      });
    } on UnsupportedError catch (error) {
      if (mounted) setState(() => _mensaje = error.message.toString());
    } on PlatformException {
      if (mounted) {
        setState(
          () => _mensaje =
              'No se pudo acceder a la foto o procesarla. '
              'Comprueba los permisos y que haya una aplicación de cámara '
              'disponible, o selecciona otra imagen de la galería.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _mensaje =
              'No se pudo reconocer la imagen. '
              'Intenta de nuevo con otra fotografía.',
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _revisar() async {
    final tarea = await Navigator.push<Tarea>(
      context,
      MaterialPageRoute(
        builder: (_) => NuevaTareaScreen(textoReconocido: _texto),
      ),
    );
    if (mounted && tarea != null) Navigator.pop(context, tarea);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Escanear tarea')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Selecciona una nota, pizarra o documento. El reconocimiento '
          'se realiza en el dispositivo. Nada se guarda hasta que revises '
          'y confirmes la tarea.',
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _ocupado ? null : () => _procesar(FuenteFoto.galeria),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Seleccionar de la galería'),
        ),
        OutlinedButton.icon(
          onPressed: _ocupado ? null : () => _procesar(FuenteFoto.camara),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Tomar fotografía'),
        ),
        if (_ocupado)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Procesando fotografía…'),
              ],
            ),
          ),
        if (_mensaje != null) Text(_mensaje!),
        if (_texto != null && _texto!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Texto reconocido (mantén pulsado para copiar):'),
          SelectableText(_texto!),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _revisar,
            child: const Text('Revisar propuesta de tarea'),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}
