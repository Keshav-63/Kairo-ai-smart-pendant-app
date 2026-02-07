// import 'package:flutter/material.dart';
// import 'package:smart_pendant_app/pages/profile_page.dart';
// import 'package:smart_pendant_app/pages/search_page.dart';
// import 'package:smart_pendant_app/screens/auth_wrapper.dart'; // Import the new wrapper
// import 'package:smart_pendant_app/screens/drive_files_screen.dart';
// import 'package:smart_pendant_app/screens/calendar_events_screen.dart';
// import 'package:smart_pendant_app/screens/change_wifi_screen.dart';
// import 'package:smart_pendant_app/screens/login_screen.dart';
// import 'package:smart_pendant_app/screens/manage_voices_screen.dart';
// import 'package:smart_pendant_app/screens/previous_recordings_screen.dart';
// import 'package:smart_pendant_app/screens/qr_scanner_screen.dart';
// import 'package:smart_pendant_app/screens/wifi_selection_screen.dart';
// import 'package:smart_pendant_app/screens/onboarding_carousel_screen.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Smart Pendant',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.indigo,
//         brightness: Brightness.dark,
//         scaffoldBackgroundColor: Colors.black,
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.indigoAccent,
//             foregroundColor: Colors.white,
//           ),
//         ),
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//         ),
//       ),
//       // Set the initial route to the AuthWrapper
//       initialRoute: '/',
//       routes: {
//         '/': (context) => const AuthWrapper(), // Add the wrapper route
//         '/login': (context) => const LoginScreen(),
//         '/onboarding': (context) => const OnboardingCarouselScreen(),
//         '/qr_scan': (context) => const QrScannerScreen(),
//         '/wifi_selection': (context) => const WifiSelectionScreen(),
//         '/home': (context) => const SearchPage(),
//         '/profile': (context) => const ProfilePage(),
//         '/change_wifi': (context) => ChangeWifiScreen(),
//         '/manage_voices': (context) => const ManageVoicesScreen(),
//         '/previous_recordings': (context) => PreviousRecordingsScreen(),
//         '/drive_files': (context) => const DriveFilesScreen(),
//         '/calendar_events': (context) => const CalendarEventsScreen(),
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_pendant_app/pages/profile_page.dart';
import 'package:smart_pendant_app/pages/search_page.dart';
import 'package:smart_pendant_app/screens/auth_wrapper.dart';
import 'package:smart_pendant_app/screens/drive_files_screen.dart';
import 'package:smart_pendant_app/screens/calendar_events_screen.dart';
import 'package:smart_pendant_app/screens/change_wifi_screen.dart';
import 'package:smart_pendant_app/screens/login_screen.dart';
import 'package:smart_pendant_app/screens/manage_voices_screen.dart';
import 'package:smart_pendant_app/screens/previous_recordings_screen.dart';
import 'package:smart_pendant_app/screens/qr_scanner_screen.dart';
import 'package:smart_pendant_app/screens/wifi_selection_screen.dart';
import 'package:smart_pendant_app/screens/onboarding_carousel_screen.dart';
import 'package:smart_pendant_app/screens/memories_screen.dart';
import 'package:smart_pendant_app/services/local_storage_service.dart';

void main() async {
  // CRITICAL FIX: Ensures that plugin services are initialized before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the storage service once when the app starts.
  await LocalStorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kairo Smart Pendant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.indigoAccent,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigoAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      initialRoute: '/wrapper',
      routes: {
        '/wrapper': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/onboarding': (context) => const OnboardingCarouselScreen(),
        '/home': (context) => const SearchPage(),
        '/qr_scan': (context) => const QrScannerScreen(),
        '/wifi_selection': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String?;
          if (userId == null) {
            return const LoginScreen();
          }
          return WifiSelectionScreen(userId: userId);
        },
        '/profile': (context) => const ProfilePage(),
        '/change_wifi': (context) => ChangeWifiScreen(),
        '/manage_voices': (context) => const ManageVoicesScreen(),
        '/previous_recordings': (context) => PreviousRecordingsScreen(),
        '/drive_files': (context) => const DriveFilesScreen(),
        '/calendar_events': (context) => const CalendarEventsScreen(),
        '/memories': (context) => const MemoriesScreen(),
      },
    );
  }
}
