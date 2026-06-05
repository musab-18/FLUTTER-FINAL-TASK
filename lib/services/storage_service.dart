import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Upload a profile picture, return its download URL
  Future<String> uploadProfilePicture({
    required String userId,
    required XFile image,
  }) async {
    final ref = _storage.ref().child('profile_pictures/$userId/avatar.jpg');
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      await ref.putFile(File(image.path));
    }
    return ref.getDownloadURL();
  }

  /// Upload a post image, return its download URL
  Future<String> uploadPostImage({
    required String userId,
    required XFile image,
  }) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('post_images/$userId/$fileName');
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      await ref.putFile(File(image.path));
    }
    return ref.getDownloadURL();
  }

  /// Delete a file at a given storage URL
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
