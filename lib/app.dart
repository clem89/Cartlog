import 'package:flutter/material.dart';

import 'features/shopping/presentation/screens/home_screen.dart';

class CartlogApp extends StatelessWidget {
  const CartlogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cartlog',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const HomeScreen(),
    );
  }
}
