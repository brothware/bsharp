import 'package:bsharp/data/providers/mobireg/parsers/json_fields.dart';
import 'package:flutter_test/flutter_test.dart';

const _privateName = 'Maria Kowalska';

Matcher _hidesValues() => throwsA(
  isA<FormatException>().having(
    (e) => '${e.source}',
    'source',
    isNot(contains(_privateName)),
  ),
);

void main() {
  final record = <String, dynamic>{'id': 'x', 'name': _privateName};

  test('a bad int field names the keys, not the values', () {
    expect(() => intField(record, 'id', 'users'), _hidesValues());
  });

  test('a bad string field names the keys, not the values', () {
    expect(() => stringField(record, 'missing', 'users'), _hidesValues());
  });

  test('a non-list view names its type, not its content', () {
    expect(() => objectsOf(record, 'users'), _hidesValues());
  });

  test('a non-object item names its type, not its content', () {
    expect(() => objectsOf([_privateName], 'users'), _hidesValues());
  });
}
