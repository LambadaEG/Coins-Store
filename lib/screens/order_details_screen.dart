import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Added for DateFormat

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found'));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final items = orderData['items'] as List<dynamic>;
          final total = orderData['total'] as double;
          final timestamp = orderData['timestamp'] as Timestamp;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${orderId.substring(0, 8)}',
                  style: Theme.of(context).textTheme.titleLarge, // Changed from headline6
                ),
                const SizedBox(height: 16),
                Text(
                  'Date: ${DateFormat.yMMMd().add_jm().format(timestamp.toDate())}',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...items.map((itemId) => FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('products')
                      .doc(itemId.toString())
                      .get(),
                  builder: (context, productSnapshot) {
                    if (productSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircularProgressIndicator(),
                      );
                    }
                    if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                      return const ListTile(title: Text('Product not found'));
                    }
                    final product = productSnapshot.data!.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: product['images'] != null && product['images'].isNotEmpty
                          ? Image.network(product['images'][0], width: 50, height: 50)
                          : const Icon(Icons.monetization_on),
                      title: Text(product['name'] ?? 'Unnamed Product'),
                      subtitle: Text('EGP ${product['price']?.toStringAsFixed(2) ?? '0.00'}'),
                    );
                  },
                )),
                const SizedBox(height: 16),
                Text(
                  'Total: EGP ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}