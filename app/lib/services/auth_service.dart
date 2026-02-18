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

  /// Signs in with Google and returns an [AuthResult] on success,
  /// or `null` if the user cancelled.
  /// Throws on failure.
  Future<AuthResult?> signInWithGoogle() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();

    if (account == null) {
      return null; // User cancelled
    }

    final GoogleSignInAuthentication auth = await account.authentication;
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
}
