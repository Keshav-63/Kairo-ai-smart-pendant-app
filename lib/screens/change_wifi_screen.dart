import 'package:flutter/material.dart';

class ChangeWifiScreen extends StatelessWidget {
  ChangeWifiScreen({super.key});

  final List<String> _mockNetworks = [
    'JioFiber_Virar',
    'Airtel_Xstream_2.4Ghz',
    'Tata_Play_Fiber',
    'BSNL_Fiber_Link',
    'MyHomeWiFi_5G'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // THEME UPDATE
      appBar: AppBar(
        title: const Text('Change Home Wi-Fi'),
      ),
      body: ListView.builder(
        itemCount: _mockNetworks.length,
        itemBuilder: (context, index) {
          final ssid = _mockNetworks[index];
          return ListTile(
            leading: const Icon(Icons.wifi),
            title: Text(ssid),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Connecting to $ssid...'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
      ),
    );
  }
}