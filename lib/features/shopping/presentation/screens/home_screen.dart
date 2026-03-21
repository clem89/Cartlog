import 'package:flutter/material.dart';

import 'add_item_screen.dart';
import 'item_view_screen.dart';
import 'receipt_scan_screen.dart';
import 'store_view_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartlog'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HomeButton(
                icon: Icons.store_outlined,
                label: '마트별 보기',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StoreViewScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _HomeButton(
                icon: Icons.inventory_2_outlined,
                label: '품목별 보기',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ItemViewScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _HomeButton(
                icon: Icons.add_circle_outline,
                label: '품목 추가하기',
                isPrimary: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddItemScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _HomeButton(
                icon: Icons.receipt_long_outlined,
                label: '영수증 등록',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReceiptScanScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: isPrimary
            ? colorScheme.primaryContainer
            : colorScheme.secondaryContainer,
        foregroundColor: isPrimary
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSecondaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
