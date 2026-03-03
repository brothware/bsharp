import 'dart:io';

import 'package:bsharp/data/data_sources/local/database.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<AppDatabase?> createCustomEventDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'custom_events.db'));
  return AppDatabase(NativeDatabase.createInBackground(file));
}
