import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/post_service.dart';
import '../utils/dummy_data.dart';
import 'package:image_picker/image_picker.dart';

class PostProvider extends ChangeNotifier {
  final PostService _postService = PostService();

  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  DocumentSnapshot? _lastDoc;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  // ─── Feed ─────────────────────────────────────────────────────────────────

  Future<void> loadFeed() async {
    _isLoading = true;
    _posts = [];
    _lastDoc = null;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _loadNextPage();
    } catch (e) {
      _errorMessage = 'Failed to load feed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      await _loadNextPage();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _loadNextPage() async {
    try {
      final query = _postService.getFeedQuery(lastDoc: _lastDoc);
      final snap = await query.get();
      if (snap.docs.isEmpty) {
        if (_posts.isEmpty) _posts = List.from(DummyData.posts);
        _hasMore = false;
        return;
      }
      _lastDoc = snap.docs.last;
      final newPosts = snap.docs.map(PostModel.fromFirestore).toList();
      _posts.addAll(newPosts);
      if (snap.docs.length < 10) _hasMore = false;
    } catch (e) {
      if (_posts.isEmpty) {
        _posts = List.from(DummyData.posts);
        _hasMore = false;
      } else {
        rethrow;
      }
    }
  }

  Future<void> refresh() => loadFeed();

  // ─── Create / Delete ──────────────────────────────────────────────────────

  Future<PostModel?> createPost({
    required UserModel author,
    required String content,
    XFile? image,
  }) async {
    try {
      final post = await _postService.createPost(
        author: author,
        content: content,
        image: image,
      );
      _posts.insert(0, post);
      notifyListeners();
      return post;
    } catch (e) {
      _errorMessage = 'Failed to create post: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> deletePost(PostModel post) async {
    try {
      await _postService.deletePost(post);
      _posts.removeWhere((p) => p.id == post.id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete post.';
      notifyListeners();
    }
  }

  // ─── Likes ────────────────────────────────────────────────────────────────

  Future<void> toggleLike({
    required String postId,
    required String userId,
    required String postAuthorId,
    required String likerName,
    String? likerPhotoUrl,
  }) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final isLiked = post.isLikedBy(userId);

    // Optimistic update
    final updatedLikedBy = List<String>.from(post.likedBy);
    if (isLiked) {
      updatedLikedBy.remove(userId);
    } else {
      updatedLikedBy.add(userId);
    }
    _posts[index] = post.copyWith(
      likesCount: isLiked ? post.likesCount - 1 : post.likesCount + 1,
      likedBy: updatedLikedBy,
    );
    notifyListeners();

    try {
      await _postService.toggleLike(
        postId: postId,
        userId: userId,
        isLiked: isLiked,
        postAuthorId: postAuthorId,
        likerName: likerName,
        likerPhotoUrl: likerPhotoUrl,
      );
    } catch (_) {
      // Revert on failure
      _posts[index] = post;
      notifyListeners();
    }
  }
}
