import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Diagnóstico temporal. Reenvía el mismo objeto de solicitud sin finalizarlo.
class ClienteHttpDiagnostico extends http.BaseClient {
  ClienteHttpDiagnostico(
    this._cliente, {
    required this.intento,
    void Function(String)? registrar,
  }) : _registrar = registrar ?? debugPrint;
  final http.Client _cliente;
  final int intento;
  final void Function(String) _registrar;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final reloj = Stopwatch()..start();
    var bytes = 0;
    var primero = false;
    void log(String evento, {int? estado, Object? error}) {
      if (!kDebugMode) return;
      // Lista cerrada: no mensajes crudos, URL, cuerpo ni cabeceras.
      final transporte = error == null ? '' : _clasificar(error);
      _registrar(
        '[TaskFlow HTTP #$intento] evento=$evento ms=${reloj.elapsedMilliseconds} '
        'bytes=$bytes${estado == null ? '' : ' estado_http=$estado'}$transporte',
      );
    }

    log('send_entrada');
    late final http.StreamedResponse respuesta;
    try {
      respuesta = await _cliente.send(request);
    } catch (error) {
      log('error_antes_cabeceras', error: error);
      rethrow;
    }
    log('cabeceras_recibidas', estado: respuesta.statusCode);
    final observado = respuesta.stream.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (fragmento, salida) {
          bytes += fragmento.length;
          if (!primero) {
            primero = true;
            log('primer_fragmento', estado: respuesta.statusCode);
          }
          salida.add(fragmento);
        },
        handleError: (Object error, StackTrace stack, salida) {
          log('error_lectura', estado: respuesta.statusCode, error: error);
          salida.addError(error, stack);
        },
        handleDone: (salida) {
          log('lectura_finalizada', estado: respuesta.statusCode);
          salida.close();
        },
      ),
    );
    return http.StreamedResponse(
      observado,
      respuesta.statusCode,
      contentLength: respuesta.contentLength,
      request: respuesta.request,
      headers: respuesta.headers,
      isRedirect: respuesta.isRedirect,
      persistentConnection: respuesta.persistentConnection,
      reasonPhrase: respuesta.reasonPhrase,
    );
  }

  static String _clasificar(Object error) {
    String clase;
    if (error is HandshakeException) {
      clase = 'HandshakeException';
    } else if (error is TlsException) {
      clase = 'TlsException';
    } else if (error is SocketException) {
      clase = error is http.ClientException
          ? 'ClientException_SocketException'
          : 'SocketException';
    } else if (error is http.ClientException) {
      clase = 'ClientException';
    } else if (error is HttpException) {
      clase = 'HttpException';
    } else if (error is TimeoutException) {
      clase = 'TimeoutException';
    } else {
      clase = 'otra';
    }
    final codigo = error is SocketException
        ? error.osError?.errorCode
        : error is TlsException
        ? error.osError?.errorCode
        : null;
    return ' transporte=$clase${codigo == null ? '' : ' os_codigo=$codigo'}';
  }

  @override
  void close() => _cliente.close();
}
