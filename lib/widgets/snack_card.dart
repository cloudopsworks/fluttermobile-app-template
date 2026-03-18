import 'package:flutter/material.dart';
import '../models/snack.dart';
import '../theme/jetsnack_theme.dart';

class SnackCard extends StatelessWidget {
  final Snack snack;
  final VoidCallback onTap;

  const SnackCard({
    super.key,
    required this.snack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                snack.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snack.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snack.tagline,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: JetsnackColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${(snack.price / 100).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: JetsnackColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
