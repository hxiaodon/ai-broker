import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

/// Drift database definition — currently empty, tables will be added
/// per feature as they are implemented (orders cache, quote snapshots, etc.).
///
/// Run `dart run build_runner build` to regenerate `database.g.dart`.
@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'trading_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
