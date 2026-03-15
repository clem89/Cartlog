import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/item_category.dart';

class ItemListTile extends StatelessWidget {
  final ItemTableData item;
  final VoidCallback onDeleted;

  const ItemListTile({super.key, required this.item, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final quantityText = item.unit != null
        ? '${_formatQuantity(item.quantity)}${item.unit}'
        : _formatQuantity(item.quantity);

    return ListTile(
      leading: item.category != null
          ? CircleAvatar(
              backgroundColor: ItemCategory.fromLabel(item.category!).color.withValues(alpha: 0.2),
              child: Text(
                item.category![0],
                style: TextStyle(
                  color: ItemCategory.fromLabel(item.category!).color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.shopping_basket, size: 16, color: Colors.white),
            ),
      title: Text(item.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.store != null)
            Text(item.store!, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          if (item.memo != null)
            Text(item.memo!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${_formatPrice(item.price)}원',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(quantityText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      onLongPress: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('품목 삭제'),
            content: Text('${item.name}을(를) 삭제할까요?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
            ],
          ),
        );
        if (confirm == true) onDeleted();
      },
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String _formatQuantity(double qty) {
    return qty == qty.truncateToDouble() ? qty.toInt().toString() : qty.toString();
  }
}
