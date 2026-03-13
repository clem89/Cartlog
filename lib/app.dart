import 'package:flutter/material.dart';

class CartlogApp extends StatelessWidget {
  const CartlogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cartlog',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const Scaffold(
        body: Center(child: Text('Cartlog')),
      ),
    );
  }
}
