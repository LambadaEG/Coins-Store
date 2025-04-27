import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';

class ProductCatalogState with ChangeNotifier {
  List<Product> products = [];
  List<Product> cart = [];
  bool isLoading = false;
  String? error;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchProducts() async {
    try {
      isLoading = true;
      notifyListeners();

      final snapshot = await _firestore.collection('products').get();
      
      products = snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          name: data['name']?.toString() ?? 'Unnamed Product',
          price: _safeParseDouble(data['price']),
          images: List<String>.from(data['images'] ?? []),
          country: data['country']?.toString() ?? 'Unknown',
          year: _safeParseInt(data['year']),
          value: _safeParseDouble(data['value']),
          sellerId: data['sellerId'] as String? ?? '',
          sellerName: data['sellerName']?.toString() ?? 'Unknown',
          sellerPhone: data['sellerPhone']?.toString() ?? 'Unknown',
          sellerEmail: data['sellerEmail']?.toString() ?? 'Unknown',
          inStock: _safeParseInt(data['inStock']),
        );
      }).toList();

      error = null;
    } catch (e) {
      error = 'Failed to load products: ${e.toString()}';
      debugPrint(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void addToCart(Product product) {
    if (product.inStock > 0) {
      cart.add(product);
      notifyListeners();
    }
  }

  void removeFromCart(Product product) {
    cart.remove(product);
      notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }
}