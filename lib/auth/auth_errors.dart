import 'package:firebase_auth/firebase_auth.dart';

/// Turns a [FirebaseAuthException] into a short, friendly message that's
/// safe to show in the UI. Firebase's own error codes (like `wrong-password`
/// or `email-already-in-use`) are meant for developers, not end users, so
/// this is the one place that translates them.
String friendlyAuthError(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-email':
      return "That email doesn't look right.";
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'email-already-in-use':
      return 'An account with that email already exists.';
    case 'weak-password':
      return 'Please choose a stronger password.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'No internet connection. Please check your network and try again.';
    case 'operation-not-allowed':
      return 'Email/password sign-in is not enabled for this app yet.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
