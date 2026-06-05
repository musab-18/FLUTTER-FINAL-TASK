import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/posts_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some text or an image.')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthProvider>().user!;
      String? imageURL;

      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance.ref('posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_selectedImage!);
        imageURL = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'userDisplayName': user.displayName,
        'userPhotoURL': user.photoURL,
        'content': _contentController.text.trim(),
        'imageURL': imageURL,
        'likesCount': 0,
        'commentsCount': 0,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) {
        context.read<PostsProvider>().fetchPosts(user.uid);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Upload Failed'),
            content: Text(
              'Failed to upload post. If you attached an image, please ensure Firebase Storage is set up in your Firebase Console (Click Storage -> Get Started).\n\nError: $e'
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child: _isLoading ? const CircularProgressIndicator() : const Text('Post'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_selectedImage != null)
              Stack(
                children: [
                  Image.file(_selectedImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _selectedImage = null),
                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    ),
                  ),
                ],
              ),
            const Divider(),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _pickImage,
                  color: Colors.blueAccent,
                ),
                const Text('Add Photo')
              ],
            )
          ],
        ),
      ),
    );
  }
}
