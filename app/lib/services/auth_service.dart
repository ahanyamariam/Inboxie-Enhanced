import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';

/// Result of a successful Google Sign-In.
class AuthResult {
  final String accessToken;
  final String email;
  final String? displayName;
  final String? photoUrl;

  const AuthResult({
    required this.accessToken,
    required this.email,
    this.displayName,
    this.photoUrl,
  });
}

/// Handles Google Sign-In authentication and token management.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.send',
    ],
  );

  static const Duration _signInTimeout = Duration(seconds: 30);

  /// Checks if there's an existing signed-in user and attempts to restore the session silently.
  /// Returns an [AuthResult] if successful, or `null` if no user is signed in.
  Future<AuthResult?> signInSilently() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();

      if (account == null) {
        return null; // No existing session
      }

      final GoogleSignInAuthentication auth = await account.authentication.timeout(_signInTimeout);
      final String? accessToken = auth.accessToken;

      if (accessToken == null) {
        throw Exception('Failed to get access token');
      }

      return AuthResult(
        accessToken: accessToken,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      print('Silent sign-in failed: $e');
      return null; // Silent sign-in failed, user needs to sign in explicitly
    }
  }

  /// Signs in with Google and shows the account picker.
  /// Returns an [AuthResult] on success, or `null` if the user cancelled.
  /// Throws on failure.
  Future<AuthResult?> signInWithGoogle() async {
    final GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn().timeout(_signInTimeout);
    } on TimeoutException {
      throw Exception(
        'Google sign-in timed out. Please check your internet and try again.',
      );
    } on Exception catch (e) {
      final raw = e.toString().toLowerCase();
      if (raw.contains('com.google.android.gms.common.api') ||
          raw.contains('sign_in_failed') ||
          raw.contains('siginin failed')) {
        throw Exception(
          'Google Sign-In failed due to Android OAuth configuration. '
          'Please verify SHA-1/SHA-256 fingerprints and `google-services.json`.',
        );
      }
      rethrow;
    }

    if (account == null) {
      return null; // User cancelled
    }

    final GoogleSignInAuthentication auth;
    try {
      auth = await account.authentication.timeout(_signInTimeout);
    } on TimeoutException {
      throw Exception(
        'Google authentication timed out while requesting access token.',
      );
    }
    final String? accessToken = auth.accessToken;

    if (accessToken == null) {
      throw Exception('Failed to get access token');
    }

    return AuthResult(
      accessToken: accessToken,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  String _friendlyGoogleSignInError(String code, String? description) {
    final details = description == null || description.isEmpty
        ? ''
        : ' ($description)';

    switch (code) {
      case 'sign_in_canceled':
        return 'Google sign-in canceled by user.';
      case 'network_error':
        return 'Network error during Google sign-in. Check connection and try again.';
      case 'sign_in_required':
        return 'No Google account available on this device. Add one in device settings.';
      case 'sign_in_failed':
      default:
        return 'Google sign-in failed$details';
    }
  }
}
