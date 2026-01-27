import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app/home/home_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  String? _error;

  // Google Sign-In object with Gmail scopes
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.send',
    ],
  );

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1️⃣ Trigger Google Sign-In
      final GoogleSignInAccount? account =
          await _googleSignIn.signIn();

      if (account == null) {
        // User cancelled sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 2️⃣ Get OAuth tokens
      final GoogleSignInAuthentication auth =
          await account.authentication;

      final String? accessToken = auth.accessToken;

      if (accessToken == null) {
        throw Exception('Failed to get access token');
      }

      // 🔍 TEMP: print token to verify OAuth works
      debugPrint('ACCESS TOKEN: $accessToken');

      // 3️⃣ Navigate to Home screen (Inbox)
      // We pass the accessToken because Gmail API needs it
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            accessToken: accessToken,
            userEmail: account.email,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Inboxie',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 20),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.mail),
                      label: const Text('Sign in with Google'),
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
