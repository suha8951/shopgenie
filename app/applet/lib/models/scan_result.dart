import 'product.dart';

enum MatchType {
  product,
  looseCandidates,
  unknown,
}

class ScanResult {
  final MatchType matchType;
  final int? productId;
  final String? name;
  final String? category;
  final String? sellingType;
  final double? costPrice;
  final double? pricePerUnit;
  final double? quantity;
  final String? formattedQuantity;
  final double? similarity; // Cosine similarity e.g. 0.85
  final String? message;
  final List<Product> candidates;

  ScanResult({
    required this.matchType,
    this.productId,
    this.name,
    this.category,
    this.sellingType,
    this.costPrice,
    this.pricePerUnit,
    this.quantity,
    this.formattedQuantity,
    this.similarity,
    this.message,
    this.candidates = const [],
  });

  bool get isProductMatch => matchType == MatchType.product;
  bool get isLooseCandidates => matchType == MatchType.looseCandidates;

  int get confidencePercentage => similarity != null ? (similarity! * 100).clamp(0, 100).toInt() : 0;

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    String typeStr = (json['match_type'] as String? ?? '').toUpperCase();
    MatchType type;
    if (typeStr == 'PRODUCT') {
      type = MatchType.product;
    } else if (typeStr == 'LOOSE_CANDIDATES') {
      type = MatchType.looseCandidates;
    } else {
      type = MatchType.unknown;
    }

    List<Product> candidateList = [];
    if (json['candidates'] != null && json['candidates'] is List) {
      candidateList = (json['candidates'] as List)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ScanResult(
      matchType: type,
      productId: json['product_id'] as int?,
      name: json['name'] as String?,
      category: json['category'] as String?,
      sellingType: json['selling_type'] as String?,
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble(),
      formattedQuantity: json['formatted_quantity'] as String?,
      similarity: (json['similarity'] as num?)?.toDouble(),
      message: json['message'] as String?,
      candidates: candidateList,
    );
  }

  Product? toProduct() {
    if (!isProductMatch || productId == null) return null;
    return Product(
      id: productId!,
      name: name ?? '',
      category: category ?? 'General',
      sellingType: sellingType ?? 'UNIT',
      costPrice: costPrice ?? 0.0,
      pricePerUnit: pricePerUnit ?? 0.0,
      quantity: quantity ?? 0.0,
      formattedQuantity: formattedQuantity ?? '',
      isLoose: sellingType?.toUpperCase() == 'KG',
    );
  }
}
