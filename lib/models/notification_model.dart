import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { like, comment, follow }

class NotificationModel {
  final String id;
  final String recipientId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final NotificationType type;
  final String? postId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.type,
    this.postId,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.like,
      ),
      postId: data['postId'],
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'recipientId': recipientId,
        'senderId': senderId,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
        'type': type.name,
        'postId': postId,
        'message': message,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
