import 'package:drift/drift.dart';

class ShoppingSessionTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get storeName => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get memo => text().nullable()();
}
