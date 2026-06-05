import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;

  const CommentsSheet({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  bool _isPosting = false;

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      final user = context.read<AuthProvider>().user!;
      
      // Add comment
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'userId': user.uid,
        'userDisplayName': user.displayName,
        'userPhotoURL': user.photoURL,
        'content': content,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Increment count
      final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
      await postRef.update({'commentsCount': FieldValue.increment(1)});

      // Notify post owner
      final postSnap = await postRef.get();
      if (postSnap.exists) {
        final postData = postSnap.data()!;
        if (postData['userId'] != null && postData['userId'] != user.uid) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'toUserId': postData['userId'],
            'fromUserId': user.uid,
            'fromUserDisplayName': user.displayName,
            'fromUserPhotoURL': user.photoURL,
            'type': 'comment',
            'postId': widget.postId,
            'postContent': (postData['content'] ?? '').toString().length > 100 
                ? (postData['content'] ?? '').toString().substring(0, 100) 
                : (postData['content'] ?? ''),
            'read': false,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }

      if (mounted) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      debugPrint('Error posting comment: $e');
    }
    if (mounted) setState(() => _isPosting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
      ),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No comments yet.'));
                }

                final comments = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: data['userPhotoURL'] != null
                            ? CachedNetworkImageProvider(data['userPhotoURL'])
                            : null,
                        child: data['userPhotoURL'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(data['userDisplayName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['content'] ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            timeago.format(DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0)),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: _isPosting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _isPosting ? null : _postComment,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
