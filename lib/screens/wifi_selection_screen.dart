import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_pendant_app/services/pendant_api_service.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_pendant_app/services/local_storage_service.dart';

class WifiSelectionScreen extends StatefulWidget {
  final String userId;
  const WifiSelectionScreen({super.key, required this.userId});

  @override
  State<WifiSelectionScreen> createState() => _WifiSelectionScreenState();
}

class _WifiSelectionScreenState extends State<WifiSelectionScreen> {
  final PendantApiService _pendantApi = PendantApiService();
  List<WifiNetwork>? _wifiNetworks;
  bool _isScanning = true;
  bool _isProvisioning = false;
  String? _provisioningStatus;

  @override
  void initState() {
    super.initState();
    debugPrint("[WifiSelectionScreen] Initialized with userId: ${widget.userId}");
    _scanForNetworks();
  }

  Future<void> _scanForNetworks() async {
    debugPrint("[WifiSelectionScreen] Starting Wi-Fi network scan...");
    setState(() => _isScanning = true);
    try {
      final networks = await _pendantApi.getNearbyWifiNetworks();
      debugPrint("[WifiSelectionScreen] Found ${networks.length} networks.");
      final uniqueNetworks = <String, WifiNetwork>{};
      for (var network in networks) {
        if (network.ssid != null && network.ssid!.isNotEmpty) {
          uniqueNetworks[network.ssid!] = network;
        }
      }
      setState(() {
        _wifiNetworks = uniqueNetworks.values.toList();
        _isScanning = false;
      });
      debugPrint("[WifiSelectionScreen] Scan complete. Displaying ${_wifiNetworks?.length ?? 0} unique networks.");
    } catch (e) {
      debugPrint("[WifiSelectionScreen] CRITICAL ERROR scanning for networks: $e");
      setState(() => _isScanning = false);
      _showErrorDialog("Could not scan for Wi-Fi networks. Please ensure location services are enabled and try again.");
    }
  }

  Future<void> _provisionPendant(String ssid, String password) async {
    setState(() {
      _isProvisioning = true;
      _provisioningStatus = 'Sending credentials to Kairo...';
    });
    debugPrint("[WifiSelectionScreen] Starting provisioning for SSID: $ssid");

    final success = await _pendantApi.provisionDevice(
      ssid: ssid,
      password: password,
      userId: widget.userId,
    );

    debugPrint("[WifiSelectionScreen] Provisioning attempt finished. Result: $success");

    if (success) {
      setState(() {
        _provisioningStatus = 'Kairo is connecting to your Wi-Fi...';
      });
      // CRITICAL: Set the onboarding complete flag HERE.
      final storage = LocalStorageService.instance;
      await storage.setHasCompletedOnboarding(true);
      debugPrint("[WifiSelectionScreen] Onboarding complete flag set to true.");
      debugPrint("[WifiSelectionScreen] Disconnecting from hotspot and re-enabling mobile data.");
      await WiFiForIoTPlugin.disconnect();
      await WiFiForIoTPlugin.forceWifiUsage(false);
      
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        debugPrint("[WifiSelectionScreen] Navigating to /home.");
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      setState(() => _isProvisioning = false);
      _showErrorDialog("Failed to configure Kairo. Please check your Wi-Fi password and try again.");
    }
  }
  
  void _showPasswordDialog(String selectedSsid) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text('Enter Password for "$selectedSsid"', style: GoogleFonts.oxanium()),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.oxanium()),
          ),
          ElevatedButton(
            onPressed: () {
              final password = passwordController.text;
              if (password.isNotEmpty) {
                Navigator.pop(context);
                _provisionPendant(selectedSsid, password);
              }
            },
            child: const Text('Connect Kairo'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
     debugPrint("[WifiSelectionScreen] Showing error dialog: $message");
     if (!mounted) return;
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
         title: Text('Error', style: GoogleFonts.oxanium()),
         content: Text(message, style: GoogleFonts.oxanium()),
         actions: [
           TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: Text('OK', style: GoogleFonts.oxanium(color: const Color(0xFF4285F4))),
           ),
         ],
       ),
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        title: Text('Select Your Home Wi-Fi', style: GoogleFonts.oxanium()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning || _isProvisioning ? null : _scanForNetworks,
          )
        ],
      ),
      body: _isProvisioning
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    _provisioningStatus ?? 'Configuring Kairo...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oxanium(fontSize: 16),
                  ),
                ],
              ),
            )
          : _isScanning
              ? const Center(child: CircularProgressIndicator())
              : _wifiNetworks == null || _wifiNetworks!.isEmpty
                  ? Center(
                      child: Text(
                        'No Wi-Fi networks found.\nEnsure Wi-Fi and Location are enabled.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.oxanium(),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _wifiNetworks!.length,
                      itemBuilder: (context, index) {
                        final network = _wifiNetworks![index];
                        if (network.ssid == null || network.ssid!.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          leading: const Icon(Icons.wifi),
                          title: Text(network.ssid!, style: GoogleFonts.oxanium()),
                          onTap: () => _showPasswordDialog(network.ssid!),
                        );
                      },
                    ),
    );
  }
}