// Entrada temporal independiente: no importa ni inicializa Firebase.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MaterialApp(home: ConectividadScreen()));

class ConectividadScreen extends StatefulWidget {
  const ConectividadScreen({super.key});
  @override
  State<ConectividadScreen> createState() => _ConectividadScreenState();
}

class _ConectividadScreenState extends State<ConectividadScreen> {
  static const _host = 'firebasevertexai.googleapis.com';
  static final _uri = Uri.https(_host, '/');
  // Límites propios del diagnóstico; no cambian el timeout de Gemini.
  static const _limite = Duration(seconds: 45);
  final _lineas = <String>[];
  bool _ocupado = false;

  void _log(String mensaje) {
    if (!mounted) return;
    final linea = '[TaskFlow Red] $mensaje';
    if (kDebugMode) debugPrint(linea);
    setState(() => _lineas.add(linea));
  }

  Future<void> _etapa(String nombre, Future<void> Function() probar) async {
    final reloj = Stopwatch()..start();
    _log('etapa=$nombre inicio');
    try {
      await probar();
      _log('etapa=$nombre fin ms=${reloj.elapsedMilliseconds}');
    } catch (error) {
      _log(
        'etapa=$nombre error ms=${reloj.elapsedMilliseconds} tipo=${error.runtimeType}',
      );
      // Solo mensajes técnicos de una petición fija, pública y sin autenticación.
      // No registrar toString(), cabeceras, cuerpo ni direcciones resueltas.
      if (error is SocketException) {
        _log(
          'categoria=socket mensaje=${error.message} '
          'os_codigo=${error.osError?.errorCode} os_mensaje=${error.osError?.message}',
        );
      } else if (error is HandshakeException) {
        _log(
          'categoria=tls mensaje=${error.message} '
          'os_codigo=${error.osError?.errorCode} os_mensaje=${error.osError?.message}',
        );
      } else if (error is TlsException) {
        _log(
          'categoria=tls mensaje=${error.message} '
          'os_codigo=${error.osError?.errorCode} os_mensaje=${error.osError?.message}',
        );
      } else if (error is HttpException) {
        _log('categoria=http_transporte mensaje=${error.message}');
      } else if (error is http.ClientException) {
        _log('categoria=cliente_http mensaje=${error.message}');
      } else if (error is TimeoutException) {
        _log('categoria=timeout_diagnostico limite_s=45');
      } else {
        _log('categoria=no_clasificada');
      }
    }
  }

  Future<void> _ejecutar() async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _lineas.clear();
    });
    try {
      _log('destino=$_host:443 ruta=/ autenticacion=ninguna');
      await _etapa('dns', () async {
        final direcciones = await InternetAddress.lookup(_host)
            .timeout(_limite);
        _log(
          'dns resultados=${direcciones.length} '
          'ipv4=${direcciones.where((d) => d.type == InternetAddressType.IPv4).length} '
          'ipv6=${direcciones.where((d) => d.type == InternetAddressType.IPv6).length}',
        );
      });
      await _etapa('https_dart_io', () async {
        final cliente = HttpClient();
        final reloj = Stopwatch()..start();
        try {
          await (() async {
            final peticion = await cliente.getUrl(_uri);
            peticion.followRedirects = false;
            _log(
              'https_dart_io conexion_abierta_ms=${reloj.elapsedMilliseconds}',
            );
            final respuesta = await peticion.close();
            _log(
              'https_dart_io estado_http=${respuesta.statusCode} '
              'cabeceras_ms=${reloj.elapsedMilliseconds}',
            );
            await respuesta.drain<void>();
          })().timeout(_limite);
        } finally {
          cliente.close(force: true);
        }
      });
      await _etapa('https_package_http', () async {
        // Misma fábrica http.Client() que usa firebase_ai en Android.
        final cliente = http.Client();
        final reloj = Stopwatch()..start();
        try {
          await (() async {
            final peticion = http.Request('GET', _uri)..followRedirects = false;
            final respuesta = await cliente.send(peticion);
            _log(
              'https_package_http estado_http=${respuesta.statusCode} '
              'cabeceras_ms=${reloj.elapsedMilliseconds}',
            );
            await respuesta.stream.drain<void>();
          })().timeout(_limite);
        } finally {
          cliente.close();
        }
      });
      _log('diagnostico_finalizado');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diagnóstico HTTPS aislado')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'DNS y GET público, sin claves, tokens ni notas. '
            'No ejecuta Gemini. Cada etapa tiene un máximo de 45 segundos.',
          ),
          FilledButton(
            onPressed: _ocupado ? null : _ejecutar,
            child: const Text('Probar conectividad'),
          ),
          if (_ocupado) const LinearProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(_lineas.join('\n')),
            ),
          ),
        ],
      ),
    ),
  );
}
