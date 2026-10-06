import '../models/cart_item.dart';
import '../models/invoice.dart';
import 'api_service.dart';

class CheckoutResult {
  final bool success;
  final Invoice? invoice;
  final String? errorMessage;
  final int billedItemsCount;

  CheckoutResult({
    required this.success,
    this.invoice,
    this.errorMessage,
    this.billedItemsCount = 0,
  });
}

class CheckoutService {
  static final CheckoutService _instance = CheckoutService._internal();
  factory CheckoutService() => _instance;
  CheckoutService._internal();

  final ApiService _api = ApiService();

  Future<CheckoutResult> checkoutCart(List<CartItem> items, {void Function(int current, int total)? onProgress}) async {
    if (items.isEmpty) {
      return CheckoutResult(success: false, errorMessage: 'Cart is empty.');
    }

    int? currentInvoiceId;
    Invoice? lastInvoice;
    int billed = 0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (onProgress != null) {
        onProgress(i + 1, items.length);
      }

      try {
        final payload = item.toCheckoutPayload(currentInvoiceId);
        final response = await _api.post('/api/checkout/accept/', body: payload);

        if (response is Map<String, dynamic> && response.containsKey('invoice')) {
          final invoiceJson = response['invoice'] as Map<String, dynamic>;
          lastInvoice = Invoice.fromJson(invoiceJson);
          currentInvoiceId = lastInvoice.id;
          billed++;
        }
      } on ApiException catch (e) {
        return CheckoutResult(
          success: false,
          invoice: lastInvoice,
          billedItemsCount: billed,
          errorMessage: 'Checkout failed on "${item.product.name}": ${e.message}',
        );
      } catch (e) {
        return CheckoutResult(
          success: false,
          invoice: lastInvoice,
          billedItemsCount: billed,
          errorMessage: 'Checkout error on "${item.product.name}": $e',
        );
      }
    }

    if (lastInvoice != null) {
      return CheckoutResult(
        success: true,
        invoice: lastInvoice,
        billedItemsCount: billed,
      );
    } else {
      return CheckoutResult(
        success: false,
        errorMessage: 'Failed to generate invoice from checkout.',
      );
    }
  }

  Future<Invoice> acceptSingleItem({
    required int productId,
    required double quantity,
    int? invoiceId,
  }) async {
    final payload = {
      'product_id': productId,
      'quantity': quantity,
      if (invoiceId != null) 'invoice_id': invoiceId,
    };

    final response = await _api.post('/api/checkout/accept/', body: payload);
    return Invoice.fromJson(response['invoice'] as Map<String, dynamic>);
  }
}
