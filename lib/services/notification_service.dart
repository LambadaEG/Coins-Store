import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> sendOrderNotification({
    required String sellerId,
    required String orderId,
    required String productId,
    required String buyerId,
    required String buyerPhone,
  }) async {
    final buyerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(buyerId)
        .get();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(sellerId)
        .collection('notifications')
        .add({
          'orderId': orderId,
          'productId': productId,
          'buyerId': buyerId,
          'buyerName': buyerDoc.data()?['name'] ?? 'Anonymous',
          'buyerPhone': buyerDoc.data()?['phone'] ?? 'No phone',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
  }
}