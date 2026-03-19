import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/item_category.dart';
import '../providers/shopping_provider.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  final ItemTableData? initialItem;
  final ShoppingSessionTableData? initialSession;

  const AddItemScreen({super.key, this.initialItem, this.initialSession});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitController = TextEditingController();
  final _storeController = TextEditingController();
  final _memoController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  ItemCategory? _selectedCategory;
  String? _customCategoryLabel;
  ItemCategory? _historyFilter;
  bool _isSaving = false;

  String? get _effectiveCategory => _customCategoryLabel ?? _selectedCategory?.label;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    final session = widget.initialSession;
    if (item != null) {
      _nameController.text = item.name;
      _priceController.text = item.price.toString();
      _quantityController.text = item.quantity == item.quantity.truncateToDouble()
          ? item.quantity.toInt().toString()
          : item.quantity.toString();
      _unitController.text = item.unit ?? '';
      _storeController.text = item.store ?? session?.storeName ?? '';
      _memoController.text = item.memo ?? '';
      _selectedDate = session?.date ?? DateTime.now();
      if (item.category != null) {
        final predefined = ItemCategory.fromLabel(item.category!);
        if (predefined != null) {
          _selectedCategory = predefined;
        } else {
          _customCategoryLabel = item.category;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _storeController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // 이전 항목 탭 → 이름 + 카테고리 채움
  void _fillNameFromHistory(ItemTableData item) {
    setState(() {
      _nameController.text = item.name;
      if (item.category != null) {
        final predefined = ItemCategory.fromLabel(item.category!);
        if (predefined != null) {
          _selectedCategory = predefined;
          _customCategoryLabel = null;
        } else {
          _selectedCategory = null;
          _customCategoryLabel = item.category;
        }
      }
    });
  }

  Future<void> _showCustomCategoryDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('카테고리 직접 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '카테고리명 입력'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedCategory = null;
        _customCategoryLabel = result;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final store = _storeController.text.trim();
    final sessionId = await ref
        .read(shoppingRepositoryProvider)
        .findOrCreateSession(_selectedDate, store.isEmpty ? '미입력' : store);

    final repo = ref.read(shoppingRepositoryProvider);
    final name = _nameController.text.trim();
    final price = int.parse(_priceController.text.trim());
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final unit = _unitController.text.trim().isEmpty ? null : _unitController.text.trim();
    final storeVal = _storeController.text.trim().isEmpty ? null : _storeController.text.trim();
    final memo = _memoController.text.trim().isEmpty ? null : _memoController.text.trim();

    if (widget.initialItem != null) {
      await repo.updateItem(ItemTableData(
        id: widget.initialItem!.id,
        sessionId: sessionId,
        name: name,
        price: price,
        quantity: quantity,
        unit: unit,
        category: _effectiveCategory,
        store: storeVal,
        memo: memo,
      ));
    } else {
      await repo.insertItem(ItemTableCompanion.insert(
        sessionId: sessionId,
        name: name,
        price: price,
        quantity: Value(quantity),
        unit: Value(unit),
        category: Value(_effectiveCategory),
        store: Value(storeVal),
        memo: Value(memo),
      ));
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(itemHistoryProvider);
    final storeHistoryAsync = ref.watch(storeHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialItem != null ? '품목 수정' : '품목 추가'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 날짜 ────────────────────────────────
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '날짜',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(
                  '${_selectedDate.year}-'
                  '${_selectedDate.month.toString().padLeft(2, '0')}-'
                  '${_selectedDate.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── 품목명 ──────────────────────────────
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '품목명 *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '품목명을 입력해주세요' : null,
            ),
            const SizedBox(height: 12),

            // ── 가격 ────────────────────────────────
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: '가격 *',
                suffixText: '원',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '가격을 입력해주세요' : null,
            ),
            const SizedBox(height: 12),

            // ── 수량 + 단위 ─────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: '수량',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: '단위 (선택)',
                      hintText: '개, g, kg, ml...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── 카테고리 ────────────────────────────
            const Text('카테고리',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ...ItemCategory.values.map((cat) {
                  final selected = _selectedCategory == cat && _customCategoryLabel == null;
                  return ChoiceChip(
                    label: Text(cat.label),
                    selected: selected,
                    selectedColor: cat.color.withValues(alpha: 0.3),
                    onSelected: (_) => setState(() {
                      _customCategoryLabel = null;
                      _selectedCategory = selected ? null : cat;
                    }),
                  );
                }),
                if (_customCategoryLabel != null)
                  ChoiceChip(
                    label: Text(_customCategoryLabel!),
                    selected: true,
                    selectedColor: Colors.teal.withValues(alpha: 0.3),
                    onSelected: (_) => setState(() => _customCategoryLabel = null),
                  ),
                ActionChip(
                  label: const Text('+ 직접 입력'),
                  onPressed: _showCustomCategoryDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── 구입처 ──────────────────────────────
            TextFormField(
              controller: _storeController,
              decoration: const InputDecoration(
                labelText: '구입처 (선택)',
                hintText: '예) 이마트, 쿠팡',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            storeHistoryAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stores) {
                if (stores.isEmpty) return const SizedBox.shrink();
                return Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: stores.map((store) {
                    return GestureDetector(
                      onTap: () => _storeController.text = store,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.1),
                          border: Border.all(
                              color: Colors.blueGrey.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(store,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.blueGrey)),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),

            // ── 메모 ────────────────────────────────
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
                hintText: '예) 1+1 행사, 냉동 말고 신선',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // ── 이전 구매 품목 ──────────────────────
            historyAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (allItems) {
                if (allItems.isEmpty) return const SizedBox.shrink();

                final seen = <String>{};
                final unique =
                    allItems.where((i) => seen.add(i.name)).toList();

                final filtered = _historyFilter == null
                    ? unique
                    : unique
                        .where((i) => i.category == _historyFilter!.label)
                        .toList();

                final existingCategories = ItemCategory.values
                    .where((cat) =>
                        unique.any((i) => i.category == cat.label))
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('이전 구매 품목',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: '전체',
                                  color: Colors.blueGrey,
                                  selected: _historyFilter == null,
                                  onTap: () =>
                                      setState(() => _historyFilter = null),
                                ),
                                ...existingCategories.map((cat) => _FilterChip(
                                      label: cat.label,
                                      color: cat.color,
                                      selected: _historyFilter == cat,
                                      onTap: () => setState(() {
                                        _historyFilter =
                                            _historyFilter == cat ? null : cat;
                                      }),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (filtered.isEmpty)
                      const Text('해당 카테고리 품목이 없습니다.',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 12))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: filtered.map((item) {
                          final cat = item.category != null
                              ? ItemCategory.fromLabel(item.category!)
                              : null;
                          final color = cat?.color ?? Colors.grey;
                          return GestureDetector(
                            onTap: () => _fillNameFromHistory(item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                border: Border.all(
                                    color: color.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),

            // ── 저장 버튼 ───────────────────────────
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
