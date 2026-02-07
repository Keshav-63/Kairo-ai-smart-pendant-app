// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:app_links/app_links.dart';
// import 'package:smart_pendant_app/services/local_storage_service.dart';
// import 'package:flutter/foundation.dart'; // For debugPrint
// import 'package:smart_pendant_app/screens/login_screen.dart';
// import 'package:smart_pendant_app/screens/onboarding_carousel_screen.dart';
// import 'package:smart_pendant_app/pages/search_page.dart'; // This is the home page

// // Enum to represent the different authentication states.
// enum AuthStatus { checking, authenticated, unauthenticated }

// class AuthWrapper extends StatefulWidget {
//   const AuthWrapper({super.key});

//   @override
//   State<AuthWrapper> createState() => _AuthWrapperState();
// }

// class _AuthWrapperState extends State<AuthWrapper> {
//   final _appLinks = AppLinks();
//   StreamSubscription<Uri>? _linkSubscription;
//   AuthStatus _authStatus = AuthStatus.checking;
//   bool _hasCompletedOnboarding = false;

//   @override
//   void initState() {
//     super.initState();
//     _initAuthCheckAndDeepLinks();
//   }

//   @override
//   void dispose() {
//     _linkSubscription?.cancel();
//     super.dispose();
//   }

//   /// Initializes deep link listeners and checks for an existing session.
//   Future<void> _initAuthCheckAndDeepLinks() async {
//     debugPrint("[AuthWrapper] Initializing auth check and deep link listener...");

//     // Listen for incoming links when the app is already running.
//     _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
//       debugPrint("[AuthWrapper] Received a deep link while app is running: $uri");
//       if (uri.host == 'auth-success') {
//         _handleAuthRedirect(uri);
//       }
//     });

//     // Check for an initial link that launched the app from a terminated state.
//     try {
//       final initialUri = await _appLinks.getInitialLink();
//       if (initialUri != null) {
//         debugPrint("[AuthWrapper] App was opened by an initial deep link: $initialUri");
//         if (initialUri.host == 'auth-success') {
//           await _handleAuthRedirect(initialUri);
//           return; // Auth flow will handle state update, no need to check storage.
//         }
//       }
//     } catch (e) {
//       debugPrint("[AuthWrapper] Could not get initial link: $e");
//     }

//     // If no deep link was handled, check for a stored token.
//     await _checkStoredToken();
//   }

//   /// Checks local storage for a valid auth token to determine if the user is already logged in.
//   Future<void> _checkStoredToken() async {
//     final storage = LocalStorageService.instance;
//     final token = storage.getAuthToken();
//     debugPrint("[AuthWrapper] Checking stored token... ${token != null && token.isNotEmpty ? "found" : "not found"}");

//     if (token != null && token.isNotEmpty) {
//       final hasCompleted = storage.hasCompletedOnboarding();
//       debugPrint("[AuthWrapper] Existing user session found. Onboarding completed: $hasCompleted");
//       if (mounted) {
//         setState(() {
//           _hasCompletedOnboarding = hasCompleted;
//           _authStatus = AuthStatus.authenticated;
//         });
//       }
//     } else {
//       debugPrint("[AuthWrapper] No valid token found, setting state to unauthenticated.");
//       if (mounted) {
//         setState(() {
//           _authStatus = AuthStatus.unauthenticated;
//         });
//       }
//     }
//   }

//   /// Handles the incoming deep link from the OAuth callback.
//   Future<void> _handleAuthRedirect(Uri uri) async {
//     debugPrint("[AuthWrapper] Handling auth redirect URI: $uri");
//     final token = uri.queryParameters['token'];
//     final userId = uri.queryParameters['userId'];
//     final isNewUser = uri.queryParameters['isNewUser'] == 'true';

//     if (token != null && userId != null && token.isNotEmpty && userId.isNotEmpty) {
//       debugPrint("[AuthWrapper] Token and userId are valid. Saving to storage.");
//       final storage = LocalStorageService.instance;
//       await storage.saveAuthToken(token);
//       await storage.saveUserId(userId);

//       // A user needs to onboard if they are new, OR if they are an existing
//       // user who never finished the onboarding process.
//       final bool needsOnboarding = isNewUser || !storage.hasCompletedOnboarding();
      
//       if (isNewUser) {
//         await storage.setHasCompletedOnboarding(false);
//       }
      
//       if (mounted) {
//         setState(() {
//           _hasCompletedOnboarding = !needsOnboarding;
//           _authStatus = AuthStatus.authenticated;
//         });
//       }

