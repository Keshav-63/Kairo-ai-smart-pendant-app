import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../constants/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _gender = 'Male'; // Default value
  String _userName = '';
  String _userEmail = '';
  String? _userAvatar;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload user data when page comes into view
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final storage = LocalStorageService.instance;
    setState(() {
      _userName = storage.getUserName() ?? 'User';
      _userEmail = storage.getUserEmail() ?? '';
      _userAvatar = storage.getUserAvatar();
      _nameController.text = _userName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: Text('Profile', style: AppTheme.headingMedium),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile Saved! (Demo)')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryAccent),
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryAccent,
                    backgroundImage: _userAvatar != null && _userAvatar!.isNotEmpty
                        ? NetworkImage(_userAvatar!)
                        : null,
                    child: _userAvatar == null || _userAvatar!.isEmpty
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.cardBackground,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Photo upload coming soon!')),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_userEmail.isNotEmpty)
              Center(
                child: Text(
                  _userEmail,
                  style: AppTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 32),
            Text('Name', style: AppTheme.bodyMedium),
            TextField(
              controller: _nameController,
              decoration: AppTheme.inputDecoration(hintText: 'Enter your name'),
            ),
            const SizedBox(height: 24),
            Text('Gender', style: AppTheme.bodyMedium),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Male'),
                    value: 'Male',
                    groupValue: _gender,
                    onChanged: (value) => setState(() => _gender = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Female'),
                    value: 'Female',
                    groupValue: _gender,
                    onChanged: (value) => setState(() => _gender = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Context for Pendant (Your Role)', style: AppTheme.bodyMedium),
            TextField(
              decoration: AppTheme.inputDecoration(hintText: 'e.g., Software Engineering Student'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Text('Daily Tasks', style: AppTheme.bodyMedium),
            TextField(
              decoration: AppTheme.inputDecoration(hintText: 'e.g., Attending lectures, working on projects, team meetings...'),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}