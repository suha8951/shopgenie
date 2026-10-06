class Product {
  final int id;
  final int? user;
  final String name;
  final String category;
  final String sellingType; // 'UNIT' or 'KG'
  final double costPrice;
  final double pricePerUnit;
  final double quantity;
  final String formattedQuantity;
  final List<double>? featureVector;
  final bool isLoose;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    this.user,
    required this.name,
    required this.category,
    required this.sellingType,
    required this.costPrice,
    required this.pricePerUnit,
    required this.quantity,
    required this.formattedQuantity,
    this.featureVector,
    required this.isLoose,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  bool get isUnit => sellingType.toUpperCase() == 'UNIT';
  bool get isKg => sellingType.toUpperCase() == 'KG';

  factory Product.fromJson(Map<String, dynamic> json) {
    List<double>? vector;
    if (json['feature_vector'] != null && json['feature_vector'] is List) {
      vector = (json['feature_vector'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    return Product(
      id: json['id'] as int? ?? 0,
      user: json['user'] as int?,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      sellingType: json['selling_type'] as String? ?? 'UNIT',
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      formattedQuantity: json['formatted_quantity'] as String? ?? '',
      featureVector: vector,
      isLoose: json['is_loose'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (user != null) 'user': user,
      'name': name,
      'category': category,
      'selling_type': sellingType,
      'cost_price': costPrice,
      'price_per_unit': pricePerUnit,
      'quantity': quantity,
      'formatted_quantity': formattedQuantity,
      if (featureVector != null) 'feature_vector': featureVector,
      'is_loose': isLoose,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }

  Product copyWith({
    int? id,
    int? user,
    String? name,
    String? category,
    String? sellingType,
    double? costPrice,
    double? pricePerUnit,
    double? quantity,
    String? formattedQuantity,
    List<double>? featureVector,
    bool? isLoose,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      user: user ?? this.user,
      name: name ?? this.name,
      category: category ?? this.category,
      sellingType: sellingType ?? this.sellingType,
      costPrice: costPrice ?? this.costPrice,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      quantity: quantity ?? this.quantity,
      formattedQuantity: formattedQuantity ?? this.formattedQuantity,
      featureVector: featureVector ?? this.featureVector,
      isLoose: isLoose ?? this.isLoose,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
