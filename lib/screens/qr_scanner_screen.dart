import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:smart_pendant_app/services/local_storage_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;
  String _statusMessage = 'Position the QR code inside the frame';

  @override
  void dispose() {
    debugPrint("[QrScannerScreen] Disposing of scanner controller.");
    _scannerController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    debugPrint("[QrScannerScreen] Showing error dialog: $message");
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text('Connection Failed', style: GoogleFonts.oxanium()),
        content: Text(message, style: GoogleFonts.oxanium()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                debugPrint("[QrScannerScreen] Resetting state after error.");
                _isProcessing = false;
                _statusMessage = 'Position the QR code inside the frame';
              });
            },
            child: Text('Try Again', style: GoogleFonts.oxanium(color: const Color(0xFF4285F4))),
          ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final String? qrCodeData = capture.barcodes.first.rawValue;

    if (qrCodeData == null) {
      debugPrint("[QrScannerScreen] QR code detected, but rawValue is null.");
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _statusMessage = 'QR Code Detected! Processing...';
    });
    debugPrint("[QrScannerScreen] QR Data: $qrCodeData");

    try {
      debugPrint("[QrScannerScreen] Fetching userId from local storage...");
      final storage = LocalStorageService.instance;
      final userId = storage.getUserId();
      if (userId == null) {
        throw Exception("User ID not found. Please log in again.");
      }
      debugPrint("[QrScannerScreen] Found userId: $userId");

      final parts = qrCodeData.split(';');
      final ssidPart = parts.firstWhere((p) => p.startsWith('WIFI:S:'), orElse: () => '');
      final passwordPart = parts.firstWhere((p) => p.startsWith('P:'), orElse: () => '');

      if (ssidPart.isEmpty || passwordPart.isEmpty) {
        throw const FormatException('Invalid QR code format for Wi-Fi credentials.');
      }

      final ssid = ssidPart.substring(7);
      final password = passwordPart.substring(2);
      
      debugPrint("[QrScannerScreen] Parsed Pendant Hotspot -> SSID: $ssid, Password: [REDACTED]");
      
      setState(() {
        _statusMessage = 'Connecting to Kairo Hotspot...';
      });

      await WiFiForIoTPlugin.forceWifiUsage(true);
      debugPrint("[QrScannerScreen] Forcing Wi-Fi usage.");

      final isConnected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA,
        withInternet: false,
      );
      
      debugPrint("[QrScannerScreen] Connection attempt finished. Result: $isConnected");

      if (isConnected) {
        debugPrint("[QrScannerScreen] Successfully connected to Kairo hotspot. Navigating to /wifi_selection...");
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/wifi_selection', arguments: userId);
        }
      } else {
        _showErrorDialog(
          'Could not connect to the Kairo hotspot. Please reset the pendant by unplugging it and plugging it back in, then scan the code again.',
        );
      }
    } catch (e) {
      debugPrint("[QrScannerScreen] CRITICAL ERROR during QR processing: $e");
      _showErrorDialog(
        'The QR code seems invalid or an error occurred. Please ensure you are scanning the correct code and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        title: Text('Connect to Kairo', style: GoogleFonts.oxanium(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.oxanium(fontSize: 18, color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 30),
            Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                border: Border.all(color: _isProcessing ? Colors.grey.shade700 : const Color(0xFF4285F4), width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_isProcessing)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
              ),
          ],
        ),
      ),
    );
  }
}