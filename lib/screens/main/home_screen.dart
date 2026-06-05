import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/posts_provider.dart';
import '../post/create_post_screen.dart';
import '../../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.uid;
      if (userId != null) {
        context.read<PostsProvider>().fetchPosts(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Seed Dummy Posts',
            onPressed: () async {
              final user = context.read<AuthProvider>().user;
              if (user == null) return;
              try {
                final firestore = FirebaseFirestore.instance;
                final now = DateTime.now().millisecondsSinceEpoch;
                await firestore.collection('posts').add({
                  'userId': user.uid,
                  'userDisplayName': user.displayName,
                  'userPhotoURL': user.photoURL,
                  'content': 'Hello world! This is my first pre-loaded post for the internship project. Really excited to build this Social Connect app!',
                  'imageURL': null,
                  'likesCount': 0,
                  'commentsCount': 0,
                  'createdAt': now,
                });
                await firestore.collection('posts').add({
                  'userId': user.uid,
                  'userDisplayName': user.displayName,
                  'userPhotoURL': user.photoURL,
                  'content': 'Just testing the responsiveness and real-time feed updates. Everything looks blazing fast! 🚀',
                  'imageURL': null,
                  'likesCount': 0,
                  'commentsCount': 0,
                  'createdAt': now - 60000,
                });
                context.read<PostsProvider>().fetchPosts(user.uid);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dummy posts seeded!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          )
        ],
      ),
      body: postsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final userId = context.read<AuthProvider>().user?.uid;
                if (userId != null) {
                  await context.read<PostsProvider>().fetchPosts(userId);
                }
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: postsProvider.posts.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.forum, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No posts yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Be the first to post!'),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
                              },
                            )
                          ],
                        )
                      : ListView.builder(
                          itemCount: postsProvider.posts.length,
                          itemBuilder: (context, index) {
                            final post = postsProvider.posts[index];
                            return PostCard(post: post);
                          },
                        ),
                ),
              ),
            ),
    );
  }
}
