import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/post_service.dart';
import '../../models/user_model.dart';
import '../../utils/dummy_data.dart';
import '../post/create_post_screen.dart';
import '../settings/settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PostService _postService = PostService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text('@${user.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: StreamBuilder<List<PostModel>>(
            stream: _postService.getUserPostsStream(user.uid),
            builder: (_, snap) {
              var posts = snap.data ?? [];
              if (snap.hasError || posts.isEmpty) {
                posts = DummyData.posts;
              }
              
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _ProfileHeader(user: user, isOwn: true, posts: posts),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(2),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _PostGridTile(post: posts[i]),
                        childCount: posts.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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

// ─── Shared Profile Header ────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isOwn;
  final List<PostModel> posts;

  const _ProfileHeader(
      {required this.user, required this.isOwn, required this.posts});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        // Avatar
        Stack(
          children: [
            user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        CachedNetworkImageProvider(user.photoUrl!))
                : CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
            if (isOwn)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.bgDark, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(user.displayName,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold)),
        Text('@${user.username}',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14)),
        if (user.bio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(user.bio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, height: 1.5, color: AppTheme.textPrimary)),
          ),
        ],
        const SizedBox(height: 20),

        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatItem(value: '${posts.length}', label: 'Posts'),
            const SizedBox(width: 32),
            _StatItem(value: '${user.followersCount}', label: 'Followers'),
            const SizedBox(width: 32),
            _StatItem(value: '${user.followingCount}', label: 'Following'),
          ],
        ),
        const SizedBox(height: 20),

        // Action button
        if (isOwn)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Profile'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EditProfileScreen()),
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),
        const Divider(height: 1),
      ],
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
      Text(value,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    ]);
  }
}

class _PostGridTile extends StatelessWidget {
  final PostModel post;
  const _PostGridTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return post.imageUrl != null
        ? CachedNetworkImage(
            imageUrl: post.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Container(color: AppTheme.cardDark),
            errorWidget: (_, __, ___) =>
                Container(color: AppTheme.cardDark,
                    child: const Icon(Icons.broken_image_outlined,
                        color: AppTheme.textSecondary)),
          )
        : Container(
            color: AppTheme.surfaceDark,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8),
            child: Text(
              post.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
            ),
          );
  }
}
