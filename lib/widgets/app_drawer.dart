import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_pendant_app/services/local_storage_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // Method to handle the logout process
  Future<void> _handleLogout(BuildContext context) async {
    // 1. Clear all stored credentials and user data
    final storage = LocalStorageService.instance;
    await storage.clearAllData();

    // 2. Navigate back to the login screen, removing all previous routes
    if (context.mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(
          0xFF1E1E24), // A slightly lighter dark color for the drawer
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF0D0D12)),
                  child: Text(
                    'Kairo',
                    style: GoogleFonts.oxanium(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.wifi_find_rounded),
                  title:
                      Text('Change Home Wi-Fi', style: GoogleFonts.oxanium()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/change_wifi');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.record_voice_over_rounded),
                  title:
                      Text('Manage User Voices', style: GoogleFonts.oxanium()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/manage_voices');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title:
                      Text('Previous Recordings', style: GoogleFonts.oxanium()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/previous_recordings');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_rounded),
                  title: Text('Google Drive', style: GoogleFonts.oxanium()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/drive_files');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: Text('Google Calendar', style: GoogleFonts.oxanium()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/calendar_events');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.stars_rounded),
                  title: Text('Memories', style: GoogleFonts.oxanium()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/memories');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text('Profile', style: GoogleFonts.oxanium()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text('Settings', style: GoogleFonts.oxanium()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
            ),
          ),
          // This ensures the logout button is always at the bottom
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text('Logout',
                style: GoogleFonts.oxanium(color: Colors.redAccent)),
            onTap: () => _handleLogout(context),
          ),
          const SizedBox(height: 20), // Some padding at the bottom
        ],
      ),
    );
  }
}
