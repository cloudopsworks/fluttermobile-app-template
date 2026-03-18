
class Snack {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String tagline;
  final String description;

  const Snack({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.tagline,
    this.description = "A delicious snack for any occasion. Made with the finest ingredients to satisfy your cravings.",
  });
}

final List<Snack> snacks = [
  const Snack(
    id: '1',
    name: 'Cupcake',
    tagline: 'Sweet and fluffy',
    imageUrl: 'https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?auto=format&fit=crop&w=400&q=80',
    price: 299,
  ),
  const Snack(
    id: '2',
    name: 'Donut',
    tagline: 'Glazed perfection',
    imageUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?auto=format&fit=crop&w=400&q=80',
    price: 150,
  ),
  const Snack(
    id: '3',
    name: 'Eclair',
    tagline: 'Creamy delight',
    imageUrl: 'https://images.unsplash.com/photo-1558326567-98ae2405596b?auto=format&fit=crop&w=400&q=80',
    price: 350,
  ),
  const Snack(
    id: '4',
    name: 'Froyo',
    tagline: 'Chilled goodness',
    imageUrl: 'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?auto=format&fit=crop&w=400&q=80',
    price: 400,
  ),
  const Snack(
    id: '5',
    name: 'Gingerbread',
    tagline: 'Spicy and snappy',
    imageUrl: 'https://images.unsplash.com/photo-1559181567-c3190ca9959b?auto=format&fit=crop&w=400&q=80',
    price: 250,
  ),
  const Snack(
    id: '6',
    name: 'Honeycomb',
    tagline: 'Golden crunch',
    imageUrl: 'https://images.unsplash.com/photo-1581447100344-77373f44a9e5?auto=format&fit=crop&w=400&q=80',
    price: 450,
  ),
];

class CartItem {
  final Snack snack;
  int quantity;

  CartItem({required this.snack, this.quantity = 1});
}
