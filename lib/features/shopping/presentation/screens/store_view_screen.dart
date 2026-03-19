import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shopping_provider.dart';
import 'store_detail_screen.dart';

class StoreViewScreen extends ConsumerStatefulWidget {
  const StoreViewScreen({super.key});

  @override
  ConsumerState<StoreViewScreen> createState() => _StoreViewScreenState();
}

class _StoreViewScreenState extends ConsumerState<StoreViewScreen> {
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
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: _isSearching
            ? TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '마트 이름 검색...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : const Text('마트별 보기'),
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
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Text('기록이 없습니다', style: TextStyle(color: Colors.grey)),
            );
          }

          final Map<String, int> storeCount = {};
          for (final s in sessions) {
            storeCount[s.storeName] = (storeCount[s.storeName] ?? 0) + 1;
          }

          final storeNames = storeCount.keys
              .where((name) => name.contains(_query))
              .toList();

          if (storeNames.isEmpty) {
            return const Center(
              child: Text('검색 결과 없음', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: storeNames.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final store = storeNames[index];
              final count = storeCount[store]!;
              return Card(
                child: ListTile(
                  title: Text(
                    store,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$count회 방문'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoreDetailScreen(storeName: store),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
