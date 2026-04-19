// ============================================================
// backend_service.dart — wraps Nathan's FastAPI backend.
//
// Two endpoints:
//   POST /scan    → barcode lookup via Open Food Facts
//   POST /analyze → Gemini LLM scoring
//
// Update [baseUrl] once Nathan deploys (or change to LAN IP
// when running on a real device during the demo).
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Base URL ─────────────────────────────────────────────────
// localhost works for web/emulator. For a real phone on the
// same Wi-Fi, use Nathan's LAN IP e.g. 'http://192.168.x.x:8000'
const _kBaseUrl = 'http://localhost:8000';

// ============================================================
// DATA: product from /scan
// ============================================================
class ScanData {
  final String barcode;
  final String productName;
  final String brand;
  final List<String> ingredients;
  final Map<String, dynamic> packaging;

  const ScanData({
    required this.barcode,
    required this.productName,
    required this.brand,
    required this.ingredients,
    required this.packaging,
  });

  factory ScanData.fromJson(Map<String, dynamic> json) => ScanData(
        barcode: (json['barcode'] as String?) ?? '',
        productName: (json['product_name'] as String?)?.trim().isNotEmpty == true
            ? json['product_name'] as String
            : 'Unknown product',
        brand: (json['brand'] as String?) ?? '',
        ingredients: (json['ingredients'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        packaging:
            (json['packaging'] as Map<String, dynamic>?) ?? {},
      );

  /// Shape sent to /analyze
  Map<String, dynamic> toAnalyzePayload() => {
        'product_name': productName,
        'brand': brand,
        'ingredients': ingredients,
        'packaging': packaging,
      };
}

// ============================================================
// DATA: Gemini analysis from /analyze
// ============================================================
class AnalysisResult {
  final String productName;
  final String brand;
  final String summary;
  final int healthScore;          // 1-10  (from Gemini)
  final int sustainabilityScore;  // 1-10  (from Gemini)
  final List<String> flags;       // e.g. "high sugar", "palm oil"
  final List<String> positives;   // e.g. "vegan", "low sodium"

  const AnalysisResult({
    required this.productName,
    required this.brand,
    required this.summary,
    required this.healthScore,
    required this.sustainabilityScore,
    required this.flags,
    required this.positives,
  });

  // ── Derived fields ──────────────────────────────────────────

  /// Combined 0-100 score used by the bear mood system.
  int get combinedScore =>
      ((healthScore + sustainabilityScore) / 2 * 10).round().clamp(0, 100);

  String get grade {
    final s = combinedScore;
    if (s >= 90) return 'A+';
    if (s >= 80) return 'A';
    if (s >= 70) return 'B';
    if (s >= 60) return 'C';
    if (s >= 40) return 'D';
    return 'F';
  }

  factory AnalysisResult.fromJson(
    Map<String, dynamic> json, {
    required String productName,
    required String brand,
  }) =>
      AnalysisResult(
        productName: productName,
        brand: brand,
        summary: (json['summary'] as String?) ?? '',
        healthScore: _parseInt(json['health_score'], fallback: 5),
        sustainabilityScore:
            _parseInt(json['sustainability_score'], fallback: 5),
        flags: _parseStringList(json['flags']),
        positives: _parseStringList(json['positives']),
      );

  // ── Demo data (used until backend is live) ──────────────────
  static AnalysisResult demo({int healthScore = 8, int sustainabilityScore = 9}) =>
      AnalysisResult(
        productName: 'Oat Milk · 1L',
        brand: 'Oatly',
        summary:
            'A solid plant-based choice with low carbon footprint and minimal '
            'processing. Packaging is recyclable in most regions.',
        healthScore: healthScore,
        sustainabilityScore: sustainabilityScore,
        flags: healthScore < 5
            ? ['ultra-processed', 'high sugar', 'non-recyclable packaging']
            : [],
        positives: healthScore >= 5
            ? ['plant-based', 'low carbon footprint', 'recyclable carton']
            : ['no artificial colours'],
      );
}

// ============================================================
// SERVICE
// ============================================================
class BackendService {
  static const _headers = {
    'Content-Type': 'application/json',
    'User-Agent': 'NanukApp/0.1',
  };

  /// Step 1 — look up a barcode.
  /// Returns [ScanData] on success, null if barcode not found.
  /// Throws on network / server errors.
  Future<ScanData?> scanBarcode(String barcode) async {
    final uri = Uri.parse('$_kBaseUrl/scan');

    final response = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({'barcode': barcode}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) return null;

    if (response.statusCode != 200) {
      throw Exception(
          'Scan error ${response.statusCode}: ${response.body}');
    }

    return ScanData.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Step 2 — run Gemini analysis on [data] returned by [scanBarcode].
  Future<AnalysisResult> analyzeProduct(ScanData data) async {
    final uri = Uri.parse('$_kBaseUrl/analyze');

    final response = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode(data.toAnalyzePayload()),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
          'Analysis error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AnalysisResult.fromJson(
      json,
      productName: data.productName,
      brand: data.brand,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────
int _parseInt(dynamic v, {required int fallback}) {
  if (v == null) return fallback;
  if (v is int) return v.clamp(1, 10);
  return int.tryParse(v.toString())?.clamp(1, 10) ?? fallback;
}

List<String> _parseStringList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}
