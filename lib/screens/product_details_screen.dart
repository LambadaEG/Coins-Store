import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_catalog_state.dart';
import 'package:photo_view/photo_view.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = Provider.of<ProductCatalogState>(context);
    final cart = catalogState.cart;
    final canAdd = cart.where((p) => p.id == widget.product.id).length < widget.product.inStock;

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PhotoViewGallery.builder(
                    pageController: _pageController,
                    itemCount: widget.product.images.length,
                    builder: (context, index) {
                      return PhotoViewGalleryPageOptions(
                        imageProvider: NetworkImage(widget.product.images[index]),
                        minScale: PhotoViewComputedScale.contained * 1,
                        maxScale: PhotoViewComputedScale.covered * 2,
                      );
                    },
                    onPageChanged: (index) => setState(() => _currentPageIndex = index),
                    scrollPhysics: const BouncingScrollPhysics(),
                    backgroundDecoration: const BoxDecoration(color: Colors.white),
                  ),
                  if (widget.product.images.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.product.images.length,
                          (index) => GestureDetector(
                            onTap: () => _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPageIndex == index 
                                    ? Colors.blue[800]
                                    : Colors.grey.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ... rest of your existing content
            const SizedBox(height: 16),
            Text(widget.product.name, 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Price: ${widget.product.formattedPrice}', 
                style: const TextStyle(color: Colors.green)),
            Text('Value: ${widget.product.value.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Country: ${widget.product.country}'),
            Text('Year: ${widget.product.year}'),
            const SizedBox(height: 12),
            Text('Seller Name: ${widget.product.sellerName}'),
            Text('Seller Phone: ${widget.product.sellerPhone}'),
            const SizedBox(height: 12),
            Text(
              'Stock: ${widget.product.inStock}',
              style: TextStyle(
                color: widget.product.inStock > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: canAdd ? () => catalogState.addToCart(widget.product) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAdd ? Colors.blue[800] : Colors.grey,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                canAdd
                    ? 'Add to Cart'
                    : widget.product.inStock > 0
                        ? 'Max Reached'
                        : 'Out of Stock',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}