import '../../domain/models/item_category.dart';

class ParsedReceiptItem {
  final String name;
  final int? price;
  final bool selected;
  final ItemCategory? category;

  const ParsedReceiptItem({
    required this.name,
    this.price,
    this.selected = true,
    this.category,
  });

  ParsedReceiptItem copyWith({
    String? name,
    int? price,
    bool? selected,
    ItemCategory? category,
    bool clearCategory = false,
  }) {
    return ParsedReceiptItem(
      name: name ?? this.name,
      price: price ?? this.price,
      selected: selected ?? this.selected,
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}
