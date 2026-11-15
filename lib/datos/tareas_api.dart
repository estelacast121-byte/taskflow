import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/tarea.dart';

class ApiException implements Exception {
  final String mensaje;
  final int? codigo;

  const ApiException(this.mensaje, [this.codigo]);

  @override
  String toString() => mensaje;
}

class TareasApi {
  final http.Client cliente;

  static final _base = Uri.parse(
    'https://jsonplaceholder.typicode.com',
  );

  TareasApi(this.cliente);

  Future<http.Response> _solicitar(
    Future<http.Response> peticion,
  ) async {
    try {
      return await peticion.timeout(
        const Duration(seconds: 10),
      );
    } on TimeoutException {
      throw const ApiException(
        'La solicitud tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const ApiException(
        'No se pudo conectar. Revisa tu conexión.',
      );
    }
  }

  dynamic _decodificar(http.Response respuesta) {
    try {
      return jsonDecode(
        utf8.decode(respuesta.bodyBytes),
      );
    } on FormatException {
      throw const ApiException(
        'El servidor devolvió un JSON incorrecto.',
      );
    }
  }

  Future<List<Tarea>> obtenerTareas() async {
    final respuesta = await _solicitar(
      cliente.get(
        _base.resolve('/todos?_limit=15'),
      ),
    );

    if (respuesta.statusCode != 200) {
      throw ApiException(
        'No se pudieron cargar las tareas '
        '(HTTP ${respuesta.statusCode}).',
        respuesta.statusCode,
      );
    }

    final datos = _decodificar(respuesta);

    if (datos is! List) {
      throw const ApiException(
        'Se esperaba una lista de tareas.',
      );
    }

    final tareas = <Tarea>[];

    for (final dato in datos) {
      if (dato is! Map<String, dynamic>) continue;

      try {
        tareas.add(Tarea.fromJson(dato));
      } on FormatException {
        // Un registro inválido no impide mostrar los demás.
        continue;
      }
    }

    return tareas;
  }

  Future<Tarea> crearTarea(Tarea tarea) async {
    final respuesta = await _solicitar(
      cliente.post(
        _base.resolve('/todos'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(tarea.toJson()),
      ),
    );

    if (respuesta.statusCode != 201) {
      throw ApiException(
        'No se pudo crear la tarea '
        '(HTTP ${respuesta.statusCode}).',
        respuesta.statusCode,
      );
    }

    final datos = _decodificar(respuesta);

    if (datos is! Map<String, dynamic>) {
      throw const ApiException(
        'Se esperaba una tarea en la respuesta.',
      );
    }

    try {
      return Tarea.fromJson(datos);
    } on FormatException {
      throw const ApiException(
        'La tarea recibida tiene datos incorrectos.',
      );
    }
  }
}