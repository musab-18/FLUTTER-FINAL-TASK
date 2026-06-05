import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      } else {
        final userModel = await _authService.getUserById(firebaseUser.uid);
        _user = userModel;
        _status = AuthStatus.authenticated;
      }
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
        username: username,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code, e.message);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signIn(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code, e.message);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _status = AuthStatus.unauthenticated;
    _user = null;
    notifyListeners();
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code, e.message);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String displayName,
    required String username,
    required String bio,
    XFile? newImage,
  }) async {
    if (_user == null) return false;
    _setLoading(true);
    _clearError();
    try {
      String? photoUrl = _user!.photoUrl;
      if (newImage != null) {
        photoUrl = await _storageService.uploadProfilePicture(
          userId: _user!.uid,
          image: newImage,
        );
      }
      final updates = {
        'displayName': displayName,
        'username': username.toLowerCase(),
        'bio': bio,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };
      await _authService.updateUserProfile(uid: _user!.uid, data: updates);
      _user = _user!.copyWith(
        displayName: displayName,
        username: username.toLowerCase(),
        bio: bio,
        photoUrl: photoUrl,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    final updated = await _authService.getUserById(_user!.uid);
    if (updated != null) {
      _user = updated;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _mapAuthError(String code, String? message) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      case 'username-taken':
        return message ?? 'Username is already taken.';
      default:
        return message ?? 'An error occurred. Please try again.';
    }
  }
}
