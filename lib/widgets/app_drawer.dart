import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            child: Text('Smart Pendant', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.wifi),
            title: const Text('Change Home Wi-Fi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/change_wifi');
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Manage User Voices'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/manage_voices');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Previous Recordings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/previous_recordings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
                    ListTile(
            leading: const Icon(Icons.drive_eta),
            title: const Text('Google Drive'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/drive_files');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Google Calendar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/calendar_events');
            },
          ),
        ],
      ),
    );
  }
}