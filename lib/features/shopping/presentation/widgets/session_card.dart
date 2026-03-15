import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

class SessionCard extends StatelessWidget {
  final ShoppingSessionTableData session;
  final VoidCallback onTap;

  const SessionCard({super.key, required this.session, required this.onTap});

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.shopping_cart_outlined),
        title: Text(
          session.storeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_formatDate(session.date)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
