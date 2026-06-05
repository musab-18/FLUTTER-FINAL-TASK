import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email + password, create Firestore user doc
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    // Check username uniqueness
    final usernameQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('username', isEqualTo: username.toLowerCase())
        .get();

    if (usernameQuery.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'username-taken',
        message: 'That username is already taken. Please choose another.',
      );
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await cred.user!.updateDisplayName(displayName);
    await cred.user!.sendEmailVerification();

    final user = UserModel(
      uid: cred.user!.uid,
      email: email,
      displayName: displayName,
      username: username.toLowerCase(),
      bio: '',
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap());

    return user;
  }

  /// Sign in with email + password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Fetch UserModel from Firestore
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(data);
    if (data['displayName'] != null) {
      await _auth.currentUser?.updateDisplayName(data['displayName']);
    }
    if (data['photoUrl'] != null) {
      await _auth.currentUser?.updatePhotoURL(data['photoUrl']);
    }
  }

  /// Save FCM token for push notifications
  Future<void> updateFcmToken(String uid, String token) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'fcmToken': token});
  }
}
