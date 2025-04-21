class Product {
  final String name;
  final double price;
  final List<String> images;
  final String country;
  final int year;
  final double value;
  final String seller;
  final int inStock;

  Product({
    required this.name,
    required this.price,
    required this.images,
    required this.country,
    required this.year,
    required this.value,
    required this.seller,
    required this.inStock,
  });

  String get formattedPrice {
    return price == price.toInt().toDouble()
        ? 'EGP ${price.toInt()}'
        : 'EGP ${price.toStringAsFixed(2)}';
  }
}
