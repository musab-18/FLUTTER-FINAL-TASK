import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import 'storage_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  // ─── Feed ────────────────────────────────────────────────────────────────

  /// Returns a paginated query for the feed
  Query<Map<String, dynamic>> getFeedQuery({DocumentSnapshot? lastDoc}) {
    var query = _firestore
        .collection(AppConstants.postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.postsPerPage);
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);
    return query;
  }

  /// Stream for real-time updates (first page only)
  Stream<List<PostModel>> getFeedStream() {
    return _firestore
        .collection(AppConstants.postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.postsPerPage)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromFirestore).toList());
  }

  // ─── Create ──────────────────────────────────────────────────────────────

  Future<PostModel> createPost({
    required UserModel author,
    required String content,
    XFile? image,
  }) async {
    String? imageUrl;
    if (image != null) {
      imageUrl = await _storageService.uploadPostImage(
        userId: author.uid,
        image: image,
      );
    }

    final docRef = _firestore.collection(AppConstants.postsCollection).doc();
    final post = PostModel(
      id: docRef.id,
      authorId: author.uid,
      authorName: author.displayName,
      authorUsername: author.username,
      authorPhotoUrl: author.photoUrl,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    await docRef.set(post.toMap());

    // Increment postsCount
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(author.uid)
        .update({'postsCount': FieldValue.increment(1)});

    return post;
  }

  // ─── Delete ──────────────────────────────────────────────────────────────

  Future<void> deletePost(PostModel post) async {
    if (post.imageUrl != null) {
      await _storageService.deleteFile(post.imageUrl!);
    }
    await _firestore
        .collection(AppConstants.postsCollection)
        .doc(post.id)
        .delete();
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(post.authorId)
        .update({'postsCount': FieldValue.increment(-1)});
  }

  // ─── Likes ───────────────────────────────────────────────────────────────

  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool isLiked,
    required String postAuthorId,
    required String likerName,
    String? likerPhotoUrl,
  }) async {
    final postRef =
        _firestore.collection(AppConstants.postsCollection).doc(postId);

    if (isLiked) {
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
      // Send notification only when liking
      if (postAuthorId != userId) {
        await _sendNotification(
          recipientId: postAuthorId,
          senderId: userId,
          senderName: likerName,
          senderPhotoUrl: likerPhotoUrl,
          type: NotificationType.like,
          postId: postId,
          message: '$likerName liked your post',
        );
      }
    }
  }

  // ─── Comments ────────────────────────────────────────────────────────────

  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.commentsCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(CommentModel.fromFirestore).toList());
  }

  Future<void> addComment({
    required String postId,
    required UserModel author,
    required String content,
    required String postAuthorId,
  }) async {
    final commentRef = _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.commentsCollection)
        .doc();

    final comment = CommentModel(
      id: commentRef.id,
      postId: postId,
      authorId: author.uid,
      authorName: author.displayName,
      authorUsername: author.username,
      authorPhotoUrl: author.photoUrl,
      content: content,
      createdAt: DateTime.now(),
    );

    await commentRef.set(comment.toMap());
    await _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .update({'commentsCount': FieldValue.increment(1)});

    if (postAuthorId != author.uid) {
      await _sendNotification(
        recipientId: postAuthorId,
        senderId: author.uid,
        senderName: author.displayName,
        senderPhotoUrl: author.photoUrl,
        type: NotificationType.comment,
        postId: postId,
        message: '${author.displayName} commented: "$content"',
      );
    }
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    await _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.commentsCollection)
        .doc(commentId)
        .delete();
    await _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .update({'commentsCount': FieldValue.increment(-1)});
  }

  // ─── User Posts ──────────────────────────────────────────────────────────

  Stream<List<PostModel>> getUserPostsStream(String userId) {
    return _firestore
        .collection(AppConstants.postsCollection)
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromFirestore).toList());
  }

  // ─── Notifications ───────────────────────────────────────────────────────

  Future<void> _sendNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required NotificationType type,
    String? postId,
    required String message,
  }) async {
    final notifRef = _firestore
        .collection(AppConstants.notificationsCollection)
        .doc();

    final notif = NotificationModel(
      id: notifRef.id,
      recipientId: recipientId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: type,
      postId: postId,
      message: message,
      createdAt: DateTime.now(),
    );

    await notifRef.set(notif.toMap());
  }

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map(NotificationModel.fromFirestore).toList());
  }

  Future<void> markNotificationsRead(String userId) async {
    final batch = _firestore.batch();
    final snap = await _firestore
        .collection(AppConstants.notificationsCollection)
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
