import 'dart:async';
import 'package:flutter/material.dart';

// (The VoiceProfile class is the same as before)
class VoiceProfile {
  final String name;
  final String relationship;
  VoiceProfile({required this.name, required this.relationship});
}

class ManageVoicesScreen extends StatefulWidget {
  const ManageVoicesScreen({super.key});
  @override
  State<ManageVoicesScreen> createState() => _ManageVoicesScreenState();
}

class _ManageVoicesScreenState extends State<ManageVoicesScreen> {
  final List<VoiceProfile> _profiles = [];
  bool _isCalibrating = false;
  bool _isRecording = false;
  String _generatedSentence = "";
  VoiceProfile? _newProfile;
  double _calibrationProgress = 0.0;
  final List<String> _sentences = [
    "The quick brown fox jumps over the lazy dog.",
    "Never underestimate the power of a good book.",
    "Technology has changed the way we live and work.",
    "The sun always shines brightest after the rain."
  ];

  void _startCalibration(VoiceProfile profile) { // (Logic is same)
    setState(() {
      _newProfile = profile;
      _isCalibrating = true;
      _calibrationProgress = 0.0;
      _generatedSentence = (_sentences..shuffle()).first;
    });
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_calibrationProgress >= 1.0) {
        timer.cancel();
        setState(() {
          _isCalibrating = false;
          _isRecording = true;
        });
      } else {
        setState(() {
          _calibrationProgress += 0.01;
        });
      }
    });
  }

  void _saveRecording() { // (Logic is same)
    setState(() => _isRecording = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (_newProfile != null) {
        setState(() {
          _profiles.add(_newProfile!);
          _isRecording = false;
          _newProfile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // THEME UPDATE applied to all 3 views below
  Widget _buildListView() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Manage User Voices')),
      body: _profiles.isEmpty
          ? const Center(child: Text('No voice profiles added yet.'))
          : ListView.builder(
              itemCount: _profiles.length,
              itemBuilder: (context, index) {
                final profile = _profiles[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(profile.name),
                  subtitle: Text(profile.relationship),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVoiceDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalibrationView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Calibrating voice for ${_newProfile?.name}...',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              LinearProgressIndicator(value: _calibrationProgress, minHeight: 10),
              const SizedBox(height: 30),
              const Text(
                'Please wait while we generate a unique sentence for you.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Please say the following sentence clearly:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              Text(
                '"$_generatedSentence"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontStyle: FontStyle.italic, color: Colors.indigoAccent),
              ),
              const SizedBox(height: 50),
              IconButton(
                onPressed: _saveRecording,
                icon: const Icon(Icons.mic),
                iconSize: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 10),
              const Text('Tap to Record'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) { // (Logic is same)
    if (_isCalibrating) return _buildCalibrationView();
    if (_isRecording) return _buildRecordingView();
    return _buildListView();
  }

  Future<void> _showAddVoiceDialog(BuildContext context) { // (Dialog is same)
    final nameController = TextEditingController();
    String? selectedRelationship = 'Friend';
    final relationships = ['Brother', 'Sister', 'Mother', 'Father', 'Friend', 'Other'];
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Voice Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedRelationship,
                items: relationships.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => selectedRelationship = newValue,
                decoration: const InputDecoration(labelText: 'Relationship'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text;
                if (name.isNotEmpty && selectedRelationship != null) {
                  Navigator.pop(context);
                  _startCalibration(VoiceProfile(name: name, relationship: selectedRelationship!));
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}