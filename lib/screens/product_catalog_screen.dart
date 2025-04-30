import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_1/models/product.dart';
import 'package:project_1/models/product_catalog_state.dart';
import 'package:project_1/services/auth_service.dart';
import 'package:project_1/screens/profile_screen.dart';
import 'package:project_1/screens/notification_screen.dart';
import 'package:project_1/screens/login_screen.dart'; // Make sure to import your login screen

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({Key? key}) : super(key: key);

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final Map<int, int> _currentPageIndexes = {};
  final Map<int, PageController> _pageControllers = {};
  String _selectedCountry = 'Any';
  String _selectedYear = 'Any';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProducts();
    });
  }

  @override
  void dispose() {
    _pageControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    await Provider.of<ProductCatalogState>(
      context,
      listen: false,
    ).fetchProducts();
  }

  bool _canAddToCart(Product product, List<Product> cart) {
    if (product.inStock <= 0) return false;
    final cartQuantity = cart.where((p) => p.id == product.id).length;
    return cartQuantity < product.inStock;
  }

  Widget _buildNotificationBadge(Stream<QuerySnapshot> stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return count > 0
            ? Positioned(
                right: 0,
                top: 0,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await authService.signOut();
      // Navigate to login screen and clear all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            email: '',
            errorMessage: '',
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = Provider.of<ProductCatalogState>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final products = catalogState.products;
    final cart = catalogState.cart;
    final userId = authService.currentUserId;

    if (catalogState.isLoading && products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('EG Coins')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (catalogState.error != null && products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('EG Coins')),
        body: Center(child: Text(catalogState.error!)),
      );
    }

    final countries = products.map((p) => p.country).toSet().toList()..sort();
    final years = products.map((p) => p.year.toString()).toSet().toList()
      ..sort((a, b) => int.parse(b).compareTo(int.parse(a)));
    countries.insert(0, 'Any');
    years.insert(0, 'Any');

    final filteredProducts = products.where((product) {
      final matchCountry = _selectedCountry == 'Any' || product.country == _selectedCountry;
      final matchYear = _selectedYear == 'Any' || product.year.toString() == _selectedYear;
      return matchCountry && matchYear;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EG Coins',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        leadingWidth: 100,
        leading: Row(
          children: [
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [const Icon(Icons.person)],
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              ),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications),
                  if (userId != null)
                    _buildNotificationBadge(
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('notifications')
                          .where('read', isEqualTo: false)
                          .snapshots(),
                    ),
                ],
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationsScreen()),
              ),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/sell'),
            tooltip: 'Sell Coin',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Sign Out',
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart),
                if (cart.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '${cart.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      items: countries
                          .map((country) => DropdownMenuItem(
                                value: country,
                                child: Text(country),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCountry = value!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Country'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedYear,
                      items: years
                          .map((year) => DropdownMenuItem(
                                value: year,
                                child: Text(year),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Year'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final crossAxisCount = screenWidth > 600
                      ? 4
                      : screenWidth > 400
                          ? 3
                          : 2;
                  final spacing = 10.0;
                  final totalSpacing = spacing * (crossAxisCount - 1);
                  final itemWidth = (screenWidth - totalSpacing - 20) / crossAxisCount;
                  final itemHeight = 330.0;
                  final aspectRatio = itemWidth / itemHeight;

                  return GridView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filteredProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: aspectRatio,
                    ),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      _currentPageIndexes[index] = _currentPageIndexes[index] ?? 0;
                      _pageControllers[index] = _pageControllers[index] ?? PageController();

                      final canAdd = _canAddToCart(product, cart);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Card(
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
                                                  cacheWidth: (itemWidth *
                                                          MediaQuery.of(context)
                                                              .devicePixelRatio)
                                                      .round(),
                                                  errorBuilder: (context, error, _) =>
                                                      const Icon(
                                                    Icons.monetization_on,
                                                    size: 60,
                                                  ),
                                                );
                                              },
                                            ),
                                            if (product.images.length > 1)
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: List.generate(
                                                  product.images.length,
                                                  (dotIndex) => GestureDetector(
                                                    onTap: () {
                                                      _pageControllers[index]!
                                                          .animateToPage(
                                                        dotIndex,
                                                        duration: const Duration(
                                                            milliseconds: 300),
                                                        curve: Curves.easeInOut,
                                                      );
                                                    },
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 2,
                                                        vertical: 6,
                                                      ),
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: _currentPageIndexes[
                                                                    index] ==
                                                                dotIndex
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      product.formattedPrice,
                                      style: const TextStyle(
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      '${product.country}, ${product.year}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Seller: ${product.sellerPhone}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Stock: ${product.inStock}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: product.inStock > 0
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 0),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  canAdd ? Colors.blue[800] : Colors.grey,
                              minimumSize: const Size(double.infinity, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: canAdd
                                ? () => catalogState.addToCart(product)
                                : null,
                            child: Text(
                              canAdd
                                  ? 'Add to Cart'
                                  : product.inStock > 0
                                      ? 'Max Reached'
                                      : 'Out of Stock',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                label: const Text(
                  'Request Unlisted Coin',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
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
      ),
    );
  }
}