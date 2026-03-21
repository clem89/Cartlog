class ParsedReceiptItem {
  final String name;
  final int? price;
  final bool selected;

  const ParsedReceiptItem({
    required this.name,
    this.price,
    this.selected = true,
  });

  ParsedReceiptItem copyWith({
    String? name,
    int? price,
    bool? selected,
  }) {
    return ParsedReceiptItem(
      name: name ?? this.name,
      price: price ?? this.price,
      selected: selected ?? this.selected,
    );
  }
}
