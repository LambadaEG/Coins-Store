import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_1/models/product.dart';
import 'package:project_1/models/product_catalog_state.dart';
import 'package:project_1/services/auth_service.dart';
import 'package:project_1/screens/sell_coin_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.currentUserId;

    return Scaffold(
      appBar: AppBar(title: Text('Profile',style: TextStyle(color: Theme.of(context).colorScheme.primary),),),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.data!.exists) {
            return const Center(child: Text('User data not found'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              ListTile(
                title: Text(userData['name']?.toString() ?? 'No Name'),
                subtitle: Text(userData['email']?.toString() ?? 'No Email'),
              ),
              const Divider(),
              Expanded(child: _SellerProductsList(userId: userId!)),
            ],
          );
        },
      ),
    );
  }
}

class _SellerProductsList extends StatelessWidget {
  final String userId;

  const _SellerProductsList({required this.userId});

  num _safeParseNumber(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('products')
              .where('sellerId', isEqualTo: userId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products listed yet'));
        }

        final products =
            snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Product(
                id: doc.id,
                name: data['name']?.toString() ?? 'Unnamed Product',
                price: _safeParseNumber(data['price']).toDouble(),
                images: List<String>.from(data['images'] ?? []),
                country: data['country']?.toString() ?? 'Unknown',
                year: _safeParseNumber(data['year']).toInt(),
                value: _safeParseNumber(data['value']).toDouble(),
                sellerId: data['sellerId']?.toString() ?? '',
                sellerName: data['sellerName']?.toString() ?? 'Unknown Seller',
                sellerPhone: data['sellerPhone']?.toString() ?? 'N/A',
                sellerEmail: data['sellerEmail']?.toString() ?? 'N/A',
                inStock: _safeParseNumber(data['inStock']).toInt(),
              );
            }).toList();

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductListItem(product: product);
          },
        );
      },
    );
  }
}

class ProductListItem extends StatelessWidget {
  final Product product;

  const ProductListItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(product.images.first),
      title: Text(product.name),
      subtitle: Text('EGP ${product.price.toStringAsFixed(2)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SellCoinScreen(editingProduct: product),
                  ),
                ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context, product.id),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Confirm Delete'),
            content: Text('Are you sure you want to delete this product?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    // Perform deletion
                    await FirebaseFirestore.instance
                        .collection('products')
                        .doc(productId)
                        .delete();

                    // Close dialog only once
                    if (Navigator.canPop(ctx)) {
                      Navigator.pop(ctx);
                    }

                    // Refresh product list
                    if (context.mounted) {
                      Provider.of<ProductCatalogState>(
                        context,
                        listen: false,
                      ).fetchProducts();
                    }
                  } catch (e) {
                    // Handle errors and ensure dialog closes
                    if (Navigator.canPop(ctx)) {
                      Navigator.pop(ctx);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete: ${e.toString()}'),
                        ),
                      );
                    }
                  }
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
