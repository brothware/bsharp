import 'dart:convert';
import 'dart:io';

const _fixturesDirectory = 'test/fixtures/mobireg';

Object loadMobiregFixture(String name) {
  final content = File('$_fixturesDirectory/$name.json').readAsStringSync();
  return jsonDecode(content) as Object;
}
