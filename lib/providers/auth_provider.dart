import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _userModel;
  bool _isLoading = true;

  UserModel? get user => _userModel;
  bool get isAuthenticated => _userModel != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _userModel = null;
    } else {
      try {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          _userModel = UserModel.fromMap(doc.data()!, doc.id);
        } else {
          _userModel = null;
        }
      } catch (e) {
        _userModel = null;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      final newUser = UserModel(
        uid: cred.user!.uid,
        email: email,
        displayName: displayName,
      );
      await _firestore.collection('users').doc(cred.user!.uid).set(newUser.toMap());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
