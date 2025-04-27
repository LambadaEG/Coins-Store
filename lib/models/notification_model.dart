import 'package:cloud_firestore/cloud_firestore.dart';

// notification_model.dart
class Notification {
  final String id;
  final String orderId;
  final String productId;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final DateTime timestamp;
  final bool read;

  Notification({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.timestamp,
    this.read = false,
  });

  factory Notification.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Notification(
      id: doc.id,
      orderId: data['orderId'],
      productId: data['productId'],
      buyerId: data['buyerId'],
      buyerName: data['buyerName'],
      buyerPhone: data['buyerPhone'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'] ?? false,
    );
  }
}