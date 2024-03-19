import 'package:flutter/material.dart';
import '../product_utils.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: FutureBuilder<List<NotificationInfo>>(
        future: fetchNotificationsInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return Center(child: Text('No notifications available'));
            }
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  title: Text('Notification Type: ${notification.type}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Store Name: ${notification.storeName}'),
                      Text('Sender Email: ${notification.senderEmail ?? 'Unknown'}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () {
                          _showConfirmationDialog(context, notification, true);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          _showConfirmationDialog(context, notification, false);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, NotificationInfo notification, bool accept) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(accept ? 'Accept Invitation?' : 'Delete Notification?'),
          content: Text(accept ? 'Are you sure you want to accept this invitation?' : 'Are you sure you want to delete this notification?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (accept) {
                  acceptInvitation(notification);
                  // deleteInvitation(notification);
                } else {
                  deleteInvitation(notification);
                }
              },
              child: Text(accept ? 'Accept' : 'Delete'),
            ),
          ],
        );
      },
    );
  }
}
