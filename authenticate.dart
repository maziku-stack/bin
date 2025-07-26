import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Register with email & password
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      // Add user to Firestore users collection with default 'user' role
      await _db.collection('users').doc(user!.uid).set({
        'email': user.email,
        'uid': user.uid,
        'role': 'user', // default role
        'createdAt': FieldValue.serverTimestamp(),
      });

      return user;
    } catch (e) {
      print("Registration error: $e");
      return null;
    }
  }

  // Sign in with email & password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result =
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Auth state changes stream
  Stream<User?> get user => _auth.authStateChanges();
}
