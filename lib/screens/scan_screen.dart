import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/product.dart';
import '../services/open_food_facts_service.dart';
import '../services/scan_storage.dart';
import 'results_screen.dart';

const _backendBase = 'https://lather-agreement-humbly.ngrok-free.dev';

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

    await _controller.stop();

    try {
      final Product? product = await _off.fetchByBarcode(code);

      if (!mounted) return;

      if (product == null) {
        _showSnack('Barcode $code not found');
        await _resumeScanning();
        return;
      }

      // Call /analyze for AI scoring
      final analyzeRes = await http
          .post(
            Uri.parse('$_backendBase/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'product_name': product.name,
              'brand': product.brand,
              'ingredients': product.ingredientsText?.split(', ') ?? [],
              'packaging': {
                'packaging_text': product.packaging ?? '',
                'ecoscore_grade': product.ecoScoreGrade,
                'ecoscore_score': product.ecoScoreScore,
                'nutriscore_grade': product.nutriScoreGrade,
                'labels_tags': product.labels,
              },
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (analyzeRes.statusCode != 200) {
        _showSnack('Could not analyze product. Please try again.');
        await _resumeScanning();
        return;
      }

      final analysis = jsonDecode(analyzeRes.body) as Map<String, dynamic>;
      final result = _buildScanResult(product, analysis);

      await ScanStorage.save(ScanEntry(
        name: result.name,
        brand: result.brand,
        score: result.score,
        grade: result.grade,
        scannedAt: DateTime.now(),
      ));

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultsScreen(result: result)),
      );

      await _resumeScanning();
    } catch (e) {
      _showSnack('Lookup failed: $e');
      await _resumeScanning();
    }
  }

  ScanResult _buildScanResult(Product product, Map<String, dynamic> analysis) {
    final healthScore = (analysis['health_score'] as num?)?.toInt() ?? 5;
    final sustainScore =
        (analysis['sustainability_score'] as num?)?.toInt() ?? 5;
    final score = (sustainScore * 10).clamp(0, 100);
    final grade = score >= 80
        ? 'A'
        : score >= 60
            ? 'B'
            : score >= 40
                ? 'C'
                : score >= 20
                    ? 'D'
                    : 'E';

    final ecoFlags = (analysis['eco_flags'] as List?)?.cast<String>() ?? [];
    final healthFlags = (analysis['health_flags'] as List?)?.cast<String>() ?? [];
    final ecoPositives = (analysis['eco_positives'] as List?)?.cast<String>() ?? [];

    final breakdown = <ScoreFactor>[
      ScoreFactor(
        emoji: '❤️',
        label: 'Health Score',
        detail: 'Nutri-Score based rating',
        score: healthScore * 10,
      ),
      ScoreFactor(
        emoji: '🌱',
        label: 'Sustainability',
        detail: 'Eco-Score based rating',
        score: sustainScore * 10,
      ),
      ...ecoPositives.map((p) => ScoreFactor(
            emoji: '✅',
            label: 'Eco Positive',
            detail: p,
            score: 80,
          )),
      ...ecoFlags.map((f) => ScoreFactor(
            emoji: '🌍',
            label: 'Eco Concern',
            detail: f,
            score: 25,
          )),
      ...healthFlags.map((f) => ScoreFactor(
            emoji: '⚠️',
            label: 'Health Concern',
            detail: f,
            score: 25,
          )),
    ];

    return ScanResult(
      name: product.name,
      brand: product.brand,
      score: score,
      grade: grade,
      breakdown: breakdown,
      alternatives: ((analysis['alternatives'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map((a) => Alternative(
                name: a['name'] ?? '',
                brand: a['brand'] ?? '',
                score: (a['score'] as num?)?.toInt() ?? 50,
                reason: a['reason'] ?? '',
              ))
          .toList(),
    );
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
                      'Analyzing product…',
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
