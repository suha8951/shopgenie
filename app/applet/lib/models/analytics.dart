import 'product.dart';

class ShopAnalytics {
  final double totalSales;
  final double totalProfit;
  final double inventoryValuationCost;
  final double inventoryValuationRetail;
  final int totalProducts;
  final int totalInvoices;
  final int lowStockCount;
  final List<Product> lowStockItems;

  ShopAnalytics({
    required this.totalSales,
    required this.totalProfit,
    required this.inventoryValuationCost,
    required this.inventoryValuationRetail,
    required this.totalProducts,
    required this.totalInvoices,
    required this.lowStockCount,
    required this.lowStockItems,
  });

  factory ShopAnalytics.fromJson(Map<String, dynamic> json) {
    List<Product> lowItems = [];
    if (json['low_stock_items'] != null && json['low_stock_items'] is List) {
      lowItems = (json['low_stock_items'] as List)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ShopAnalytics(
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0.0,
      inventoryValuationCost: (json['inventory_valuation_cost'] as num?)?.toDouble() ?? 0.0,
      inventoryValuationRetail: (json['inventory_valuation_retail'] as num?)?.toDouble() ?? 0.0,
      totalProducts: json['total_products'] as int? ?? 0,
      totalInvoices: json['total_invoices'] as int? ?? 0,
      lowStockCount: json['low_stock_count'] as int? ?? lowItems.length,
      lowStockItems: lowItems,
    );
  }
}
