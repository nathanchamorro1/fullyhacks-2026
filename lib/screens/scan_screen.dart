// ScanScreen — opens the camera, listens for barcodes, hits Open Food Facts,
// then navigates to the results screen with the resolved Product.
//
// Notes for first-time Flutter folks:
// - StatefulWidget: a widget that has mutable state (the scanner controller,
//   loading flag, last-seen barcode for debounce).
// - The scanner can fire the same barcode many times per second while it's in
//   view. We guard with `_isHandling` + `_lastBarcode` so we only process once.
// - We `dispose()` the scanner controller to free the camera. Without this,
//   the camera can stay locked when leaving the screen.

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/product.dart';
import '../services/open_food_facts_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
    ],
  );
  final OpenFoodFactsService _off = OpenFoodFactsService();

  bool _isHandling = false;
  String? _lastBarcode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isHandling) return;

    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null || code == _lastBarcode) return;

    setState(() {
      _isHandling = true;
      _lastBarcode = code;
    });

    // Pause the camera while we look up the product.
    await _controller.stop();

    try {
      final Product? product = await _off.fetchByBarcode(code);

      if (!mounted) return;

      if (product == null) {
        _showSnack('Barcode $code not found in Open Food Facts');
        await _resumeScanning();
        return;
      }

      await Navigator.of(context).pushNamed('/results', arguments: product);

      // When the user comes back from results, allow scanning again.
      await _resumeScanning();
    } catch (e) {
      _showSnack('Lookup failed: $e');
      await _resumeScanning();
    }
  }

  Future<void> _resumeScanning() async {
    if (!mounted) return;
    setState(() {
      _isHandling = false;
      _lastBarcode = null;
    });
    await _controller.start();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a barcode')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Camera error: ${error.errorCode.name}\n\n'
                  'Make sure camera permission is granted in Settings.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Simple framing overlay so the user knows where to point.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          if (_isHandling)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Looking up product…',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
