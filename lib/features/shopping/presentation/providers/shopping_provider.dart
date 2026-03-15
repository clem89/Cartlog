import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/repositories/drift_shopping_repository.dart';
import '../../domain/repositories/shopping_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return DriftShoppingRepository(ref.watch(appDatabaseProvider));
});

final sessionsProvider = StreamProvider<List<ShoppingSessionTableData>>((ref) {
  return ref.watch(shoppingRepositoryProvider).watchSessions();
});

final itemsProvider =
    StreamProvider.family<List<ItemTableData>, int>((ref, sessionId) {
  return ref.watch(shoppingRepositoryProvider).watchItemsBySession(sessionId);
});

final itemHistoryProvider = StreamProvider<List<ItemTableData>>((ref) {
  return ref.watch(shoppingRepositoryProvider).watchAllItems();
});

final storeHistoryProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(shoppingRepositoryProvider).watchStoreHistory();
});
