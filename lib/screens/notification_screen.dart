import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:project_1/models/notification_model.dart' as my_notification;
import 'package:project_1/services/auth_service.dart';
import 'package:project_1/screens/order_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthService>(context).currentUserId;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
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
            return my_notification.Notification.fromFirestore(doc);
          }).toList();

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) => _deleteNotification(
                  notification.id,
                  userId,
                ),
                child: Container(
                  color: notification.read ? Colors.grey[100] : null,
                  child: ListTile(
                    title: Text('New order from ${notification.buyerName}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.buyerPhone),
                        Text(DateFormat.yMMMd().format(notification.timestamp)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        notification.read
                            ? Icons.drafts
                            : Icons.markunread,
                        color: notification.read
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => _toggleReadStatus(
                        notification.id,
                        userId,
                        !notification.read,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsScreen(
                          orderId: notification.orderId,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleReadStatus(String notificationId, String userId, bool newStatus) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': newStatus});
  }

  void _deleteNotification(String notificationId, String userId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }
}
