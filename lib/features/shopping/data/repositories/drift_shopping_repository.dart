import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/repositories/shopping_repository.dart';

class DriftShoppingRepository implements ShoppingRepository {
  final AppDatabase _db;

  DriftShoppingRepository(this._db);

  // ── ShoppingSession ──────────────────────────────────────

  @override
  Future<List<ShoppingSessionTableData>> getSessions() =>
      (_db.select(_db.shoppingSessionTable)
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  @override
  Stream<List<ShoppingSessionTableData>> watchSessions() =>
      (_db.select(_db.shoppingSessionTable)
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  @override
  Future<int> insertSession(ShoppingSessionTableCompanion session) =>
      _db.into(_db.shoppingSessionTable).insert(session);

  @override
  Future<void> updateSession(ShoppingSessionTableData session) =>
      _db.update(_db.shoppingSessionTable).replace(session);

  @override
  Future<void> deleteSession(int id) =>
      (_db.delete(_db.shoppingSessionTable)
            ..where((t) => t.id.equals(id)))
          .go();

  // ── Item ─────────────────────────────────────────────────

  @override
  Future<List<ItemTableData>> getItemsBySession(int sessionId) =>
      (_db.select(_db.itemTable)
            ..where((t) => t.sessionId.equals(sessionId)))
          .get();

  @override
  Stream<List<ItemTableData>> watchItemsBySession(int sessionId) =>
      (_db.select(_db.itemTable)
            ..where((t) => t.sessionId.equals(sessionId)))
          .watch();

  @override
  Future<int> insertItem(ItemTableCompanion item) =>
      _db.into(_db.itemTable).insert(item);

  @override
  Future<void> updateItem(ItemTableData item) =>
      _db.update(_db.itemTable).replace(item);

  @override
  Future<void> deleteItem(int id) =>
      (_db.delete(_db.itemTable)..where((t) => t.id.equals(id))).go();
}
