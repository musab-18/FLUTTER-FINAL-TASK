import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../providers/auth_provider.dart';
import 'profile_screen.dart'; // We'll need to extract shared components if possible, but let's copy the needed parts for now

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getUserById(widget.userId);
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not found')),
      );
    }

    final isOwn = context.read<AuthProvider>().user?.uid == _user!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('@${_user!.username}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: StreamBuilder<List<PostModel>>(
            stream: _postService.getUserPostsStream(_user!.uid),
            builder: (_, snap) {
              final posts = snap.data ?? [];
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _user!.photoUrl != null
                                ? NetworkImage(_user!.photoUrl!)
                                : null,
                            backgroundColor: AppTheme.primaryColor,
                            child: _user!.photoUrl == null
                                ? Text(
                                    _user!.displayName.isNotEmpty
                                        ? _user!.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 40, color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Text(_user!.displayName,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('@${_user!.username}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                          if (_user!.bio.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(_user!.bio, textAlign: TextAlign.center),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatItem(value: '${posts.length}', label: 'Posts'),
                              const SizedBox(width: 32),
                              _StatItem(value: '${_user!.followersCount}', label: 'Followers'),
                              const SizedBox(width: 32),
                              _StatItem(value: '${_user!.followingCount}', label: 'Following'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (!isOwn)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Follow functionality would go here
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Follow feature coming soon!')));
                                },
                                child: const Text('Follow'),
                              ),
                            ),
                          const SizedBox(height: 16),
                          const Divider(),
                        ],
                      ),
                    ),
                  ),
                  if (posts.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text('No posts yet', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(2),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final p = posts[i];
                            return Container(
                              color: AppTheme.surfaceDark,
                              child: p.imageUrl != null
                                  ? Image.network(p.imageUrl!, fit: BoxFit.cover)
                                  : Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                          child: Text(p.content,
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12))),
                                    ),
                            );
                          },
                          childCount: posts.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    ]);
  }
}
