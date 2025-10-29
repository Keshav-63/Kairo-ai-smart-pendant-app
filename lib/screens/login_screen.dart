// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:url_launcher/url_launcher.dart';

// const List<Color> kGeminiColors = [
//   Color(0xFF4285F4), // Blue
//   Color(0xFF9B72F8), // Purple
//   Color(0xFFF472B6), // Pink
//   Color(0xFFFBBC05), // Yellow
//   Color(0xFF34A853), // Green
//   Color(0xFF4285F4), // Blue again to complete the loop
// ];

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _animationController;
//   late AnimationController _rotationController;
//   late Animation<double> _fadeAnimation;
//   late final AudioPlayer _ambientAudioPlayer;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();

//     _ambientAudioPlayer = AudioPlayer();
//     _playAmbientSound();

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     );

//     _rotationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 4),
//     )..repeat();

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
//     );

//     _animationController.forward();
//   }

//   Future<void> _playAmbientSound() async {
//     try {
//       await _ambientAudioPlayer.setAsset('assets/audio/ui_ambient.mp3');
//       // The audio will now play only once as the loop mode is not set.
//       await _ambientAudioPlayer.play();
//     } catch (e) {
//       debugPrint("Error loading or playing ambient audio: $e");
//     }
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _rotationController.dispose();
//     _ambientAudioPlayer.dispose();
//     super.dispose();
//   }

//   Future<void> _playLoginClickSound() async {
//     // This creates a new player instance to ensure it plays immediately
//     // without interfering with the ambient sound. It's a "fire-and-forget" sound.
//     try {
//       final clickPlayer = AudioPlayer();
//       await clickPlayer.setAsset('assets/audio/login_click.mp3');
//       clickPlayer.play();
//     } catch (e) {
//       debugPrint("Error playing login click sound: $e");
//     }
//   }

//   Future<void> _handleGoogleSignIn() async {
//     await _playLoginClickSound();
//     setState(() => _isLoading = true);
    
//     // Using 'localhost' which is generally more reliable for iOS simulators and can be
//     // forwarded on Android emulators (adb reverse tcp:3001 tcp:3001)
//     final url = Uri.parse('http://localhost:3001/api/auth/google');

//     // Launch the URL. The AuthWrapper will handle the redirect.
//     if (await canLaunchUrl(url)) {
//       await launchUrl(url, mode: LaunchMode.externalApplication);
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch the sign-in page.')),
//         );
//       }
//     }
    
//     if (mounted) {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0D0D12),
//       body: Stack(
//         children: [
//           Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Spacer(flex: 2),
//                 AnimatedBuilder(
//                   animation: _rotationController,
//                   builder: (context, child) {
//                     return Container(
//                       height: 120,
//                       width: 120,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         gradient: SweepGradient(
//                           colors: kGeminiColors,
//                           transform: GradientRotation(
//                               _rotationController.value * 2 * pi),
//                         ),
//                         boxShadow: [
//                           for (int i = 0; i < kGeminiColors.length; i++)
//                             BoxShadow(
//                               color: kGeminiColors[i].withOpacity(0.5),
//                               blurRadius: 20,
//                               spreadRadius: 5 + (i * 2),
//                             ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 30),
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: Text(
//                     'Kairo',
//                     style: GoogleFonts.oxanium(
//                       fontSize: 56,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: Text(
//                     'Your Personal AI Pendant',
//                     style: GoogleFonts.oxanium(
//                       fontSize: 18,
//                       color: Colors.white.withOpacity(0.8),
//                     ),
//                   ),
//                 ),
//                 const Spacer(),
//                 if (_isLoading)
//                   const CircularProgressIndicator()
//                 else
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 50.0),
//                     child: FadeTransition(
//                       opacity: _fadeAnimation,
//                       child: Container(
//                         width: 250,
//                         height: 50,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(25),
//                           color: Colors.white,
//                         ),
//                         child: Material(
//                           color: Colors.transparent,
//                           child: InkWell(
//                             onTap: _handleGoogleSignIn,
//                             borderRadius: BorderRadius.circular(25),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Image.asset(
//                                   'assets/google_logo.png',
//                                   height: 24,
//                                   width: 24,
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Text(
//                                   'Continue with Google',
//                                   style: GoogleFonts.oxanium(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 const Spacer(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late final AudioPlayer _ambientAudioPlayer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _ambientAudioPlayer = AudioPlayer();
    _playAmbientSound();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  Future<void> _playAmbientSound() async {
    try {
      await _ambientAudioPlayer.setAsset('assets/audio/ui_ambient.mp3');
      await _ambientAudioPlayer.play();
    } catch (e) {
      debugPrint("Error loading or playing ambient audio: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ambientAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playLoginClickSound() async {
    try {
      final clickPlayer = AudioPlayer();
      await clickPlayer.setAsset('assets/audio/login_click.mp3');
      clickPlayer.play();
    } catch (e) {
      debugPrint("Error playing login click sound: $e");
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await _playLoginClickSound();
    setState(() => _isLoading = true);

    final url = Uri.parse('http://localhost:3001/api/auth/google');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch the sign-in page.')),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Plain logo (NOT enclosed in a circle). Use assets/kairo-logo.png
            SizedBox(
              height: 120,
              child: Image.asset(
                'assets/kairo-logo.png',
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 30),

            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Kairo',
                style: GoogleFonts.oxanium(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Your Personal AI Pendant',
                style: GoogleFonts.oxanium(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),

            const Spacer(),

            if (_isLoading)
              const CircularProgressIndicator()
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 250,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.white,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleGoogleSignIn,
                        borderRadius: BorderRadius.circular(25),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google_logo.png',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: GoogleFonts.oxanium(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}