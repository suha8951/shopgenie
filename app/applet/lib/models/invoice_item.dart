class InvoiceItem {
  final int id;
  final int product;
  final String productName;
  final String productCategory;
  final String sellingType;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  InvoiceItem({
    required this.id,
    required this.product,
    required this.productName,
    required this.productCategory,
    required this.sellingType,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  bool get isLoose => sellingType.toUpperCase() == 'KG';

  String get formattedQuantity {
    if (isLoose) {
      if (quantity < 1.0) {
        return '${(quantity * 1000).toInt()} g';
      }
      return '${quantity.toStringAsFixed(3)} kg';
    } else {
      return '${quantity.toInt()} units';
    }
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as int? ?? 0,
      product: json['product'] as int? ?? 0,
      productName: json['product_name'] as String? ?? 'Item',
      productCategory: json['product_category'] as String? ?? 'General',
      sellingType: json['selling_type'] as String? ?? 'UNIT',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'product_name': productName,
      'product_category': productCategory,
      'selling_type': sellingType,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}
