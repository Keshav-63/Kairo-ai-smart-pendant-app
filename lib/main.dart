import 'package:flutter/material.dart';
import 'package:smart_pendant_app/pages/profile_page.dart';
import 'package:smart_pendant_app/pages/search_page.dart';
import 'package:smart_pendant_app/screens/drive_files_screen.dart';
import 'package:smart_pendant_app/screens/calendar_events_screen.dart';
import 'package:smart_pendant_app/screens/change_wifi_screen.dart';
import 'package:smart_pendant_app/screens/login_screen.dart';
import 'package:smart_pendant_app/screens/manage_voices_screen.dart';
import 'package:smart_pendant_app/screens/previous_recordings_screen.dart';
import 'package:smart_pendant_app/screens/qr_scanner_screen.dart';
import 'package:smart_pendant_app/screens/wifi_selection_screen.dart';
import 'package:smart_pendant_app/screens/onboarding_carousel_screen.dart'; // Add this import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Pendant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigoAccent,
            foregroundColor: Colors.white,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/onboarding': (context) => const OnboardingCarouselScreen(), // Add this new route
        '/qr_scan': (context) => const QrScannerScreen(),
        '/wifi_selection': (context) => const WifiSelectionScreen(),
        '/home': (context) => const SearchPage(),
        '/profile': (context) => const ProfilePage(),
        '/change_wifi': (context) => ChangeWifiScreen(),
        '/manage_voices': (context) => const ManageVoicesScreen(),
        '/previous_recordings': (context) => PreviousRecordingsScreen(),
        '/drive_files': (context) => const DriveFilesScreen(),
        '/calendar_events': (context) => const CalendarEventsScreen(),
      },
    );
  }
}