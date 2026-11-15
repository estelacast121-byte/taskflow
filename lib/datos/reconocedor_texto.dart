import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

enum FuenteFoto { galeria, camara }

abstract interface class ReconocedorTexto {
  Future<String?> reconocer(FuenteFoto fuente);
  Future<String?> recuperarPendiente();
}

final reconocedorTextoProvider = Provider<ReconocedorTexto>(
  (ref) => ReconocedorTextoMlKit(),
);

class ReconocedorTextoMlKit implements ReconocedorTexto {
  final _selector = ImagePicker();

  void _comprobarPlataforma() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw UnsupportedError('El escaneo requiere Android o iOS.');
    }
  }

  Future<String> _procesar(XFile foto) async {
    final reconocedor = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final resultado = await reconocedor.processImage(
        InputImage.fromFilePath(foto.path),
      );
      return resultado.text;
    } finally {
      await reconocedor.close();
    }
  }

  @override
  Future<String?> reconocer(FuenteFoto fuente) async {
    _comprobarPlataforma();
    final foto = await _selector.pickImage(
      source: fuente == FuenteFoto.camara
          ? ImageSource.camera
          : ImageSource.gallery,
      requestFullMetadata: false,
    );
    return foto == null ? null : _procesar(foto);
  }

  @override
  Future<String?> recuperarPendiente() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final respuesta = await _selector.retrieveLostData();
    if (respuesta.exception != null) throw respuesta.exception!;
    final fotos = respuesta.files;
    return fotos == null || fotos.isEmpty ? null : _procesar(fotos.first);
  }
}
