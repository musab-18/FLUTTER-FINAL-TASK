import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/app_theme.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../profile/user_profile_screen.dart';
import '../post/comments_screen.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onDelete;

  const PostCard({super.key, required this.post, this.onDelete});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  bool _showHeart = false;
  DateTime? _lastTap;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _showHeart = false);
          _heartController.reset();
        }
      });
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 400)) {
      _triggerLike();
    }
    _lastTap = now;
  }

  void _triggerLike() {
    final auth = context.read<AuthProvider>();
    final postProv = context.read<PostProvider>();
    if (auth.user == null) return;
    setState(() => _showHeart = true);
    _heartController.forward();
    postProv.toggleLike(
      postId: widget.post.id,
      userId: auth.user!.uid,
      postAuthorId: widget.post.authorId,
      likerName: auth.user!.displayName,
      likerPhotoUrl: auth.user!.photoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final postProv = context.read<PostProvider>();
    final isOwner = auth.user?.uid == widget.post.authorId;
    final isLiked = auth.user != null && widget.post.isLikedBy(auth.user!.uid);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(
                        userId: widget.post.authorId,
                      ),
                    ),
                  ),
                  child: _Avatar(
                    photoUrl: widget.post.authorPhotoUrl,
                    displayName: widget.post.authorName,
                    radius: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UserProfileScreen(userId: widget.post.authorId),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.post.authorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('@${widget.post.authorUsername}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                Text(
                  timeago.format(widget.post.createdAt),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz,
                        color: AppTheme.textSecondary),
                    color: AppTheme.cardDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (v) async {
                      if (v == 'delete') {
                        await postProv.deletePost(widget.post);
                        widget.onDelete?.call();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline, color: AppTheme.errorColor),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: AppTheme.errorColor)),
                        ]),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(widget.post.content,
                  style: const TextStyle(fontSize: 15, height: 1.5)),
            ),

          // ── Image ─────────────────────────────────────────────────────
          if (widget.post.imageUrl != null)
            GestureDetector(
              onTap: _handleDoubleTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(0)),
                    child: CachedNetworkImage(
                      imageUrl: widget.post.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 250,
                        color: AppTheme.cardDark,
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 200,
                        color: AppTheme.cardDark,
                        child: const Icon(Icons.broken_image_outlined,
                            color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  if (_showHeart)
                    ScaleTransition(
                      scale: Tween<double>(begin: 0, end: 1.4)
                          .animate(CurvedAnimation(
                        parent: _heartController,
                        curve: Curves.elasticOut,
                      )),
                      child: const Icon(Icons.favorite_rounded,
                          color: Colors.white, size: 80),
                    ),
                ],
              ),
            ),

          // ── Actions ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: Row(
              children: [
                // Like
                _ActionButton(
                  icon: isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor: isLiked ? AppTheme.secondaryColor : null,
                  label: widget.post.likesCount.toString(),
                  onTap: () {
                    if (auth.user == null) return;
                    postProv.toggleLike(
                      postId: widget.post.id,
                      userId: auth.user!.uid,
                      postAuthorId: widget.post.authorId,
                      likerName: auth.user!.displayName,
                      likerPhotoUrl: auth.user!.photoUrl,
                    );
                  },
                )
                    .animate(target: isLiked ? 1 : 0)
                    .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
                    .then()
                    .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1)),

                const SizedBox(width: 4),

                // Comment
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: widget.post.commentsCount.toString(),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppTheme.surfaceDark,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => CommentsScreen(post: widget.post),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon,
                size: 22, color: iconColor ?? AppTheme.textSecondary),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: iconColor ?? AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;

  const _Avatar({this.photoUrl, required this.displayName, required this.radius});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryColor,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.9),
      ),
    );
  }
}
