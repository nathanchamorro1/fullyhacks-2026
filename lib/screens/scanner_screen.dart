import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import 'results_screen.dart';

const _backendUrl = 'http://10.67.125.24:8000';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;

    setState(() => _processing = true);
    await _controller.stop();

    try {
      // Step 1: look up product by barcode
      final scanRes = await http.post(
        Uri.parse('$_backendUrl/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'barcode': barcode}),
      );

      if (!mounted) return;

      if (scanRes.statusCode == 404) {
        _showError('Product not found for barcode: $barcode');
        return;
      }
      if (scanRes.statusCode != 200) {
        _showError('Failed to fetch product. Please try again.');
        return;
      }

      final product = jsonDecode(scanRes.body) as Map<String, dynamic>;

      // Step 2: get AI analysis
      final analyzeRes = await http.post(
        Uri.parse('$_backendUrl/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'product_name': product['product_name'],
          'brand': product['brand'],
          'ingredients': product['ingredients'] ?? [],
          'packaging': product['packaging'] ?? {},
        }),
      );

      if (!mounted) return;

      if (analyzeRes.statusCode != 200) {
        _showError('Could not analyze product. Please try again.');
        return;
      }

      final analysis = jsonDecode(analyzeRes.body) as Map<String, dynamic>;
      final result = _toScanResult(product, analysis);

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultsScreen(result: result)),
      );
      await _controller.start();
      setState(() => _processing = false);
    } catch (_) {
      if (mounted) _showError('Network error. Check your connection.');
    }
  }

  ScanResult _toScanResult(
    Map<String, dynamic> product,
    Map<String, dynamic> analysis,
  ) {
    final healthScore = (analysis['health_score'] as num?)?.toInt() ?? 5;
    final sustainScore = (analysis['sustainability_score'] as num?)?.toInt() ?? 5;
    final score = ((healthScore + sustainScore) / 2 * 10).round().clamp(0, 100);
    final grade = score >= 80
        ? 'A'
        : score >= 60
            ? 'B'
            : score >= 40
                ? 'C'
                : score >= 20
                    ? 'D'
                    : 'E';

    final flags = (analysis['flags'] as List?)?.cast<String>() ?? [];
    final positives = (analysis['positives'] as List?)?.cast<String>() ?? [];

    return ScanResult(
      name: product['product_name']?.toString() ?? 'Unknown',
      brand: product['brand']?.toString() ?? 'Unknown',
      score: score,
      grade: grade,
      breakdown: [
        ScoreFactor(
          icon: Icons.favorite_rounded,
          label: 'Health',
          detail: positives.isNotEmpty ? positives.join(', ') : 'No data',
          score: healthScore * 10,
        ),
        ScoreFactor(
          icon: Icons.eco_rounded,
          label: 'Sustainability',
          detail: flags.isNotEmpty ? flags.join(', ') : 'No concerns',
          score: sustainScore * 10,
        ),
      ],
      alternatives: const [],
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
    _controller.start();
    setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
        errorBuilder: (context, error, child) {
          final message = error.errorCode == MobileScannerErrorCode.permissionDenied
              ? 'Camera permission denied.\nPlease enable it in Settings.'
              : 'Camera error: ${error.errorCode.name}';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        },
        overlayBuilder: (context, constraints) {
          return Stack(
            children: [
              if (_processing)
                const Center(child: CircularProgressIndicator()),
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Text(
                    'Point the camera at the barcode and we\'ll do the rest.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
