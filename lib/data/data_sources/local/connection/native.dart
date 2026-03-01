import 'package:drift/native.dart';
import 'package:bsharp/data/data_sources/local/database.dart';

AppDatabase? createTranslationDatabase() => AppDatabase(NativeDatabase.memory());
