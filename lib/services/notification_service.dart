import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

    final existingNotificationQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(sellerId)
        .collection('notifications')
        .where('orderId', isEqualTo: orderId)
        .get();

    // ✅ Send notification only if not already sent for this order
    if (existingNotificationQuery.docs.isEmpty) {
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

      // ✅ Send push notification (assuming seller FCM token exists)
      final sellerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();

      final fcmToken = sellerDoc.data()?['fcmToken'];
      if (fcmToken != null) {
        await FirebaseMessaging.instance.sendMessage(
          to: fcmToken,
          data: {
            'title': 'New Order',
            'body': 'You have a new order from ${buyerDoc.data()?['name'] ?? 'a user'}',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        );
      }
    }
  }

}
