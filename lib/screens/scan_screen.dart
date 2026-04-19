// ============================================================
// scan_screen.dart — camera barcode scanner.
//
// Flow:
//   1. MobileScanner detects a barcode
//   2. Call BackendService.scanBarcode(code)   → ScanData
//   3. Call BackendService.analyzeProduct(data) → AnalysisResult
//   4. Push /results with the AnalysisResult
//
// The two-step backend call (scan → analyze) keeps the UI
// showing a loading state the whole time, then navigates
// when both are done.
// ============================================================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme.dart';
import '../services/backend_service.dart';
import '../services/stats_service.dart';

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

  final BackendService _backend = BackendService();
  final StatsService   _stats   = StatsService();

  bool   _isHandling = false;
  String? _lastBarcode;
  String  _statusMessage = 'Point at a barcode';

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
      _statusMessage = 'Looking up product…';
    });

    await _controller.stop();

    try {
      // ── Step 1: barcode lookup ──────────────────────────────
      final scanData = await _backend.scanBarcode(code);

      if (!mounted) return;

      if (scanData == null) {
        _showSnack('Barcode $code not found — try another product');
        await _resumeScanning();
        return;
      }

      // ── Step 2: Gemini analysis ─────────────────────────────
      setState(() => _statusMessage = 'Analysing with AI…');

      final analysis = await _backend.analyzeProduct(scanData);

      // Save scan to stats (count, streak, avg grade)
      await _stats.recordScan(analysis.combinedScore);

      if (!mounted) return;

      await Navigator.of(context)
          .pushNamed('/results', arguments: analysis);

      await _resumeScanning();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: ${e.toString().replaceAll('Exception: ', '')}');
      await _resumeScanning();
    }
  }

  Future<void> _resumeScanning() async {
    if (!mounted) return;
    setState(() {
      _isHandling   = false;
      _lastBarcode  = null;
      _statusMessage = 'Point at a barcode';
    });
    await _controller.start();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('SCAN', style: kLabelStyle(size: 13, color: Colors.white, letterSpacing: 2)),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ── Camera feed ───────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined,
                        color: Colors.white54, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Camera unavailable\n'
                      '(${error.errorCode.name})\n\n'
                      'Make sure camera permission is granted in Settings.',
                      style: kBodyStyle(size: 14, color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Viewfinder overlay ────────────────────────────────
          IgnorePointer(
            child: Center(
              child: SizedBox(
                width: 260,
                height: 180,
                child: CustomPaint(
                  painter: _ViewfinderPainter(),
                ),
              ),
            ),
          ),

          // ── Status label ──────────────────────────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _statusMessage,
                  style: kBodyStyle(size: 14, color: Colors.white),
                ),
              ),
            ),
          ),

          // ── Loading overlay ───────────────────────────────────
          if (_isHandling)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: kBlue, strokeWidth: 3),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      style: kBodyStyle(size: 15, color: Colors.white),
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

// ── Viewfinder corner-bracket overlay ────────────────────────
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kBlue
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    const len = 28.0;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(Offset(0, len), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(len, 0), paint);
    // Top-right
    canvas.drawLine(Offset(w - len, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, h - len), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    // Bottom-right
    canvas.drawLine(Offset(w, h - len), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w - len, h), paint);
  }

  @override
  bool shouldRepaint(_ViewfinderPainter old) => false;
}
