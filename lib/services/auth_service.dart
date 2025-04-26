import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Auth state stream
  Stream<User?> get user => _auth.authStateChanges();

  // Sign in with email
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _getAuthError(e.code);
    }
  }

  // Sign up with email
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _getAuthError(e.code);
    }
  }

  // Sign out
  Future<void> signOut() async => await _auth.signOut();

  // Error handling
  String _getAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email format';
      case 'user-disabled':
        return 'Account disabled';
      case 'user-not-found':
        return 'No user found';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'weak-password':
        return 'Password too weak (min 6 chars)';
      default:
        return 'Authentication failed';
    }
  }
}