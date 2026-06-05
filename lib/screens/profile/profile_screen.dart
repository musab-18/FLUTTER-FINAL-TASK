import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: user.photoURL != null ? CachedNetworkImageProvider(user.photoURL!) : null,
              child: user.photoURL == null ? const Icon(Icons.person, size: 50) : null,
            ),
            const SizedBox(height: 16),
            Text(user.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(user.email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Text(user.bio.isNotEmpty ? user.bio : 'No bio available', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Posts', user.postsCount),
                _buildStatColumn('Followers', 0), // Placeholder
                _buildStatColumn('Following', 0), // Placeholder
              ],
            ),
            const Divider(height: 48),
            // User's posts
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('posts')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No posts yet.');
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    if (data['imageURL'] != null) {
                      return CachedNetworkImage(
                        imageUrl: data['imageURL'],
                        fit: BoxFit.cover,
                      );
                    }
                    return Container(
                      color: Colors.grey[800],
                      padding: const EdgeInsets.all(4),
                      child: Center(
                        child: Text(
                          data['content'] ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
