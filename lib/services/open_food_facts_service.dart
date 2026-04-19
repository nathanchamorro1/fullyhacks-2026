import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/product.dart';

const _backendBase = 'https://lather-agreement-humbly.ngrok-free.dev';

class OpenFoodFactsService {
  Future<Product?> fetchByBarcode(String barcode) async {
    final resp = await http
        .post(
          Uri.parse('$_backendBase/scan'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'barcode': barcode}),
        )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 404) return null;
    if (resp.statusCode != 200) {
      throw Exception('Backend returned ${resp.statusCode} for $barcode');
    }

    final body = json.decode(resp.body) as Map<String, dynamic>;
    final packaging = (body['packaging'] as Map<String, dynamic>?) ?? {};
    final ingredients = (body['ingredients'] as List?)?.cast<String>() ?? [];
    final labels = (packaging['labels_tags'] as List?)
            ?.cast<String>()
            .map((t) => t.replaceFirst(RegExp(r'^en:'), ''))
            .toList() ??
        [];

    return Product(
      barcode: barcode,
      name: body['product_name']?.toString() ?? 'Unknown product',
      brand: body['brand']?.toString() ?? '',
      ingredientsText: ingredients.join(', '),
      packaging: packaging['packaging_text']?.toString() ??
          (packaging['packaging_tags'] as List?)?.join(', '),
      ecoScoreGrade: packaging['ecoscore_grade']?.toString(),
      ecoScoreScore: (packaging['ecoscore_score'] as num?)?.toInt(),
      nutriScoreGrade: packaging['nutriscore_grade']?.toString(),
      labels: labels,
    );
  }
}
