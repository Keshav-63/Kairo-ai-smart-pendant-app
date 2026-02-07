import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_pendant_app/services/local_storage_service.dart';
import 'package:smart_pendant_app/constants/app_theme.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _userName = 'User';
  String _userEmail = '';
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didUpdateWidget(AppDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload user data when drawer is rebuilt
    _loadUserData();
  }

  void _loadUserData() {
    final storage = LocalStorageService.instance;
    setState(() {
      _userName = storage.getUserName() ?? 'User';
      _userEmail = storage.getUserEmail() ?? '';
      _userAvatar = storage.getUserAvatar();
    });
  }

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
      backgroundColor: AppTheme.secondaryBackground,
      child: Column(
        children: [
          // User header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 48, bottom: 24, left: 16, right: 16),
            decoration: BoxDecoration(color: AppTheme.cardBackground),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryAccent,
                      backgroundImage: _userAvatar != null && _userAvatar!.isNotEmpty
                          ? NetworkImage(_userAvatar!)
                          : null,
                      child: _userAvatar == null || _userAvatar!.isEmpty
                          ? const Icon(Icons.person, size: 30, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: GoogleFonts.oxanium(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_userEmail.isNotEmpty)
                            Text(
                              _userEmail,
                              style: GoogleFonts.oxanium(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.stars_rounded),
                  title: Text('Memories', style: GoogleFonts.oxanium()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/memories');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.task_alt_rounded),
                  title: Text('Tasks & Reminders', style: GoogleFonts.oxanium()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/tasks');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.analytics_rounded),
                  title: Text('Kairo Plus', style: GoogleFonts.oxanium()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/kairo_plus');
                  },
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
                  leading: const Icon(Icons.mic_rounded),
                  title: Text('Recordings', style: GoogleFonts.oxanium()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/recordings');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline_rounded),
                  title: Text('Chat History', style: GoogleFonts.oxanium()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/history');
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
