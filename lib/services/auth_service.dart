import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the current user (returns null if not logged in)
  User? get currentUser => _auth.currentUser;

  /// Get the current user's email (returns null if not logged in)
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Get the current user's ID (returns null if not logged in)
  String? get currentUserId => _auth.currentUser?.uid;

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _getAuthError(e.code);
    } catch (e) {
      throw 'Login failed. Please try again.';
    }
  }

  /// Register with email, password, name and phone
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. Save additional user data in Firestore
      await _firestore.collection('users').doc(credential.user?.uid).set({
        'name': name,
        'phone': phone,
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _getAuthError(e.code);
    } catch (e) {
      throw 'Registration failed. Please try again.';
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUserId == null) return null;
    
    final doc = await _firestore.collection('users').doc(currentUserId).get();
    return doc.data();
  }

  /// Update user profile
  Future<void> updateProfile({String? name, String? phone}) async {
    if (currentUserId == null) return;
    
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    
    if (data.isNotEmpty) {
      await _firestore.collection('users').doc(currentUserId).update(data);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _getAuthError(e.code);
    } catch (e) {
      throw 'Failed to send reset email. Please try again.';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Logout failed. Please try again.';
    }
  }

  /// Helper method to translate Firebase auth error codes
  String _getAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address format';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication error: $code';
    }
  }
}