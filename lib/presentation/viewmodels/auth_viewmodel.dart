import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth;

  AuthViewModel(this._firebaseAuth);

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  User? _user;

  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  bool get isAuthenticated => _user != null;

  // Check initial auth state
  Future<void> checkAuthState() async {
    _setState(AuthState.loading);
    
    _user = _firebaseAuth.currentUser;
    
    if (_user != null) {
      _setState(AuthState.authenticated);
    } else {
      _setState(AuthState.unauthenticated);
    }
  }

  // Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    try {
      _setState(AuthState.loading);
      _errorMessage = null;

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      _setState(AuthState.authenticated);
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _setState(AuthState.error);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _setState(AuthState.error);
    }
  }

  // Register with email and password
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setState(AuthState.loading);
      _errorMessage = null;

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();
      
      _user = _firebaseAuth.currentUser;
      _setState(AuthState.authenticated);
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _setState(AuthState.error);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _setState(AuthState.error);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _user = null;
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _errorMessage = 'Failed to sign out';
      _setState(AuthState.error);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      _setState(AuthState.loading);
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _setState(_user != null ? AuthState.authenticated : AuthState.unauthenticated);
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _setState(AuthState.error);
    }
  }

  void _setState(AuthState state) {
    _state = state;
    // Log auth state transitions for debugging intermittent navigation to login
    // Use developer.log so it's easy to spot in console. Avoid sensitive data.
    developer.log('Auth state -> $_state, user: ${_user?.uid}', name: 'AuthViewModel');
    notifyListeners();
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}