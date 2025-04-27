import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:project_1/models/notification_model.dart' as my_notification; // Added alias
import 'package:project_1/services/auth_service.dart';
import 'package:project_1/screens/order_details_screen.dart'; // Added import

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthService>(context).currentUserId;

    // Handle null userId case
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          final notifications = snapshot.data!.docs.map((doc) {
            return my_notification.Notification.fromFirestore(doc); // Using alias
          }).toList();

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                title: Text('New order from ${notification.buyerName}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.buyerPhone),
                    Text(DateFormat.yMMMd().format(notification.timestamp)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.mark_as_unread),
                  onPressed: () => _markAsRead(notification.id, userId), // userId is now non-null
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(orderId: notification.orderId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _markAsRead(String notificationId, String userId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }
}