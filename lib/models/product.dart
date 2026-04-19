// Plain Dart data class for a product pulled from Open Food Facts.
//
// Open Food Facts returns a lot of fields — we grab only what's relevant for
// (a) showing the user and (b) feeding into the sustainability LLM prompt.
//
// Keep this model small for now. Add fields as the scoring prompt needs them.

class Product {
  final String barcode;
  final String name;
  final String brand;
  final String? imageUrl;

  // Fields we'll pass to the LLM for sustainability scoring.
  final String? ingredientsText;
  final String? packaging;            // e.g. "plastic, cardboard"
  final String? origins;              // e.g. "France, Spain"
  final String? manufacturingPlaces;
  final List<String> labels;          // e.g. ["organic", "fair-trade"]
  final List<String> categories;
  final String? ecoScoreGrade;        // Open Food Facts' own a-e grade if present
  final String? novaGroup;            // ultra-processed food classification

  const Product({
    required this.barcode,
    required this.name,
    required this.brand,
    this.imageUrl,
    this.ingredientsText,
    this.packaging,
    this.origins,
    this.manufacturingPlaces,
    this.labels = const [],
    this.categories = const [],
    this.ecoScoreGrade,
    this.novaGroup,
  });

  /// Build from the Open Food Facts `/api/v2/product/<barcode>.json` response.
  /// The top-level response is `{ status, product: {...} }`.
  factory Product.fromOpenFoodFacts(String barcode, Map<String, dynamic> json) {
    final p = (json['product'] as Map<String, dynamic>?) ?? const {};

    List<String> splitCsv(dynamic v) {
      if (v == null) return const [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return v
          .toString()
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return Product(
      barcode: barcode,
      name: (p['product_name'] as String?)?.trim().isNotEmpty == true
          ? p['product_name'] as String
          : 'Unknown product',
      brand: (p['brands'] as String?) ?? '',
      imageUrl: p['image_front_url'] as String? ?? p['image_url'] as String?,
      ingredientsText: p['ingredients_text'] as String?,
      packaging: p['packaging'] as String?,
      origins: p['origins'] as String?,
      manufacturingPlaces: p['manufacturing_places'] as String?,
      labels: splitCsv(p['labels']),
      categories: splitCsv(p['categories']),
      ecoScoreGrade: p['ecoscore_grade'] as String?,
      novaGroup: p['nova_group']?.toString(),
    );
  }

  /// Shape we'll send to the FastAPI backend for LLM scoring.
  Map<String, dynamic> toScoringPayload() => {
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'ingredients': ingredientsText,
        'packaging': packaging,
        'origins': origins,
        'manufacturing_places': manufacturingPlaces,
        'labels': labels,
        'categories': categories,
        'eco_score_grade': ecoScoreGrade,
        'nova_group': novaGroup,
      };
}
