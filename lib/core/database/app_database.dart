import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/shopping/data/models/item_table.dart';
import '../../features/shopping/data/models/shopping_session_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [ShoppingSessionTable, ItemTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement('ALTER TABLE item_table ADD COLUMN memo TEXT');
          }
          if (from < 3) {
            await customStatement('ALTER TABLE item_table ADD COLUMN store TEXT');
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cartlog.db'));
    return NativeDatabase.createInBackground(file);
  });
}
