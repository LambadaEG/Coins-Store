import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_catalog_state.dart';
import 'package:photo_view/photo_view.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final catalogState = Provider.of<ProductCatalogState>(context);
    final cart = catalogState.cart;

    final canAdd = cart.where((p) => p.id == product.id).length < product.inStock;

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              child: PhotoViewGallery.builder(
                itemCount: product.images.length,
                builder: (context, index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(product.images[index]),
                    minScale: PhotoViewComputedScale.contained * 1,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  );
                },
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(product.name, 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Price: ${product.formattedPrice}', 
                style: const TextStyle(color: Colors.green)),
            Text('Value: ${product.value.toStringAsFixed(2)}', // Added coin value
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Country: ${product.country}'),
            Text('Year: ${product.year}'),
            const SizedBox(height: 12),
            Text('Seller Name: ${product.sellerName}'), // Added seller name
            Text('Seller Phone: ${product.sellerPhone}'),
            const SizedBox(height: 12),
            Text(
              'Stock: ${product.inStock}',
              style: TextStyle(
                color: product.inStock > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: canAdd ? () => catalogState.addToCart(product) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAdd ? Colors.blue[800] : Colors.grey,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                canAdd
                    ? 'Add to Cart'
                    : product.inStock > 0
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