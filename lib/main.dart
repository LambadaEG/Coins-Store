import 'package:flutter/material.dart';
import 'screens/request_coin_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/product_catalog_screen.dart';
import 'models/product.dart';
void main() {
  runApp(MyApp());
}


class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Product> products = [
    Product(
      name: '٥مليم حسين كامل',
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
      name: '١مليم فاروق',
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
      name: '١مليم فاروق',
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
      name: '٢مليم فؤاد',
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
  ];

  List<Product> cart = [];

  void addToCart(Product product) {
    if (product.inStock > 0) {
      setState(() {
        cart.add(product);
      });
    }
  }

  void removeFromCart(Product product) {
    setState(() {
      cart.remove(product);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coin Catalog',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => ProductCatalogScreen(
              products: products,
              cart: cart,
              addToCart: addToCart,
            ),
        '/cart': (context) => CartScreen(cart: cart, removeFromCart: removeFromCart),
        '/request': (context) => RequestCoinScreen(),
      },
    );
  }
}

