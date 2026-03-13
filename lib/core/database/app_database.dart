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
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cartlog.db'));
    return NativeDatabase.createInBackground(file);
  });
}
