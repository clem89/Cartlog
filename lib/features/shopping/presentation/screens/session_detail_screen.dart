import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/shopping_provider.dart';
import '../widgets/item_list_tile.dart';
import 'add_item_screen.dart';

class SessionDetailScreen extends ConsumerWidget {
  final ShoppingSessionTableData session;

  const SessionDetailScreen({super.key, required this.session});

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider(session.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(session.storeName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (items) {
          final totalPrice = items.fold(0, (sum, i) => sum + i.price);

          return Column(
            children: [
              // ── 세션 정보 ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(session.date),
                        style: const TextStyle(color: Colors.grey)),
                    if (session.memo != null && session.memo!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(session.memo!,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '총 ${_formatPrice(totalPrice)}원 · ${items.length}개 품목',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),

              // ── 품목 목록 ──────────────────────────
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('품목이 없습니다',
                                style: TextStyle(color: Colors.grey)),
                            SizedBox(height: 4),
                            Text('+ 버튼을 눌러 추가해보세요',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ItemListTile(
                            item: item,
                            onDeleted: () => ref
                                .read(shoppingRepositoryProvider)
                                .deleteItem(item.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddItemScreen(sessionId: session.id),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
