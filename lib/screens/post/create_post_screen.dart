import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentCtrl = TextEditingController();
  XFile? _pickedImage;
  bool _isPosting = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1080);
    if (img != null) setState(() => _pickedImage = img);
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something or add a photo!')),
      );
      return;
    }

    setState(() => _isPosting = true);
    final auth = context.read<AuthProvider>();
    final postProv = context.read<PostProvider>();

    final post = await postProv.createPost(
      author: auth.user!,
      content: content,
      image: _pickedImage,
    );

    if (!mounted) return;
    setState(() => _isPosting = false);

    if (post != null) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(postProv.errorMessage ?? 'Failed to create post.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hasContent = _contentCtrl.text.trim().isNotEmpty || _pickedImage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        leading: TextButton(
          onPressed: _isPosting ? null : () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        leadingWidth: 80,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: (_isPosting || !hasContent) ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(auth),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.user?.displayName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('@${auth.user?.username ?? ''}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _contentCtrl,
                        maxLines: null,
                        maxLength: AppConstants.maxPostLength,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: "What's on your mind?",
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          counterStyle:
                              TextStyle(color: AppTheme.textSecondary),
                        ),
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Image preview
            if (_pickedImage != null) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: kIsWeb
                        ? Image.network(_pickedImage!.path,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover)
                        : Image.file(File(_pickedImage!.path),
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _pickedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

            // Toolbar
            Row(
              children: [
                const Text('Add to your post:',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(width: 12),
                _ToolbarButton(
                  icon: Icons.image_outlined,
                  label: 'Photo',
                  color: AppTheme.successColor,
                  onTap: _pickImage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(AuthProvider auth) {
    final photo = auth.user?.photoUrl;
    final name = auth.user?.displayName ?? '';
    if (photo != null && photo.isNotEmpty) {
      return CircleAvatar(radius: 22, backgroundImage: NetworkImage(photo));
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppTheme.primaryColor,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ToolbarButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }
}
