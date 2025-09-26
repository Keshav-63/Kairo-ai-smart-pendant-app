import 'package:flutter/material.dart';
import 'package:smart_pendant_app/services/local_storage_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    // --- MOCK LOGIN ---
    // In a real app, you would use the google_sign_in package here.
    final String mockUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    // Save the userId locally BEFORE moving to the next step.
    final storage = LocalStorageService();
    await storage.saveUserId(mockUserId);

    print('Mock login successful. UserID: $mockUserId saved locally.');

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding');
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