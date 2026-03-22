import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/item_category.dart';
import '../../domain/models/parsed_receipt_item.dart';
import '../providers/shopping_provider.dart';

class ReceiptReviewScreen extends ConsumerStatefulWidget {
  final List<ParsedReceiptItem> parsedItems;

  const ReceiptReviewScreen({super.key, required this.parsedItems});

  @override
  ConsumerState<ReceiptReviewScreen> createState() =>
      _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  late List<ParsedReceiptItem> _items;
  final _storeController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.parsedItems);
  }

  @override
  void dispose() {
    _storeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _editItem(int index) {
    final item = _items[index];
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl =
        TextEditingController(text: item.price?.toString() ?? '');
    ItemCategory? selectedCategory = item.category;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('품목 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '품목명'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: '가격 (원)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ItemCategory?>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: '카테고리'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('미분류')),
                  ...ItemCategory.values.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                  ),
                ],
                onChanged: (v) => setDialogState(() => selectedCategory = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _items[index] = ParsedReceiptItem(
                    name: nameCtrl.text.trim().isEmpty ? item.name : nameCtrl.text.trim(),
                    price: int.tryParse(priceCtrl.text) ?? item.price,
                    selected: item.selected,
                    category: selectedCategory,
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final storeName = _storeController.text.trim();
    if (storeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마트/구입처를 입력해주세요.')),
      );
      return;
    }

    final selectedItems = _items.where((i) => i.selected).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 품목을 하나 이상 선택해주세요.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(shoppingRepositoryProvider);
      final sessionId = await repo.findOrCreateSession(_date, storeName);

      for (final item in selectedItems) {
        await repo.insertItem(
          ItemTableCompanion(
            sessionId: Value(sessionId),
            name: Value(item.name),
            price: Value(item.price ?? 0),
            store: Value(storeName),
            category: Value(item.category?.label),
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context)
        ..pop() // ReceiptReviewScreen
        ..pop(); // ReceiptScanScreen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedItems.length}개 품목이 저장되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _items.where((i) => i.selected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('인식 결과 확인'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                '저장 ($selectedCount)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 마트명 + 날짜 입력
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _storeController,
                    decoration: const InputDecoration(
                      labelText: '마트 / 구입처',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(
                    '${_date.year}.${_date.month.toString().padLeft(2, '0')}.${_date.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 전체 선택/해제 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Checkbox(
                  value: selectedCount == _items.length
                      ? true
                      : selectedCount == 0
                          ? false
                          : null,
                  tristate: true,
                  onChanged: (v) {
                    setState(() {
                      final selectAll = v ?? true;
                      _items = _items
                          .map((i) => i.copyWith(selected: selectAll))
                          .toList();
                    });
                  },
                ),
                Text(
                  '전체 ${_items.length}개 중 $selectedCount개 선택',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 품목 목록
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: Checkbox(
                    value: item.selected,
                    onChanged: (v) => setState(() {
                      _items[index] = item.copyWith(selected: v ?? false);
                    }),
                  ),
                  title: Text(item.name),
                  subtitle: Row(
                    children: [
                      if (item.category != null)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.category!.color.withAlpha(38),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category!.label,
                            style: TextStyle(fontSize: 11, color: item.category!.color),
                          ),
                        ),
                      item.price != null
                          ? Text('${_formatPrice(item.price!)}원')
                          : const Text('가격 미인식', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editItem(index),
                        tooltip: '수정',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => setState(() => _items.removeAt(index)),
                        tooltip: '삭제',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

