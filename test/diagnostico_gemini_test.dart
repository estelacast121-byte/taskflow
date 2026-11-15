import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/datos/propuestas_tarea.dart';

void main() {
  test('clasifica códigos sin devolver mensajes sensibles', () {
    expect(
      codigoDiagnostico(FirebaseAIException('Server Error [503]: secreto')),
      'HTTP_503',
    );
    expect(
      codigoDiagnostico(FirebaseAIException('PERMISSION_DENIED: secreto')),
      'PERMISSION_DENIED',
    );
    expect(
      codigoDiagnostico(FirebaseAIException('token-secreto')),
      'NO_EXPUESTO_POR_SDK',
    );
    expect(
      codigoDiagnostico(
        FirebaseException(
          plugin: 'app_check',
          code: 'unavailable',
          message: 'secreto',
        ),
      ),
      'unavailable',
    );
    expect(codigoDiagnostico(QuotaExceeded('secreto')), 'RESOURCE_EXHAUSTED');
    expect(codigoDiagnostico(TimeoutException('secreto')), 'TIMEOUT_LOCAL');
  });

  test('espera predeterminada es 120 segundos', () {
    expect(PropuestasTarea().espera, const Duration(seconds: 120));
  });

  test('observa error tardío sin imprimir nota, mensaje ni tokens', () async {
    final mensajes = <String>[];
    final anterior = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) mensajes.add(message);
    };
    addTearDown(() => debugPrint = anterior);
    final pendiente = Completer<String?>();
    final servicio = PropuestasTarea(
      generar: (_, _) => pendiente.future,
      espera: const Duration(milliseconds: 1),
    );
    await expectLater(
      servicio.proponer('NOTA_PRIVADA'),
      throwsA(isA<ErrorPropuesta>()),
    );
    pendiente.completeError(
      FirebaseAIException('PERMISSION_DENIED TOKEN_PRIVADO'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(mensajes.join(), contains('error_origen_incluso_si_tardio'));
    expect(mensajes.join(), contains('PERMISSION_DENIED'));
    expect(mensajes.join(), isNot(contains('NOTA_PRIVADA')));
    expect(mensajes.join(), isNot(contains('TOKEN_PRIVADO')));
  });
}
