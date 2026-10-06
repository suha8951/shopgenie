import '../models/analytics.dart';
import '../models/invoice.dart';
import 'api_service.dart';

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();
  factory InvoiceService() => _instance;
  InvoiceService._internal();

  final ApiService _api = ApiService();

  Future<List<Invoice>> getInvoices() async {
    final response = await _api.get('/api/checkout/invoices/');
    if (response is List) {
      return response.map((item) => Invoice.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<Invoice> getInvoiceDetail(int id) async {
    final response = await _api.get('/api/checkout/invoices/$id/');
    return Invoice.fromJson(response as Map<String, dynamic>);
  }

  Future<ShopAnalytics> getAnalytics() async {
    final response = await _api.get('/api/checkout/analytics/');
    return ShopAnalytics.fromJson(response as Map<String, dynamic>);
  }
}
