//lib/services/authenticate.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../models/user.dart'; 
// This is your custom User class

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Convert Firebase User to custom User
  User? _userFromFirebaseUser(firebase_auth.User? user) {
    return user != null
        ? User(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
          )
        : null;
  }

  // Auth state changes stream
  Stream<User?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // Sign in anonymously
  Future<User?> signInAnon() async {
    try {
      var result = await _auth.signInAnonymously();
      return _userFromFirebaseUser(result.user);
    } catch (e) {
      if(kDebugMode){
      print(e.toString());
      }
      return null;
    }
  }

  // Sign in with email & password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      var result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return _userFromFirebaseUser(result.user);
    } catch (e) {
      if(kDebugMode){
      print(e.toString());
    }
      return null;
    }
  }

  // Register with email & password
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      var result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return _userFromFirebaseUser(result.user);
    } catch (e) {
      if(kDebugMode){
      print(e.toString());
      }
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      if(kDebugMode){
      print(e.toString());
      }
    }
  }
}
