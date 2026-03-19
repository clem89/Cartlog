import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/shopping_provider.dart';

class ItemViewScreen extends ConsumerStatefulWidget {
  const ItemViewScreen({super.key});

  @override
  ConsumerState<ItemViewScreen> createState() => _ItemViewScreenState();
}

class _ItemViewScreenState extends ConsumerState<ItemViewScreen> {
  bool _isSearching = false;
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _query = '';
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemHistoryProvider);
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: _isSearching
            ? TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '품목 이름 검색...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : const Text('품목별 보기'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
            ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('기록이 없습니다', style: TextStyle(color: Colors.grey)),
            );
          }

          final sessionMap = sessionsAsync.valueOrNull != null
              ? {for (final s in sessionsAsync.valueOrNull!) s.id: s}
              : <int, ShoppingSessionTableData>{};

          final Map<String, List<ItemTableData>> grouped = {};
          for (final item in items) {
            grouped.putIfAbsent(item.name, () => []).add(item);
          }

          final names = grouped.keys
              .where((name) => name.contains(_query))
              .toList();

          if (names.isEmpty) {
            return const Center(
              child: Text('검색 결과 없음', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: names.length,
            itemBuilder: (context, index) {
              final name = names[index];
              final entries = grouped[name]!;
              return _ItemGroup(
                name: name,
                entries: entries,
                sessionMap: sessionMap,
              );
            },
          );
        },
      ),
    );
  }
}

class _ItemGroup extends StatelessWidget {
  final String name;
  final List<ItemTableData> entries;
  final Map<int, ShoppingSessionTableData> sessionMap;

  const _ItemGroup({
    required this.name,
    required this.entries,
    required this.sessionMap,
  });

  String _fmtPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _quantityStr(ItemTableData item) {
    final qty = item.quantity == item.quantity.truncateToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toString();
    return item.unit != null ? '$qty${item.unit}' : qty;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Divider(height: 14),
            ...entries.map((item) {
              final session = sessionMap[item.sessionId];
              final storePart = item.store ?? session?.storeName ?? '구입처 미상';
              final datePart =
                  session != null ? _fmtDate(session.date) : '-';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$storePart · $datePart',
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 13),
                      ),
                    ),
                    Text('${_quantityStr(item)} · ${_fmtPrice(item.price)}원'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
