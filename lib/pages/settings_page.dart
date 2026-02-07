import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: Text('Settings', style: AppTheme.headingMedium),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.wifi),
            title: const Text('Change Pendant Wi-Fi'),
            onTap: () {
              Navigator.pushNamed(context, '/change_wifi');
            },
          ),
          ListTile(
            leading: const Icon(Icons.power_settings_new),
            title: const Text('Reboot Your Device'),
            onTap: () {
              // Dummy reboot confirmation
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reboot Pendant'),
                  content: const Text('Are you sure you want to reboot your device?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Reboot')),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('Delete Your Account', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              // Dummy delete confirmation
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text('This action is permanent and cannot be undone. Are you sure?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}