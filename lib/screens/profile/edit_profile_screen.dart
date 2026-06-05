import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _displayName;
  late String _bio;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _displayName = user.displayName;
    _bio = user.bio;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthProvider>().user!;
      String? newPhotoURL = user.photoURL;

      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance.ref('users/${user.uid}/profile.jpg');
        await ref.putFile(_selectedImage!);
        newPhotoURL = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'displayName': _displayName,
        'bio': _bio,
        if (newPhotoURL != null) 'photoURL': newPhotoURL,
      });

      // Update provider logic would typically happen via auth listener 
      // but you can also do a manual refresh if required.

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading ? const CircularProgressIndicator() : const Text('Save'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (user.photoURL != null ? CachedNetworkImageProvider(user.photoURL!) : null) as ImageProvider?,
                  child: _selectedImage == null && user.photoURL == null ? const Icon(Icons.add_a_photo, size: 40) : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: _displayName,
                decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Name cannot be empty' : null,
                onSaved: (v) => _displayName = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _bio,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
                onSaved: (v) => _bio = v ?? '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
