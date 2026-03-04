import 'package:bsharp/data/data_sources/local/database.dart';
import 'package:drift/native.dart';

AppDatabase? createTranslationDatabase() =>
    AppDatabase(NativeDatabase.memory());
