import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/modelos/tarea.dart';

void main() {
  test('JSON 1: datos completos y fecha predeterminada', () {
    final antes = DateTime.now().add(const Duration(days: 7));
    final tarea = Tarea.fromJson({
      'id': 7,
      'title': ' Leer ',
      'completed': true,
    });
    expect(tarea.id, 7);
    expect(tarea.titulo, 'Leer');
    expect(tarea.completada, isTrue);
    expect(tarea.fechaLimite.isBefore(antes), isFalse);
    expect(tarea.fechaLimite.difference(antes).inSeconds, lessThan(2));
    expect(tarea.categoria, 'General');
    expect(tarea.descripcion, '');
    expect(tarea.prioridad, 2);
  });
  test('JSON 2: id y completed ausentes', () {
    final tarea = Tarea.fromJson({'title': 'Leer'});
    expect(tarea.id, isNull);
    expect(tarea.completada, isFalse);
  });
  test('JSON 3: título ausente', () {
    expect(() => Tarea.fromJson({}), throwsFormatException);
  });
  test('JSON 4: título de espacios', () {
    expect(() => Tarea.fromJson({'title': '  '}), throwsFormatException);
  });
  test('JSON 5: título numérico', () {
    expect(() => Tarea.fromJson({'title': 8}), throwsFormatException);
  });
  test('JSON 6: id de texto', () {
    expect(
      () => Tarea.fromJson({'title': 'Leer', 'id': '1'}),
      throwsFormatException,
    );
  });
  test('JSON 7: completed de texto', () {
    expect(
      () => Tarea.fromJson({'title': 'Leer', 'completed': 'false'}),
      throwsFormatException,
    );
  });
  test('JSON 8: toJson envía únicamente el contrato requerido', () {
    final tarea = Tarea(
      id: 9,
      titulo: 'Leer',
      fechaLimite: DateTime(2026),
      completada: true,
    );
    expect(tarea.toJson(), {'title': 'Leer', 'completed': true, 'userId': 1});
  });
}
