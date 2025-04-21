import 'package:flutter/material.dart';
import 'package:project_1/models/product.dart';

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

  // State for selected filters
  String? selectedCountry;
  int? selectedYear;
  late List<Product> filteredProducts;

  @override
  void initState() {
    super.initState();
    filteredProducts = widget.products; // Initially show all products
  }

  // Filter products based on the selected country and year
  void filterProducts() {
    setState(() {
      filteredProducts = widget.products.where((product) {
        bool matchesCountry = selectedCountry == null || selectedCountry == 'Any' || product.country == selectedCountry;
        bool matchesYear = selectedYear == null || selectedYear == -1 || product.year == selectedYear;

        return matchesCountry && matchesYear;
      }).toList();
    });
  }

  @override
  void dispose() {
    _pageControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get all unique countries and years
    final countries = widget.products.map((product) => product.country).toSet().toList();
    final years = widget.products.map((product) => product.year).toSet().toList();

    // Sort countries alphabetically in descending order and insert "Any" at the beginning
    countries.sort((a, b) => a.compareTo(b)); 
    countries.insert(0, 'Any');

    // Sort years in descending order and insert "Any" at the beginning
    years.sort((a, b) => b.compareTo(a)); 
    years.insert(0, -1);  // Use -1 to represent "Any" for year filter

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
          // Filter section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Country Dropdown
                Expanded(
                  child: DropdownButton<String>(
                    hint: const Text('Select Country'),
                    value: selectedCountry,
                    onChanged: (newValue) {
                      setState(() {
                        selectedCountry = newValue;
                      });
                      filterProducts();
                    },
                    items: countries.map((country) {
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                // Year Dropdown
                Expanded(
                  child: DropdownButton<int>(
                    hint: const Text('Select Year'),
                    value: selectedYear,
                    onChanged: (newValue) {
                      setState(() {
                        selectedYear = newValue;
                      });
                      filterProducts();
                    },
                    items: years.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year == -1 ? 'Any' : year.toString()),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Product Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: filteredProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.64,
              ),
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
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
