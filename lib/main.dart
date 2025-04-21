import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class Product {
  final String name;
  final double price;
  final String image;
  final String country;
  final int year;
  final double value;  
  final String seller;

  Product({
    required this.name,
    required this.price,
    required this.image,
    required this.country,
    required this.year,
    required this.value,  // Added to constructor
    required this.seller,
  });

    String get formattedPrice {
    return price == price.toInt().toDouble() 
        ? 'EGP ${price.toInt()}' 
        : 'EGP ${price.toStringAsFixed(2)}';
  }
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Product> products = [
    Product(
      name: 'Egyptian Coin',
      price: 8000,
      image: 'https://i.imgur.com/Vms4QE0.jpeg',
      country: 'Egypt',
      year: 1980,
      value: 10,
      seller: 'Jimmy',
    ),
    Product(
      name: 'USA Coin',
      price: 4000,
      image: 'https://i.imgur.com/b24RFio.jpeg',
      country: 'USA',
      year: 1923,
      value: 10,
      seller: 'Jimmy',
    ),
    Product(
      name: '١مليم فاروق',
      price: 75,
      image: 'https://i.postimg.cc/CBfDXpX0/1.jpg',
      country: 'Egypt',
      year: 1938,
      value: 10,
      seller: 'Jimmy',
    ),
    Product(
      name: 'Italy Coin',
      price: 2000,
      image: 'https://i.imgur.com/Vms4QE0.jpeg',
      country: 'Italy',
      year: 1902,
            value: 10,
      seller: 'Jimmy',
    ),
  ];

  List<Product> cart = [];

  void addToCart(Product product) {
    setState(() {
      cart.add(product);
    });
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
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => ProductCatalogScreen(
              products: products,
              cart: cart,
              addToCart: addToCart,
            ),
        '/cart': (context) => CartScreen(
              cart: cart,
              removeFromCart: removeFromCart,
            ),
        '/request': (context) => RequestCoinScreen(),
      },
    );
  }
}

class ProductCatalogScreen extends StatelessWidget {
  final List<Product> products;
  final List<Product> cart;
  final Function(Product) addToCart;

  ProductCatalogScreen({
    required this.products,
    required this.cart,
    required this.addToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coin Catalog'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.shopping_cart),
                if (cart.isNotEmpty)
                  Positioned(
                    right: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '${cart.length}',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                Product p = products[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        p.image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.monetization_on, size: 60),
                      ),
                    ),
                    title: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text('EGP ${p.price.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.green)),
                        SizedBox(height: 2),
                        Text('${p.country}, ${p.year}',
                            style: TextStyle(fontSize: 12)),
                        Text('Seller: ${p.seller}'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => addToCart(p),
                      child: Text('Add to Cart',style: TextStyle(color: Colors.white),),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add_circle_outline),
              label: Text('Request Unlisted Coin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pushNamed(context, '/request'),
            ),
          ),
        ],
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  final List<Product> cart;
  final Function(Product) removeFromCart;

  const CartScreen({
    required this.cart,
    required this.removeFromCart,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double total = cart.fold(0, (sum, item) => sum + item.price);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final p = cart[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              p.image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.monetization_on, size: 50),
                            ),
                          ),
                          title: Text(p.name),
                          subtitle: Text('EGP ${p.price.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => removeFromCart(p),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'EGP ${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      // Checkout logic would go here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Proceeding to checkout...')),
                      );
                    },
                    child: const Text('Checkout', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
    );
  }
}

class RequestCoinScreen extends StatefulWidget {
  @override
  _RequestCoinScreenState createState() => _RequestCoinScreenState();
}

class _RequestCoinScreenState extends State<RequestCoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();
  final _valueController = TextEditingController();
  final _yearController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _countryController.dispose();
    _valueController.dispose();
    _yearController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Coin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Can\'t find your coin? Request it here!',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country of Origin',
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the country';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Value (EGP)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the estimated value';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Year of Minting',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the year';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Your Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Here you would typically send the request to your backend
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Request submitted successfully!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Submit Request', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}