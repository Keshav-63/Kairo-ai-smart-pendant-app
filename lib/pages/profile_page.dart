import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _gender = 'Male'; // Default value

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // THEME UPDATE
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile Saved! (Demo)')),
              );
            },
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
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.indigoAccent,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade800,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20),
                        onPressed: () {}, // Dummy upload action
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Name', style: TextStyle(color: Colors.white70)),
            const TextField(
              decoration: InputDecoration(hintText: 'Aniruddha Yadav'),
            ),
            const SizedBox(height: 24),
            const Text('Gender', style: TextStyle(color: Colors.white70)),
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
            const Text('Context for Pendant (Your Role)', style: TextStyle(color: Colors.white70)),
            const TextField(
              decoration: InputDecoration(hintText: 'e.g., Software Engineering Student'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const Text('Daily Tasks', style: TextStyle(color: Colors.white70)),
            const TextField(
              decoration: InputDecoration(hintText: 'e.g., Attending lectures, working on projects, team meetings...'),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}