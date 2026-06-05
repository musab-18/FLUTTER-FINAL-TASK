import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../screens/post/comments_sheet.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  void _handleLike(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.read<PostsProvider>().toggleLike(post, user.uid, user.displayName, user.photoURL);
    }
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(postId: post.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.userPhotoURL != null
                      ? CachedNetworkImageProvider(post.userPhotoURL!)
                      : null,
                  child: post.userPhotoURL == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userDisplayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(timeago.format(DateTime.fromMillisecondsSinceEpoch(post.createdAt)), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content, style: const TextStyle(fontSize: 15)),
            if (post.imageURL != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: post.imageURL!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(height: 200, color: Colors.grey),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _handleLike(context),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : Colors.grey,
                      ).animate(target: post.isLiked ? 1 : 0).scale(duration: 200.ms, curve: Curves.elasticOut),
                      const SizedBox(width: 4),
                      Text('${post.likesCount}'),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => _showComments(context),
                  child: Row(
                    children: [
                      const Icon(Icons.comment_outlined, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${post.commentsCount}'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
