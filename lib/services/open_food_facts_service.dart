// Thin API client for Open Food Facts.
//
// Docs: https://openfoodfacts.github.io/openfoodfacts-server/api/
// No API key needed. They do ask that you identify your app in the User-Agent.
//
// v2 endpoint: https://world.openfoodfacts.org/api/v2/product/<barcode>.json
// Response shape:
//   {
//     "status": 1 or 0,       // 1 = found, 0 = not found
//     "status_verbose": "...",
//     "product": { ...lots of fields... }
//   }

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/product.dart';

class OpenFoodFactsService {
  static const _base = 'https://world.openfoodfacts.org/api/v2/product';

  // Be a good citizen — OFF asks for a descriptive User-Agent.
  static const _userAgent =
      'SustainScan/0.1 (hackathon prototype; contact: team@example.com)';

  /// Returns the [Product] or `null` if the barcode isn't in their database.
  /// Throws on network / non-200 errors so the UI can show a retry state.
  Future<Product?> fetchByBarcode(String barcode) async {
    final uri = Uri.parse('$_base/$barcode.json');
    final resp = await http.get(uri, headers: {'User-Agent': _userAgent});

    if (resp.statusCode != 200) {
      throw Exception(
        'Open Food Facts returned ${resp.statusCode} for $barcode',
      );
    }

    final body = json.decode(resp.body) as Map<String, dynamic>;

    // status = 0 means barcode not found. status = 1 means found.
    final status = body['status'];
    if (status == 0 || status == '0') return null;

    return Product.fromOpenFoodFacts(barcode, body);
  }
}
