import 'invoice_item.dart';

class Invoice {
  final int id;
  final int? user;
  final double totalAmount;
  final String status;
  final List<InvoiceItem> items;
  final int itemCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Invoice({
    required this.id,
    this.user,
    required this.totalAmount,
    required this.status,
    required this.items,
    required this.itemCount,
    this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    List<InvoiceItem> itemsList = [];
    if (json['items'] != null && json['items'] is List) {
      itemsList = (json['items'] as List)
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Invoice(
      id: json['id'] as int? ?? 0,
      user: json['user'] as int?,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'COMPLETED',
      items: itemsList,
      itemCount: json['item_count'] as int? ?? itemsList.length,
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
      'total_amount': totalAmount,
      'status': status,
      'items': items.map((i) => i.toJson()).toList(),
      'item_count': itemCount,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
