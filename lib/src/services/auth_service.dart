import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart';
import 'package:myapp/src/models/user_role.dart'; // Import UserRole model

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Initialize Firestore
  User? _user;
  UserRole? _userRole; // Store user role

  User? get user => _user;
  UserRole? get userRole => _userRole;

  AuthService() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      _user = firebaseUser;
      if (firebaseUser != null) {
        // Fetch user role from Firestore
        final userRoleDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (userRoleDoc.exists) {
          _userRole = UserRole.fromFirestore(userRoleDoc, null);
        } else {
          // If no role defined, default to 'user' and create the document
          _userRole = UserRole(uid: firebaseUser.uid, role: 'user');
          await _firestore.collection('users').doc(firebaseUser.uid).set(_userRole!.toFirestore());
        }
      } else {
        _userRole = null;
      }
      notifyListeners();
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        throw 'Wrong password provided for that user.';
      }
      throw e.message ?? 'An unknown error occurred.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Updated isAdmin method using the fetched user role
  Future<bool> isAdmin(User user) async {
    // Ensure the role is fetched before checking
    if (_userRole == null || _userRole!.uid != user.uid) {
      final userRoleDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userRoleDoc.exists) {
        _userRole = UserRole.fromFirestore(userRoleDoc, null);
      } else {
        _userRole = UserRole(uid: user.uid, role: 'user'); // Default if not found
        await _firestore.collection('users').doc(user.uid).set(_userRole!.toFirestore());
      }
    }
    return _userRole?.role == 'admin';
  }
}
