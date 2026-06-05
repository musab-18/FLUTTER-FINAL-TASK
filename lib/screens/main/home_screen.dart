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
