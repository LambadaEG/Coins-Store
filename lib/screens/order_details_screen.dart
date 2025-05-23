import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isSeller = false;
  bool _loadingUserCheck = true;

  @override
  void initState() {
    super.initState();
    _checkIfUserIsSeller();
  }

  Future<void> _checkIfUserIsSeller() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get();

    if (!orderDoc.exists) {
      setState(() {
        _loadingUserCheck = false;
      });
      return;
    }

    final orderData = orderDoc.data()!;
    final items = orderData['items'] as List<dynamic>;

    final sellerIds = <String>{};

    for (final item in items) {
      final productId = item is Map ? item['productId'] : item.toString();
      final productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      if (productDoc.exists) {
        final productData = productDoc.data()!;
        final sellerId = productData['sellerId']?.toString();
        if (sellerId != null) {
          sellerIds.add(sellerId);
        }
      }
    }

    setState(() {
      _isSeller = sellerIds.length == 1 && sellerIds.first == currentUser.uid;
      _loadingUserCheck = false;
    });
  }

  Future<void> _confirmOrder(Map<String, dynamic> orderData) async {
    try {
      final items = orderData['items'] as List<dynamic>;

      final products = await Future.wait(items.map((item) {
        final productId = item is Map ? item['productId'] : item.toString();
        return FirebaseFirestore.instance.collection('products').doc(productId).get();
      }));

      for (int i = 0; i < products.length; i++) {
        final doc = products[i];
        final product = doc.data()!;
        final stock = _parseStock(product['inStock']);
        final quantity = items[i] is Map ? items[i]['quantity'] ?? 1 : 1;

        if (stock < quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${product['name']} has insufficient stock!')),
          );
          return;
        }
      }

      final batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final productId = item is Map ? item['productId'] : item.toString();
        final quantity = item is Map ? item['quantity'] ?? 1 : 1;
        final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
        batch.update(productRef, {'inStock': FieldValue.increment(-quantity)});
      }

      batch.update(
        FirebaseFirestore.instance.collection('orders').doc(widget.orderId),
        {
          'status': 'confirmed',
          'confirmedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order confirmed successfully!')),
      );
      setState(() {}); // refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming order: $e')),
      );
    }
  }

  Future<void> _undoConfirmation(Map<String, dynamic> orderData) async {
    try {
      final items = orderData['items'] as List<dynamic>;
      final batch = FirebaseFirestore.instance.batch();

      for (final item in items) {
        final productId = item is Map ? item['productId'] : item.toString();
        final quantity = item is Map ? item['quantity'] ?? 1 : 1;
        final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
        batch.update(productRef, {'inStock': FieldValue.increment(quantity)});
      }

      batch.update(
        FirebaseFirestore.instance.collection('orders').doc(widget.orderId),
        {
          'status': 'pending',
          'confirmedAt': FieldValue.delete(),
        },
      );

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order confirmation undone!')),
      );
      setState(() {}); // refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error undoing confirmation: $e')),
      );
    }
  }

  int _parseStock(dynamic stockValue) {
    if (stockValue == null) return 0;
    if (stockValue is int) return stockValue;
    if (stockValue is double) return stockValue.toInt();
    if (stockValue is String) return int.tryParse(stockValue) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _loadingUserCheck) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('The order is cancelled'));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final items = orderData['items'] as List<dynamic>;
          final total = orderData['total'] as double;
          final timestamp = orderData['timestamp'] as Timestamp;
          final isConfirmed = orderData['status'] == 'confirmed';

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Order #${widget.orderId.substring(0, 8)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text('Date: ${DateFormat.yMMMd().add_jm().format(timestamp.toDate())}'),
              if (orderData['confirmedAt'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Confirmed: ${DateFormat.yMMMd().add_jm().format((orderData['confirmedAt'] as Timestamp).toDate())}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...items.map((item) => FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('products')
                        .doc(item is Map ? item['productId'] : item.toString())
                        .get(),
                    builder: (context, productSnapshot) {
                      if (productSnapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(leading: CircularProgressIndicator());
                      }

                      if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                        return const ListTile(title: Text('Product not found'));
                      }

                      final product = productSnapshot.data!.data() as Map<String, dynamic>;
                      final quantity = item is Map ? item['quantity'] ?? 1 : 1;
                      final inStock = _parseStock(product['inStock']);

                      return ListTile(
                        leading: product['images'] != null &&
                                product['images'] is List &&
                                product['images'].isNotEmpty
                            ? Image.network(product['images'][0], width: 50, height: 50)
                            : const Icon(Icons.monetization_on),
                        title: Text(product['name'] ?? 'Unnamed Product'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EGP ${product['price']?.toStringAsFixed(2) ?? '0.00'}'),
                            Text('Quantity: $quantity'),
                            Text('Stock: $inStock',
                                style: TextStyle(
                                    color: inStock > 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold)),
                            if (product['year'] != null) Text('Year: ${product['year']}'),
                          ],
                        ),
                      );
                    },
                  )),
              const SizedBox(height: 16),
              Text(
                'Total: EGP ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 24),
              if (_isSeller && !isConfirmed)
                ElevatedButton(
                  onPressed: () => _confirmOrder(orderData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Confirm Order Purchase', style: TextStyle(color: Colors.white)),
                ),
              if (_isSeller && isConfirmed)
                ElevatedButton(
                  onPressed: () => _undoConfirmation(orderData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Undo Confirmation', style: TextStyle(color: Colors.white)),
                ),
            ],
          );
        },
      ),
    );
  }
}
