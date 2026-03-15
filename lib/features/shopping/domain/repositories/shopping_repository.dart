import '../../../../core/database/app_database.dart';

abstract class ShoppingRepository {
  // ShoppingSession
  Future<List<ShoppingSessionTableData>> getSessions();
  Stream<List<ShoppingSessionTableData>> watchSessions();
  Future<int> insertSession(ShoppingSessionTableCompanion session);
  Future<void> updateSession(ShoppingSessionTableData session);
  Future<void> deleteSession(int id);

  // Item
  Future<List<ItemTableData>> getAllItems();
  Stream<List<ItemTableData>> watchAllItems();
  Stream<List<String>> watchStoreHistory();
  Future<List<String>> getStoreHistory();
  Future<List<ItemTableData>> getItemsBySession(int sessionId);
  Stream<List<ItemTableData>> watchItemsBySession(int sessionId);
  Future<int> insertItem(ItemTableCompanion item);
  Future<void> updateItem(ItemTableData item);
  Future<void> deleteItem(int id);
}
