import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/auth_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUserId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final photoURL = data['fromUserPhotoURL'] as String?;
              final displayName = data['fromUserDisplayName'] ?? 'Someone';
              final type = data['type']; // 'like' or 'comment'
              final content = data['postContent'] ?? '';
              final read = data['read'] ?? false;
              final time = data['createdAt'] ?? 0;

              return ListTile(
                tileColor: read ? null : Colors.blue.withValues(alpha: 0.1),
                leading: CircleAvatar(
                  backgroundImage: photoURL != null ? CachedNetworkImageProvider(photoURL) : null,
                  child: photoURL == null ? const Icon(Icons.person) : null,
                ),
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white),
                    children: [
                      TextSpan(text: displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: type == 'like' ? ' liked your post: ' : ' commented on your post: '),
                      TextSpan(text: '"$content"', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                subtitle: Text(timeago.format(DateTime.fromMillisecondsSinceEpoch(time))),
                onTap: () {
                  if (!read) {
                    doc.reference.update({'read': true});
                  }
                  // Navigate to post details if desired
                },
              );
            },
          );
        },
      ),
    );
  }
}
