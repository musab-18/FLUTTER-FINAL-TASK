import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/post_service.dart';

class CommentsScreen extends StatefulWidget {
  final PostModel post;
  const CommentsScreen({super.key, required this.post});
  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  final PostService _postService = PostService();
  bool _isSending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    setState(() => _isSending = true);
    try {
      await _postService.addComment(
        postId: widget.post.id,
        author: auth.user!,
        content: text,
        postAuthorId: widget.post.authorId,
      );
      _ctrl.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(children: [
                Text('Comments',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            const Divider(height: 1),

            // Comments list
            Expanded(
              child: StreamBuilder<List<CommentModel>>(
                stream: _postService.getCommentsStream(widget.post.id),
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(
                        color: AppTheme.primaryColor));
                  }
                  final comments = snap.data ?? [];
                  if (comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 56, color: AppTheme.textSecondary),
                          const SizedBox(height: 12),
                          Text('No comments yet',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          const Text('Be the first to comment!',
                              style:
                                  TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final c = comments[i];
                      final isOwner = auth.user?.uid == c.authorId;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _commentAvatar(c),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(c.authorName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    const SizedBox(width: 6),
                                    Text(timeago.format(c.createdAt),
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(c.content,
                                      style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                          if (isOwner)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppTheme.textSecondary),
                              onPressed: () => _postService.deleteComment(
                                  postId: widget.post.id,
                                  commentId: c.id),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Input bar
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AppTheme.dividerColor, width: 0.5)),
                  color: AppTheme.bgDark,
                ),
                child: Row(children: [
                  if (auth.user?.photoUrl != null)
                    CircleAvatar(
                      radius: 18,
                      backgroundImage:
                          CachedNetworkImageProvider(auth.user!.photoUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        auth.user?.displayName.isNotEmpty == true
                            ? auth.user!.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppTheme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppTheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor))
                      : IconButton(
                          icon: const Icon(Icons.send_rounded,
                              color: AppTheme.primaryColor),
                          onPressed: _sendComment,
                        ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _commentAvatar(CommentModel c) {
    if (c.authorPhotoUrl != null && c.authorPhotoUrl!.isNotEmpty) {
      return CircleAvatar(
          radius: 18,
          backgroundImage: CachedNetworkImageProvider(c.authorPhotoUrl!));
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppTheme.primaryColor,
      child: Text(
        c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
