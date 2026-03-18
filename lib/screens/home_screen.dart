import 'package:flutter/material.dart';
import '../models/snack.dart';
import '../widgets/snack_card.dart';
import 'snack_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<CartItem> cart;
  final Function(Snack) onAddToCart;

  const HomeScreen({
    super.key,
    required this.cart,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JetSnack'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Snacks for you',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final snack = snacks[index];
                  return SnackCard(
                    snack: snack,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SnackDetailScreen(
                            snack: snack,
                            onAddToCart: onAddToCart,
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: snacks.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
