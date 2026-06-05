import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../profile/user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search users...',
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        ),
      ),
      body: _searchQuery.isEmpty
          ? const Center(child: Text('Search for friends'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('displayName', isGreaterThanOrEqualTo: _searchQuery)
                  .where('displayName', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }
                final users = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data() as Map<String, dynamic>;
                    final photoURL = data['photoURL'] as String?;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: photoURL != null ? CachedNetworkImageProvider(photoURL) : null,
                        child: photoURL == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(data['displayName'] ?? 'Unknown User'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(userId: users[index].id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
