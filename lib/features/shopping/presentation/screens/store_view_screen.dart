import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/shopping_provider.dart';

class StoreViewScreen extends ConsumerWidget {
  const StoreViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('마트별 보기'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Text('기록이 없습니다', style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sessions.length,
            itemBuilder: (context, index) =>
                _SessionGroup(session: sessions[index]),
          );
        },
      ),
    );
  }
}

class _SessionGroup extends ConsumerWidget {
  final ShoppingSessionTableData session;

  const _SessionGroup({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider(session.id));
    final d = session.date;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$dateStr · ${session.storeName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Divider(height: 16),
            itemsAsync.when(
              loading: () => const SizedBox(
                height: 24,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text('오류: $e'),
              data: (items) {
                if (items.isEmpty) {
                  return const Text('품목 없음',
                      style: TextStyle(color: Colors.grey, fontSize: 13));
                }
                final total = items.fold<int>(
                    0, (sum, i) => sum + (i.price * i.quantity).round());
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(child: Text(item.name)),
                              Text(
                                '${_fmtPrice(item.price)}원'
                                ' / ${_quantityStr(item)}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${items.length}개 품목',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                        Text(
                          '총 ${_fmtPrice(total)}원',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _fmtPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _quantityStr(ItemTableData item) {
    final qty = item.quantity == item.quantity.truncateToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toString();
    return item.unit != null ? '$qty${item.unit}' : qty;
  }
}
