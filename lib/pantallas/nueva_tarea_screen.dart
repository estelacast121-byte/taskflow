import 'package:flutter/material.dart';

import '../modelos/tarea.dart';
import '../datos/propuestas_tarea.dart';
import '../utils/formato.dart';
import '../validacion/validadores_tarea.dart';

/// SEMANA 13 - SESION 2: pantalla "Nueva tarea".
///
/// Decision de diseno (Opcion B): esta pantalla NO conoce Riverpod.
/// Construye la Tarea y la DEVUELVE con Navigator.pop(context, tarea).
/// Quien la abrio decide que hacer con el resultado.
/// Lectura: Libro B, Cap. 7, "Sending data backwards", pp. 264-267.
class NuevaTareaScreen extends StatefulWidget {
  const NuevaTareaScreen({super.key, this.textoReconocido, this.propuesta});
  final String? textoReconocido;
  final PropuestaTarea? propuesta;

  @override
  State<NuevaTareaScreen> createState() => _NuevaTareaScreenState();
}

class _NuevaTareaScreenState extends State<NuevaTareaScreen> {
  // (1) Estado EFIMERO: vive y muere con esta pantalla.
  //     Lectura: Libro A, Cap. 3, pp. 76-78 (Tabla 3.1).
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _descripcionFocus = FocusNode();

  DateTime? _fechaLimite; // fuente de verdad de la fecha
  int _prioridad = 2;
  String _categoria = 'General';

  static const _categorias = ['General', 'Estudio', 'Trabajo', 'Personal'];

  @override
  void initState() {
    super.initState();
    final propuesta = widget.propuesta;
    if (propuesta != null) {
      _tituloCtrl.text = propuesta.titulo;
      _descripcionCtrl.text = propuesta.descripcion;
      _fechaLimite = propuesta.fechaLimite;
      if (_fechaLimite != null) _fechaCtrl.text = formatearFecha(_fechaLimite!);
    }
    final texto = widget.textoReconocido;
    if (texto != null) {
      final lineas = texto
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty);
      _tituloCtrl.text = lineas.isEmpty ? '' : lineas.first;
      _descripcionCtrl.text = texto;
    }
  }

  // (2) Cuatro objetos con dispose() creados por nosotros -> cuatro liberaciones.
  //     Lectura: Libro B, Cap. 10, pp. 350-351.
  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _fechaCtrl.dispose();
    _descripcionFocus.dispose();
    super.dispose();
  }

  // (3) Selector de fecha: firstDate impide dias pasados desde la UI.
  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaLimite ?? hoy,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year + 2),
      helpText: 'Fecha límite de la tarea',
    );
    // Safe-await pattern: tras el await la pantalla pudo cerrarse.
    if (elegida == null || !mounted) return;
    setState(() {
      _fechaLimite = elegida;
      _fechaCtrl.text = formatearFecha(elegida);
    });
  }

  // (4) Guardar: validar TODO y devolver la tarea a quien abrio la pantalla.
  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final tarea = Tarea(
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      fechaLimite: _fechaLimite!, // seguro: el validador ya lo exigio
      categoria: _categoria,
      prioridad: _prioridad,
    );
    Navigator.pop(context, tarea);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva tarea')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        // (5) ListView y no Column: con teclado abierto o texto ampliado
        //     el formulario se desplaza sin overflow.
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.propuesta != null)
              const Text(
                'Revisa y corrige la propuesta de Gemini antes de guardar. Media y General son valores iniciales.',
              ),
            if (widget.textoReconocido != null) ...[
              const Text(
                'Revisa la propuesta: el reconocimiento puede equivocarse. '
                'Corrige título y descripción, elige la fecha y revisa prioridad '
                'y categoría antes de guardar. Media y General son valores '
                'iniciales, no datos reconocidos.',
              ),
              ExpansionTile(
                title: const Text('Texto reconocido completo'),
                initiallyExpanded: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(widget.textoReconocido!),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // (6) Titulo: obligatorio, contador, foco al siguiente campo.
            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: 'Título *',
                helperText: 'Obligatorio, entre 3 y 60 caracteres',
                border: OutlineInputBorder(),
              ),
              maxLength: ValidadoresTarea.tituloMax,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _descripcionFocus.requestFocus(),
              validator: ValidadoresTarea.titulo,
            ),
            const SizedBox(height: 12),

            // (7) Descripcion: opcional y multilinea ("Enter" = salto de linea).
            TextFormField(
              controller: _descripcionCtrl,
              focusNode: _descripcionFocus,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 2,
              maxLines: 4,
              maxLength: ValidadoresTarea.descripcionMax,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              validator: ValidadoresTarea.descripcion,
            ),
            const SizedBox(height: 12),

            // (8) Fecha: solo lectura; el validador revisa _fechaLimite,
            //     no el texto (el texto solo sirve para mostrarla).
            TextFormField(
              controller: _fechaCtrl,
              readOnly: true,
              onTap: _elegirFecha,
              decoration: const InputDecoration(
                labelText: 'Fecha límite *',
                hintText: 'Toca para elegir',
                suffixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              validator: (_) => ValidadoresTarea.fechaLimite(_fechaLimite),
            ),
            const SizedBox(height: 12),

            // (9) Opciones cerradas: la mejor validacion es la que no hace falta.
            //     Flutter 3.35+: initialValue (antes se llamaba value).
            DropdownButtonFormField<int>(
              initialValue: _prioridad,
              decoration: const InputDecoration(
                labelText: 'Prioridad',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Baja')),
                DropdownMenuItem(value: 2, child: Text('Media')),
                DropdownMenuItem(value: 3, child: Text('Alta')),
              ],
              onChanged: (valor) => setState(() => _prioridad = valor ?? 2),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in _categorias)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (valor) =>
                  setState(() => _categoria = valor ?? 'General'),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.check),
              label: const Text('Guardar tarea'),
            ),
          ],
        ),
      ),
    );
  }
}
