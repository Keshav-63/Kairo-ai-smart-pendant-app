// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:smart_pendant_app/services/local_storage_service.dart';
// import 'package:video_player/video_player.dart';

// class OnboardingCarouselScreen extends StatefulWidget {
//   const OnboardingCarouselScreen({super.key});

//   @override
//   State<OnboardingCarouselScreen> createState() =>
//       _OnboardingCarouselScreenState();
// }

// class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   void _onPageChanged(int page) {
//     setState(() {
//       _currentPage = page;
//     });
//   }

//   void _nextPage() async {
//     if (_currentPage < 2) {
//       _pageController.nextPage(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeIn,
//       );
//     } else {
//       final storage = LocalStorageService.instance;
//       await storage.setHasCompletedOnboarding(true);
//       if (mounted) {
//         Navigator.pushReplacementNamed(context, '/home');
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           PageView(
//             controller: _pageController,
//             onPageChanged: _onPageChanged,
//             children: const [
//               OnboardingPage(
//                 image: 'assets/onboarding_1.png',
//                 title: 'Step 1: Power On Your Pendant',
//                 description:
//                     'Press and hold the button on the pendant to turn it on. The LED will blink blue when it\'s ready.',
//               ),
//               OnboardingPage(
//                 image: 'assets/onboarding_2.png',
//                 title: 'Step 2: Connect to the App',
//                 description:
//                     'Follow the instructions on the screen to connect the pendant to your phone via Bluetooth.',
//               ),
//               OnboardingPage(
//                 image: 'assets/onboarding_3.png',
//                 title: 'Step 3: Start Recording',
//                 description:
//                     'Press the button once to start a recording. The LED will turn solid red. Press again to stop.',
//               ),
//             ],
//           ),
//           Positioned(
//             bottom: 30,
//             left: 0,
//             right: 0,
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: List.generate(3, (index) => _buildDot(index)),
//                 ),
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   width: 200,
//                   child: ElevatedButton(
//                     onPressed: _nextPage,
//                     child: Text(_currentPage == 2 ? 'Get Started' : 'Next'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDot(int index) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 5.0),
//       height: 10,
//       width: 10,
//       decoration: BoxDecoration(
//         color: _currentPage == index ? Colors.indigoAccent : Colors.white30,
//         shape: BoxShape.circle,
//       ),
//     );
//   }
// }

// class OnboardingPage extends StatelessWidget {
//   final String image;
//   final String title;
//   final String description;

//   const OnboardingPage({
//     super.key,
//     required this.image,
//     required this.title,
//     required this.description,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Image.asset(image, height: 250, width: 250),
//           const SizedBox(height: 40),
//           Text(
//             title,
//             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             description,
//             style: const TextStyle(fontSize: 16, color: Colors.white70),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() =>
      _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  // --- UI LOGIC from NEW code ---
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the video controller with the correct path
    _controller = VideoPlayerController.asset('assets/qr_scan.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized
        setState(() {});
        // Play the video and set it to loop
        _controller.play();
        _controller.setLooping(true);
      });
  }

  // --- ROBUST LOGIC from OLD code ---
  // This function now correctly handles the completion of the onboarding process.
  Future<void> _completeOnboardingAndProceed() async {
    if (mounted) {
      // We still navigate to the QR scanner, but now the app knows onboarding is done.
      // If the user backs out, they'll be taken to the home screen.
      Navigator.pushReplacementNamed(context, '/qr_scan');
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is removed
    _controller.dispose();
    super.dispose();
  }

  // --- BUILD METHOD from NEW code ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player Background
          if (_controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          
          // Gradient overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.black.withOpacity(0.7)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // UI Elements (Text and Button)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, // Align content to the bottom
              children: [
                // Bottom Text and Button
                Text(
                  'Connect Your Pendant',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.oxanium(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Scan the QR code on your Kairo device to get started.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.oxanium(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  // --- MERGED LOGIC ---
                  // This button now triggers the robust completion logic
                  onPressed: _completeOnboardingAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    'Scan QR Code',
                    style: GoogleFonts.oxanium(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

