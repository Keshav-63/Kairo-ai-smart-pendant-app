import 'package:flutter/material.dart';
import 'package:smart_pendant_app/services/local_storage_service.dart';
import 'package:smart_pendant_app/services/pendant_api_service.dart';

class WifiSelectionScreen extends StatefulWidget {
  const WifiSelectionScreen({super.key});

  @override
  State<WifiSelectionScreen> createState() => _WifiSelectionScreenState();
}

class _WifiSelectionScreenState extends State<WifiSelectionScreen> {
  bool _isLoading = false;
  final _passwordController = TextEditingController();
  
  // Mock list of Wi-Fi networks. A real app would scan for these.
  final List<String> _mockNetworks = ['MyHomeWiFi', 'Netgear_5G', 'Neighbors_Guest', 'Airtel_Fiber'];

  Future<void> _sendCredentialsToPendant(String ssid, String password) async {
    setState(() { _isLoading = true; });

    final storage = LocalStorageService();
    final api = PendantApiService();

    final userId = await storage.getUserId();

    if (userId == null) {
      _showErrorSnackBar("Error: User ID not found. Please restart the app.");
      return;
    }

    final success = await api.sendWifiCredentials(
      ssid: ssid,
      password: password,
      userId: userId,
    );

    setState(() { _isLoading = false; });
    
    if (success) {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showErrorSnackBar("Failed to connect to pendant. Please try again.");
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showPasswordDialog(String selectedSsid) {
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Password for "$selectedSsid"'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final password = _passwordController.text;
                if (password.isNotEmpty) {
                  Navigator.pop(context);
                  _sendCredentialsToPendant(selectedSsid, password);
                }
              },
              child: const Text('Send to Pendant'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Home Wi-Fi')),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Sending credentials to pendant...'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _mockNetworks.length,
              itemBuilder: (context, index) {
                final ssid = _mockNetworks[index];
                return ListTile(
                  leading: const Icon(Icons.wifi),
                  title: Text(ssid),
                  onTap: () => _showPasswordDialog(ssid),
                );
              },
            ),
    );
  }
}