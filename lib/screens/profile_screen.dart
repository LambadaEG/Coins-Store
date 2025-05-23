import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:project_1/models/product.dart';
import 'package:project_1/models/product_catalog_state.dart';
import 'package:project_1/services/auth_service.dart';
import 'package:project_1/screens/sell_coin_screen.dart';
import 'package:project_1/screens/order_details_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return FutureBuilder<String?>(
      future: Future.value(authService.currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userId = snapshot.data;

        if (userId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: Text('User not logged in')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Profile',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditProfileDialog(context, userId),
              ),
            ],
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
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

              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name']?.toString() ?? 'No Name',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userData['email']?.toString() ?? 'No Email',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (userData['phone'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              userData['phone']?.toString() ?? '',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const TabBar(
                      tabs: [
                        Tab(icon: Icon(Icons.sell), text: 'My Listings'),
                        Tab(icon: Icon(Icons.history), text: 'Order History'),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _SellerProductsList(userId: userId),
                          _UserOrdersList(userId: userId),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static void _showEditProfileDialog(BuildContext context, String userId) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    // Fetch current user data to pre-fill the form
    FirebaseFirestore.instance.collection('users').doc(userId).get().then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        nameController.text = data['name']?.toString() ?? '';
        phoneController.text = data['phone']?.toString() ?? '';
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    hintText: '+1234567890',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    // Simple phone number validation
                    if (!RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$')
                        .hasMatch(value)) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({
                    'name': nameController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating profile: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

class _UserOrdersList extends StatelessWidget {
  final String userId;

  const _UserOrdersList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders yet'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final order = snapshot.data!.docs[index];
            final data = order.data() as Map<String, dynamic>;
            final total = data['total'] as double? ?? 0.0;
            final timestamp =
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            final items = List<String>.from(data['items'] ?? []);

            return Dismissible(
              key: Key(order.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) => _confirmDelete(context, order.id),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsScreen(orderId: order.id),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text('Order #${order.id.substring(0, 6)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: EGP ${total.toStringAsFixed(2)}'),
                        Text('Items: ${items.length}'),
                        Text(DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, order.id),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String orderId) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .delete();
                Navigator.pop(ctx, true);
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: ${e.toString()}')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SellerProductsList extends StatefulWidget {
  final String userId;

  const _SellerProductsList({required this.userId});

  @override
  State<_SellerProductsList> createState() => _SellerProductsListState();
}

class _SellerProductsListState extends State<_SellerProductsList> {
  String? selectedCountry;

  num _safeParseNumber(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products listed yet'));
        }

        final allDocs = snapshot.data!.docs;

        final allCountries = allDocs
            .map((doc) => (doc['country'] ?? 'Unknown').toString())
            .toSet()
            .toList()
          ..sort();

        final filteredDocs = selectedCountry == null
            ? allDocs
            : allDocs.where((doc) => doc['country'] == selectedCountry).toList();

        final products = filteredDocs.map((doc) {
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

        return Column(
          children: [
            if (allCountries.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Filter by Country'),
                  value: selectedCountry,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Countries'),
                    ),
                    ...allCountries.map((country) {
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCountry = value;
                    });
                  },
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductListItem(product: product);
                },
              ),
            ),
          ],
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
      leading: Image.network(
        product.images.isNotEmpty ? product.images.first : '',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
      ),
      title: Text(product.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EGP ${product.price.toStringAsFixed(2)}'),
          Text('Year: ${product.year}'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SellCoinScreen(editingProduct: product),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context, product.id),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .delete();

                if (Navigator.canPop(ctx)) Navigator.pop(ctx);

                if (context.mounted) {
                  Provider.of<ProductCatalogState>(context, listen: false)
                      .fetchProducts();
                }
              } catch (e) {
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}