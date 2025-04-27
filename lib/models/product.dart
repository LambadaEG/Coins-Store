class Product {
  final String id;
  final String name;
  final double price;
  final List<String> images;
  final String country;
  final int year;
  final double value;
  final String sellerId;  // Changed from seller email to seller ID
  final String sellerName;
  final String sellerPhone;
  final String sellerEmail;
  final int inStock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.country,
    required this.year,
    required this.value,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.sellerEmail,
    required this.inStock,
  });

  String get formattedPrice {
    return price == price.toInt().toDouble()
        ? 'EGP ${price.toInt()}'
        : 'EGP ${price.toStringAsFixed(2)}';
  }
}