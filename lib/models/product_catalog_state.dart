import 'package:flutter/material.dart';
import 'product.dart';

class ProductCatalogState with ChangeNotifier {
  List<Product> products = [
    Product(
      name: '٥ مليم حسين كامل',
      price: 90,
      images: [
        'https://i.postimg.cc/NjDGyMn8/4.jpg',
        'https://i.postimg.cc/65spgFRZ/3.jpg',
      ],
      country: 'Egypt',
      year: 1916,
      value: 5,
      seller: 'Jimmy',
      inStock: 5,
    ),
    Product(
      name: '١ مليم فاروق',
      price: 65,
      images: [
        'https://i.postimg.cc/Z54KK3wK/6.jpg',
        'https://i.postimg.cc/HsQkg34h/5.jpg',
      ],
      country: 'Egypt',
      year: 1947,
      value: 1,
      seller: 'Jimmy',
      inStock: 3,
    ),
    Product(
      name: '١ مليم فاروق',
      price: 75,
      images: [
        'https://i.postimg.cc/CBfDXpX0/1.jpg',
        'https://i.postimg.cc/5yjmLZPn/2.jpg',
      ],
      country: 'Egypt',
      year: 1938,
      value: 1,
      seller: 'Jimmy',
      inStock: 10,
    ),
    Product(
      name: '٢ مليم فؤاد',
      price: 45,
      images: [
        'https://i.postimg.cc/15YJycmD/8.jpg',
        'https://i.postimg.cc/59gsRWD7/7.jpg',
      ],
      country: 'Egypt',
      year: 1929,
      value: 2,
      seller: 'Jimmy',
      inStock: 2,
    ),
    Product(
      name: '١٠ سنت',
      price: 15,
      images: [
        'https://i.postimg.cc/261CKNxP/9.jpg',
        'https://i.postimg.cc/Px0dGV3N/10.jpg',
      ],
      country: 'Zimbabwe',
      year: 1987,
      value: 10,
      seller: 'Jimmy',
      inStock: 2,
    ),
  ];

  List<Product> cart = [];

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
}