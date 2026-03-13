import 'package:drift/drift.dart';

import 'shopping_session_table.dart';

class ItemTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(ShoppingSessionTable, #id)();
  TextColumn get name => text()();
  IntColumn get price => integer()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().nullable()();
  TextColumn get category => text().nullable()();
}
