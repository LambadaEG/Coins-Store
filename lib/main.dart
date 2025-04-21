import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

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

class ProductCatalogScreen extends StatefulWidget {
  final List<Product> products;
  final List<Product> cart;
  final Function(Product) addToCart;

  const ProductCatalogScreen({
    required this.products,
    required this.cart,
    required this.addToCart,
  });

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final Map<int, int> _currentPageIndexes = {};
  final Map<int, PageController> _pageControllers = {};

  @override
  void dispose() {
    _pageControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Catalog'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (widget.cart.isNotEmpty)
                  Positioned(
                    right: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '${widget.cart.length}',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
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
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: widget.products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.64,
              ),
              itemBuilder: (context, index) {
                final product = widget.products[index];
                _currentPageIndexes[index] = _currentPageIndexes[index] ?? 0;
                _pageControllers[index] = _pageControllers[index] ?? PageController();

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                PageView.builder(
                                  controller: _pageControllers[index]!,
                                  itemCount: product.images.length,
                                  onPageChanged: (page) {
                                    setState(() {
                                      _currentPageIndexes[index] = page;
                                    });
                                  },
                                  itemBuilder: (context, imageIndex) {
                                    return Image.network(
                                      product.images[imageIndex],
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, _) =>
                                          const Icon(Icons.monetization_on, size: 60),
                                    );
                                  },
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    product.images.length,
                                    (dotIndex) => GestureDetector(
                                      onTap: () {
                                        _pageControllers[index]!.animateToPage(
                                          dotIndex,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _currentPageIndexes[index] == dotIndex
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(product.formattedPrice, style: const TextStyle(color: Colors.green)),
                        Text('${product.country}, ${product.year}', style: const TextStyle(fontSize: 12)),
                        Text('Seller: ${product.seller}', style: const TextStyle(fontSize: 12)),
                        Text(
                          'Stock: ${product.inStock}',
                          style: TextStyle(
                            fontSize: 12,
                            color: product.inStock > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: product.inStock > 0 ? Colors.blue[800] : Colors.grey,
                            minimumSize: const Size(double.infinity, 35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: product.inStock > 0 ? () => widget.addToCart(product) : null,
                          child: Text(
                            product.inStock > 0 ? 'Add' : 'Out',
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Request Unlisted Coin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
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
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  '${cart.length} item${cart.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, 
                      size: 60, 
                      color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue Shopping'),
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
                      return Dismissible(
                        key: Key(p.name + index.toString()),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) => removeFromCart(p),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                p.images[0],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.monetization_on, size: 60),
                              ),
                            ),
                            title: Text(p.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EGP ${p.price.toStringAsFixed(2)}'),
                                  Text(
                                    'In Stock: ${p.inStock}',
                                    style: TextStyle(
                                      color: p.inStock > 0 
                                        ? Colors.green 
                                        : Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => removeFromCart(p),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'EGP ${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'EGP ${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      // Checkout logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Sending request to the buyer'),
                          action: SnackBarAction(
                            label: 'OK',
                            onPressed: () {},
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Proceed to Checkout',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
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
