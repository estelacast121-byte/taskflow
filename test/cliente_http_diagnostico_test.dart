import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:taskflow/datos/cliente_http_diagnostico.dart';

class ClienteFalso extends http.BaseClient {
  ClienteFalso(this.enviar);
  final Future<http.StreamedResponse> Function(http.BaseRequest) enviar;
  bool cerrado = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      enviar(request);
  @override
  void close() {
    cerrado = true;
  }
}

void main() {
  test(
    'conserva identidad, método, URL, cabeceras, cuerpo y opciones',
    () async {
      final logs = <String>[];
      final uri = Uri.parse(
        'https://example.invalid/URL_PRIVADA?clave=SECRETO',
      );
      final solicitud = http.Request('POST', uri)
        ..headers['Authorization'] = 'TOKEN_PRIVADO'
        ..headers['X-Firebase-AppCheck'] = 'APP_CHECK_PRIVADO'
        ..body = 'NOTA_PRIVADA'
        ..followRedirects = false
        ..maxRedirects = 2
        ..persistentConnection = false;
      final falso = ClienteFalso((recibida) async {
        expect(identical(recibida, solicitud), true);
        expect(recibida.method, 'POST');
        expect(recibida.url, uri);
        expect(recibida.headers['Authorization'], 'TOKEN_PRIVADO');
        expect(recibida.headers['X-Firebase-AppCheck'], 'APP_CHECK_PRIVADO');
        expect(recibida.followRedirects, false);
        expect(recibida.maxRedirects, 2);
        expect(recibida.persistentConnection, false);
        expect(await recibida.finalize().bytesToString(), 'NOTA_PRIVADA');
        return http.StreamedResponse(
          Stream.fromIterable([
            [1, 2],
            [3],
          ]),
          200,
          headers: {'secreto': 'CABECERA_PRIVADA'},
          contentLength: 3,
          request: recibida,
          reasonPhrase: 'MENSAJE_PRIVADO',
          persistentConnection: false,
        );
      });
      final cliente = ClienteHttpDiagnostico(
        falso,
        intento: 7,
        registrar: logs.add,
      );
      final respuesta = await cliente.send(solicitud);
      expect(respuesta.headers['secreto'], 'CABECERA_PRIVADA');
      expect(respuesta.reasonPhrase, 'MENSAJE_PRIVADO');
      expect(respuesta.contentLength, 3);
      expect(respuesta.persistentConnection, false);
      expect(await respuesta.stream.toBytes(), [1, 2, 3]);
      expect(logs.join(), contains('send_entrada'));
      expect(logs.join(), contains('cabeceras_recibidas'));
      expect(logs.join(), contains('primer_fragmento'));
      expect(logs.last, contains('lectura_finalizada'));
      expect(logs.last, contains('bytes=3'));
      for (final secreto in [
        'URL_PRIVADA',
        'SECRETO',
        'TOKEN_PRIVADO',
        'APP_CHECK_PRIVADO',
        'NOTA_PRIVADA',
        'CABECERA_PRIVADA',
        'MENSAJE_PRIVADO',
      ]) {
        expect(logs.join(), isNot(contains(secreto)));
      }
      cliente.close();
      expect(falso.cerrado, true);
    },
  );

  for (final error in [
    const SocketException('SECRETO'),
    const HandshakeException('SECRETO'),
    http.ClientException(
      'SECRETO',
      Uri.parse('https://example.invalid/PRIVADO'),
    ),
  ]) {
    test(
      'conserva excepción de envío ${error.runtimeType} sin mensaje sensible',
      () async {
        final logs = <String>[];
        final cliente = ClienteHttpDiagnostico(
          ClienteFalso((_) async => throw error),
          intento: 1,
          registrar: logs.add,
        );
        await expectLater(
          cliente.send(http.Request('POST', Uri.https('example.invalid', '/'))),
          throwsA(same(error)),
        );
        expect(logs.last, contains('error_antes_cabeceras'));
        expect(logs.last, contains('transporte='));
        expect(logs.join(), isNot(contains('SECRETO')));
        expect(logs.join(), isNot(contains('PRIVADO')));
        cliente.close();
      },
    );
  }

  test(
    'error de lectura conserva objeto y stack sin registrar cuerpo',
    () async {
      final logs = <String>[];
      final error = const HttpException('CUERPO_PRIVADO');
      final stack = StackTrace.current;
      final fuente = StreamController<List<int>>();
      final cliente = ClienteHttpDiagnostico(
        ClienteFalso((_) async => http.StreamedResponse(fuente.stream, 503)),
        intento: 2,
        registrar: logs.add,
      );
      final respuesta = await cliente.send(
        http.Request('POST', Uri.https('example.invalid', '/')),
      );
      final recibido = Completer<void>();
      respuesta.stream.listen(
        (_) {},
        onError: (Object e, StackTrace s) {
          expect(identical(e, error), true);
          expect(identical(s, stack), true);
          recibido.complete();
        },
      );
      fuente.add([10]);
      fuente.addError(error, stack);
      await recibido.future;
      await fuente.close();
      expect(logs.join(), contains('error_lectura'));
      expect(logs.join(), contains('estado_http=503'));
      expect(logs.join(), isNot(contains('CUERPO_PRIVADO')));
      cliente.close();
    },
  );

  test('cuerpo vacío no registra primer fragmento', () async {
    final logs = <String>[];
    final cliente = ClienteHttpDiagnostico(
      ClienteFalso(
        (_) async => http.StreamedResponse(const Stream.empty(), 204),
      ),
      intento: 3,
      registrar: logs.add,
    );
    final respuesta = await cliente.send(
      http.Request('GET', Uri.https('example.invalid', '/')),
    );
    await respuesta.stream.drain<void>();
    expect(logs.join(), isNot(contains('primer_fragmento')));
    expect(logs.last, contains('bytes=0'));
    cliente.close();
  });
}
