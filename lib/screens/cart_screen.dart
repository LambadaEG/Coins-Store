import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_1/models/product_catalog_state.dart';
import 'package:project_1/services/auth_service.dart';
import 'package:project_1/services/notification_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  Future<String> _getUserPhone(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return doc.data()?['phone'] ?? 'No phone provided';
    } catch (e) {
      return 'Error fetching phone';
    }
  }

  Future<int> _getUserOrderedQuantity(String userId, String productId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      int orderedQuantity = 0;

      for (var doc in querySnapshot.docs) {
        final items = List.from(doc.data()['items']);
        orderedQuantity += items.where((id) => id == productId).length;
      }

      return orderedQuantity;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _placeOrder(BuildContext context, String deliveryLocation) async {
    final catalogState = Provider.of<ProductCatalogState>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser!;
    final cart = catalogState.cart;

    try {
      // Validate stock before placing the order
      for (final product in cart) {
        final previouslyOrdered = await _getUserOrderedQuantity(user.uid, product.id);
        if (previouslyOrdered + 1 > product.inStock) { // 1 because each cart item is single
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot order more of "${product.name}". In stock: ${product.inStock}, already ordered: $previouslyOrdered.'),
              duration: const Duration(seconds: 3),
            ),
          );
          return; // Stop the order
        }
      }

      // Create order document
      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'items': cart.map((p) => p.id).toList(),
        'total': cart.fold(0.0, (sum, item) => sum + item.price),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'deliveryLocation': deliveryLocation,
      });

      // Create notifications for sellers
      for (final product in cart) {
        final buyerPhone = await _getUserPhone(user.uid);

        await NotificationService.sendOrderNotification(
          sellerId: product.sellerId,
          orderId: orderRef.id,
          productId: product.id,
          buyerId: user.uid,
          buyerPhone: buyerPhone,
        );
      }

      // Clear cart and show success
      catalogState.clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

Future<void> _showDeliveryLocationDialog(BuildContext context) async {
  final locations = ['كلية الهندسة', 'سيدي جابر', 'سوق ديانا - القاهرة'];

  await showDialog(
    context: context,
    builder: (context) {
      String? selectedLocation;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Select Delivery Location'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: locations.map((location) {
                return RadioListTile<String>(
                  title: Text(location),
                  value: location,
                  groupValue: selectedLocation,
                  onChanged: (value) {
                    setState(() {
                      selectedLocation = value;
                    });
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedLocation == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        _placeOrder(context, selectedLocation!);
                      },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    },
  );
}



  @override
  Widget build(BuildContext context) {
    final catalogState = Provider.of<ProductCatalogState>(context, listen: true);
    final cart = catalogState.cart;
    final total = cart.fold(0.0, (sum, item) => sum + item.price);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Cart', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
                        key: Key('${p.name}_${p.year}_${index}'),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) => catalogState.removeFromCart(p),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                              onPressed: () => catalogState.removeFromCart(p),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                              fontWeight: FontWeight.bold,
                            ),
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
                    onPressed: () => _showDeliveryLocationDialog(context),
                    child: const Text(
                      'Place Order',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}