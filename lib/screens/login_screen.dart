import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:smart_pendant_app/services/local_storage_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    // Use the loopback IP address for local development as it's more standard.
    const String url = 'http://127.0.0.1:3001/api/auth/google';
    const String callbackUrlScheme = 'kairo';

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: callbackUrlScheme,
      );

      final String? token = Uri.parse(result).queryParameters['token'];

      if (token != null) {
        final storage = LocalStorageService();
        await storage.saveAuthToken(token);
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_moon, size: 80, color: Colors.indigoAccent),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Smart Pendant',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _handleGoogleSignIn(context),
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}