import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/app_theme.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/post_service.dart';
import '../../utils/dummy_data.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _postService.markNotificationsRead(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _postService.getNotificationsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }

          var notifications = snapshot.data ?? [];

          if (snapshot.hasError || notifications.isEmpty) {
            notifications = DummyData.notifications;
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final n = notifications[i];
              IconData icon;
              Color color;
              switch (n.type) {
                case NotificationType.like:
                  icon = Icons.favorite;
                  color = AppTheme.secondaryColor;
                  break;
                case NotificationType.comment:
                  icon = Icons.chat_bubble;
                  color = AppTheme.primaryColor;
                  break;
                case NotificationType.follow:
                  icon = Icons.person_add;
                  color = AppTheme.successColor;
                  break;
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: n.isRead ? AppTheme.bgDark : AppTheme.surfaceDark.withValues(alpha: 0.5),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: n.senderPhotoUrl != null ? NetworkImage(n.senderPhotoUrl!) : null,
                      backgroundColor: AppTheme.cardDark,
                      child: n.senderPhotoUrl == null
                          ? Text(n.senderName.isNotEmpty ? n.senderName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.bgDark, width: 2),
                        ),
                        child: Icon(icon, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    children: [
                      TextSpan(text: n.senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: n.type == NotificationType.like ? ' liked your post.' : ' commented on your post.'),
                    ],
                  ),
                ),
                subtitle: Text(timeago.format(n.createdAt),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              );
            },
          );
        },
      ),
    );
  }
}
