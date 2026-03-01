import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor createInMemoryExecutor() =>
    WasmDatabase(sqlite3Uri: Uri.parse('sqlite3.wasm'), databaseName: 'bsharp');
