import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final ApiService _api = ApiService();

  Future<List<Product>> getProducts() async {
    final response = await _api.get('/api/products/');
    if (response is List) {
      return response.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<Product> getProductDetail(int id) async {
    final response = await _api.get('/api/products/$id/');
    return Product.fromJson(response as Map<String, dynamic>);
  }

  Future<Product> registerProduct({
    required String name,
    required String category,
    required String sellingType, // 'UNIT' or 'KG'
    required double costPrice,
    required double pricePerUnit,
    required double quantity,
    required bool isLoose,
    List<double>? featureVector,
    String? imageUrl,
  }) async {
    final body = {
      'name': name.trim(),
      'category': category.trim(),
      'selling_type': sellingType.toUpperCase(),
      'cost_price': costPrice,
      'price_per_unit': pricePerUnit,
      'quantity': sellingType.toUpperCase() == 'UNIT' ? quantity.toInt() : quantity,
      'is_loose': isLoose,
      if (featureVector != null) 'feature_vector': featureVector,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
    };

    final response = await _api.post('/api/products/register/', body: body);
    return Product.fromJson(response as Map<String, dynamic>);
  }

  Future<Product> updateProduct(int id, {
    String? name,
    String? category,
    String? sellingType,
    double? costPrice,
    double? pricePerUnit,
    double? quantity,
    bool? isLoose,
    List<double>? featureVector,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (category != null) body['category'] = category.trim();
    if (sellingType != null) body['selling_type'] = sellingType.toUpperCase();
    if (costPrice != null) body['cost_price'] = costPrice;
    if (pricePerUnit != null) body['price_per_unit'] = pricePerUnit;
    if (quantity != null) {
      body['quantity'] = (sellingType?.toUpperCase() == 'UNIT') ? quantity.toInt() : quantity;
    }
    if (isLoose != null) body['is_loose'] = isLoose;
    if (featureVector != null) body['feature_vector'] = featureVector;
    if (imageUrl != null) body['image_url'] = imageUrl;

    final response = await _api.put('/api/products/$id/', body: body);
    return Product.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteProduct(int id) async {
    await _api.delete('/api/products/$id/');
  }
}