//     } else {
//       debugPrint("[AuthWrapper] Auth redirect failed: token or userId is missing. Setting state to unauthenticated.");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Authentication failed. Please try again.')),
//         );
//         setState(() {
//           _authStatus = AuthStatus.unauthenticated;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This widget now builds the correct screen based on the auth status,
//     // ensuring it stays in the widget tree to listen for deep links.
//     switch (_authStatus) {
//       case AuthStatus.checking:
//         return const Scaffold(
//           backgroundColor: Color(0xFF0D0D12),
//           body: Center(
//             child: CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//           ),
//         );
//       case AuthStatus.unauthenticated:
//         return const LoginScreen();
//       case AuthStatus.authenticated:
//         if (_hasCompletedOnboarding) {
//           return const SearchPage(); // The main home page
//         } else {
//           return const OnboardingCarouselScreen();
//         }
//     }
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:smart_pendant_app/services/local_storage_service.dart';
// For debugPrint
import 'package:smart_pendant_app/screens/login_screen.dart';
import 'package:smart_pendant_app/screens/onboarding_carousel_screen.dart';
import 'package:smart_pendant_app/pages/search_page.dart'; // This is the home page

// Enum to represent the different authentication states.
enum AuthStatus { checking, authenticated, unauthenticated }

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  AuthStatus _authStatus = AuthStatus.checking;
  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    debugPrint("[AuthWrapper] initState: Initializing auth check and deep links.");
    _initAuthCheckAndDeepLinks();
  }

  @override
  void dispose() {
    debugPrint("[AuthWrapper] dispose: Cancelling deep link subscription.");
    _linkSubscription?.cancel();
    super.dispose();
  }

  /// Initializes deep link listeners and checks for an existing session.
  Future<void> _initAuthCheckAndDeepLinks() async {
    debugPrint("[AuthWrapper] _initAuthCheckAndDeepLinks: Setting up deep link listener...");

    // Listen for incoming links when the app is already running.
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint("[AuthWrapper] DEEP LINK RECEIVED: $uri");
      if (uri.host == 'auth-success' && mounted) {
        _handleAuthRedirect(uri);
      }
    });

    // Check for an initial link that launched the app from a terminated state.
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && mounted) {
        debugPrint("[AuthWrapper] INITIAL DEEP LINK: $initialUri");
        if (initialUri.host == 'auth-success') {
          await _handleAuthRedirect(initialUri);
          return; // Auth flow will handle state update.
        }
      }
    } catch (e) {
      debugPrint("[AuthWrapper] ERROR getting initial link: $e");
    }

    // If no deep link was handled, check for a stored token.
    await _checkStoredToken();
  }

  /// Checks local storage for a valid auth token to determine if the user is already logged in.
  Future<void> _checkStoredToken() async {
    debugPrint("[AuthWrapper] _checkStoredToken: Checking local storage for token...");
    final storage = LocalStorageService.instance;
    final token = storage.getAuthToken();
    
    // Small delay to prevent race conditions during fast re-authentication
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      final currentToken = storage.getAuthToken();
      if (currentToken != null && currentToken.isNotEmpty) {
        final hasCompleted = storage.hasCompletedOnboarding();
        debugPrint("[AuthWrapper] _checkStoredToken: Token found. Onboarding completed: $hasCompleted");
        setState(() {
          _hasCompletedOnboarding = hasCompleted;
          _authStatus = AuthStatus.authenticated;
        });
      } else {
        debugPrint("[AuthWrapper] _checkStoredToken: No valid token found. Setting state to unauthenticated.");
        setState(() {
          _authStatus = AuthStatus.unauthenticated;
        });
      }
    }
  }

  /// Handles the incoming deep link from the OAuth callback.
  Future<void> _handleAuthRedirect(Uri uri) async {
    debugPrint("[AuthWrapper] _handleAuthRedirect: Processing auth URI: $uri");
    final token = uri.queryParameters['token'];
    final userId = uri.queryParameters['userId'];
    final isNewUser = uri.queryParameters['isNewUser'] == 'true';

    if (token != null && userId != null && token.isNotEmpty && userId.isNotEmpty) {
      debugPrint("[AuthWrapper] _handleAuthRedirect: Token and userId are valid. Saving...");
      final storage = LocalStorageService.instance;
      await storage.saveAuthToken(token);
      await storage.saveUserId(userId);
      debugPrint("[AuthWrapper] _handleAuthRedirect: Token and userId saved.");

      final bool needsOnboarding = isNewUser || !storage.hasCompletedOnboarding();
      
      if (isNewUser) {
        await storage.setHasCompletedOnboarding(false);
      }
      
      if (mounted) {
        debugPrint("[AuthWrapper] _handleAuthRedirect: Setting state to AUTHENTICATED.");
        setState(() {
          _hasCompletedOnboarding = !needsOnboarding;
          _authStatus = AuthStatus.authenticated;
        });
      }

    } else {
      debugPrint("[AuthWrapper] _handleAuthRedirect: Auth failed. Token or userId is missing.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed. Please try again.')),
        );
        setState(() {
          _authStatus = AuthStatus.unauthenticated;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("[AuthWrapper] build: Current auth status is $_authStatus");
    switch (_authStatus) {
      case AuthStatus.checking:
        return const Scaffold(
          backgroundColor: Color(0xFF0D0D12),
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        if (_hasCompletedOnboarding) {
          return const SearchPage(); // The main home page
        } else {
          return const OnboardingCarouselScreen();
        }
    }
  }
}