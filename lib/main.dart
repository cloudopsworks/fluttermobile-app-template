import 'package:flutter/material.dart';
import 'theme/jetsnack_theme.dart';
import 'models/snack.dart';
import 'screens/home_screen.dart';
import 'screens/cart_screen.dart';

void main() {
  runApp(const JetSnackApp());
}

class JetSnackApp extends StatelessWidget {
  const JetSnackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JetSnack',
      theme: jetsnackTheme,
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final List<CartItem> _cart = [];

  void _addToCart(Snack snack) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.snack.id == snack.id);
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(snack: snack));
      }
    });
  }

  void _removeFromCart(Snack snack) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.snack.id == snack.id);
      if (existingIndex >= 0) {
        if (_cart[existingIndex].quantity > 1) {
          _cart[existingIndex].quantity--;
        } else {
          _cart.removeAt(existingIndex);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(cart: _cart, onAddToCart: _addToCart),
      CartScreen(cart: _cart, onRemoveFromCart: _removeFromCart),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: JetsnackColors.primary,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(_cart.length.toString()),
              isLabelVisible: _cart.isNotEmpty,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: Badge(
              label: Text(_cart.length.toString()),
              isLabelVisible: _cart.isNotEmpty,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}
