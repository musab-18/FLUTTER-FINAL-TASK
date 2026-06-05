import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

class PostsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Post> _posts = [];
  bool _isLoading = false;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;

  Future<void> fetchPosts(String currentUserId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final List<Post> loadedPosts = [];
      for (var doc in snapshot.docs) {
        final post = Post.fromMap(doc.data(), doc.id);
        // Check if current user liked it
        final likeDoc = await _firestore
            .collection('posts')
            .doc(post.id)
            .collection('likes')
            .doc(currentUserId)
            .get();
        post.isLiked = likeDoc.exists;
        loadedPosts.add(post);
      }
      _posts = loadedPosts;
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleLike(Post post, String userId, String userDisplayName, String? userPhotoURL) async {
    final likeRef = _firestore.collection('posts').doc(post.id).collection('likes').doc(userId);
    final postRef = _firestore.collection('posts').doc(post.id);

    final bool isLiking = !post.isLiked;

    // Optimistic update
    post.isLiked = isLiking;
    notifyListeners();

    try {
      if (isLiking) {
        await likeRef.set({'userId': userId, 'createdAt': DateTime.now().millisecondsSinceEpoch});
        await postRef.update({'likesCount': FieldValue.increment(1)});
        
        // Notify post owner
        if (post.userId != userId) {
          await _firestore.collection('notifications').add({
            'toUserId': post.userId,
            'fromUserId': userId,
            'fromUserDisplayName': userDisplayName,
            'fromUserPhotoURL': userPhotoURL,
            'type': 'like',
            'postId': post.id,
            'postContent': post.content.length > 100 ? post.content.substring(0, 100) : post.content,
            'read': false,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      } else {
        await likeRef.delete();
        await postRef.update({'likesCount': FieldValue.increment(-1)});
      }
    } catch (e) {
      // Revert optimistic update
      post.isLiked = !isLiking;
      notifyListeners();
      debugPrint('Error toggling like: $e');
    }
  }
}
