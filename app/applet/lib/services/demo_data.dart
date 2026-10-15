import '../models/analytics.dart';
import '../models/cart_item.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import '../models/user.dart';

/// Worker model representation for staff management.
class DemoWorker {
  final int id;
  final String name;
  final String role;
  final String phone;
  final String shift;
  final List<String> permissions;
  final bool isActive;

  const DemoWorker({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.shift,
    required this.permissions,
    required this.isActive,
  });
}

/// Rich, clearly labeled sample Kirana dataset for development exploration.
class DemoData {
  /// Demo user profile representing an authenticated Kirana shop owner
  static final User demoUser = User(
    id: 9999,
    username: 'ramesh_sharma',
    email: 'sharma.kirana@shopgenie.local',
    shopName: 'Sharma Kirana & General Store',
    phoneNumber: '+91 98765 43210',
    shopCategory: 'Daily Kirana & FMCG Grocery',
    shopAddress: 'Shop #14, Main Market Road, Sector 5, Bengaluru, KA 560001',
    ownerName: 'Ramesh Sharma',
    isVerified: true,
    role: 'OWNER',
    dateJoined: DateTime(2023, 4, 15),
  );

  /// Demo worker profile representing a store staff member
  static final User demoWorkerUser = User(
    id: 9998,
    username: 'suresh_kumar',
    email: 'suresh.staff@shopgenie.local',
    shopName: 'Sharma Kirana & General Store',
    phoneNumber: '+91 98450 11223',
    shopCategory: 'Daily Kirana & FMCG Grocery',
    shopAddress: 'Shop #14, Main Market Road, Sector 5, Bengaluru, KA 560001',
    ownerName: 'Ramesh Sharma',
    isVerified: true,
    role: 'WORKER',
    dateJoined: DateTime(2024, 1, 10),
  );

  /// Sample products across packaged units and loose kilogram goods
  static final List<Product> _demoProducts = [
    Product(
      id: 901,
      name: '[DEMO] Tata Salt Vacuum Evaporated (1kg)',
      category: 'Spices & Staples',
      sellingType: 'UNIT',
      costPrice: 23.00,
      pricePerUnit: 28.00,
      quantity: 42,
      isLoose: false,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Product(
      id: 902,
      name: '[DEMO] Aashirvaad Shudh Chakki Atta (5kg)',
      category: 'Grains & Flours',
      sellingType: 'UNIT',
      costPrice: 215.00,
      pricePerUnit: 245.00,
      quantity: 16,
      isLoose: false,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    Product(
      id: 903,
      name: '[DEMO] Fortune Sunlite Refined Sunflower Oil (1L)',
      category: 'Edible Oils',
      sellingType: 'UNIT',
      costPrice: 122.00,
      pricePerUnit: 140.00,
      quantity: 24,
      isLoose: false,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Product(
      id: 904,
      name: '[DEMO] Premium Toor Dal (Loose Unpolished)',
      category: 'Pulses & Dals',
      sellingType: 'KG',
      costPrice: 138.00,
      pricePerUnit: 160.00,
      quantity: 38.5,
      isLoose: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Product(
      id: 905,
      name: '[DEMO] Pure White Sugar / Chini (Loose)',
      category: 'Staples',
      sellingType: 'KG',
      costPrice: 38.00,
      pricePerUnit: 44.00,
      quantity: 3.2, // Low stock item
      isLoose: true,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
    Product(
      id: 906,
      name: '[DEMO] Amul Pasteurised Salted Butter (100g)',
      category: 'Dairy Products',
      sellingType: 'UNIT',
      costPrice: 48.00,
      pricePerUnit: 56.00,
      quantity: 14,
      isLoose: false,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Product(
      id: 907,
      name: '[DEMO] Maggi 2-Minute Masala Noodles (70g)',
      category: 'Instant Food',
      sellingType: 'UNIT',
      costPrice: 11.50,
      pricePerUnit: 14.00,
      quantity: 65,
      isLoose: false,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    Product(
      id: 908,
      name: '[DEMO] Surf Excel Easy Wash Detergent Powder (1kg)',
      category: 'Household & Cleaning',
      sellingType: 'UNIT',
      costPrice: 114.00,
      pricePerUnit: 135.00,
      quantity: 4.0, // Low stock item
      isLoose: false,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Product(
      id: 909,
      name: '[DEMO] Parle-G Gold Glucose Biscuits (1kg Pack)',
      category: 'Snacks & Biscuits',
      sellingType: 'UNIT',
      costPrice: 74.00,
      pricePerUnit: 90.00,
      quantity: 28,
      isLoose: false,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Product(
      id: 910,
      name: '[DEMO] MDH Deggi Mirch Natural Red Chilli (100g)',
      category: 'Spices & Staples',
      sellingType: 'UNIT',
      costPrice: 72.00,
      pricePerUnit: 85.00,
      quantity: 18,
      isLoose: false,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  static List<Product> getDemoProducts() {
    return List<Product>.from(_demoProducts);
  }

  static Product getDemoProductDetail(int id) {
    return _demoProducts.firstWhere(
      (p) => p.id == id,
      orElse: () => _demoProducts.first,
    );
  }

  /// Store Analytics for Demo Mode
  static ShopAnalytics get demoAnalytics => ShopAnalytics(
        totalSales: 18450.00,
        totalProfit: 3820.00,
        inventoryValuationCost: 118400.00,
        inventoryValuationRetail: 145200.00,
        totalProducts: 10,
        totalInvoices: 42,
        lowStockCount: 2,
        lowStockItems: [
          _demoProducts[4], // Sugar
          _demoProducts[7], // Surf Excel
        ],
      );

  /// Sample Invoices for Invoice History
  static final List<Invoice> _demoInvoices = [
    Invoice(
      id: 7001,
      totalAmount: 413.00,
      status: 'PAID (Cash)',
      itemCount: 3,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      items: [
        InvoiceItem(
          id: 1,
          product: 901,
          productName: '[DEMO] Tata Salt (1kg)',
          productCategory: 'Spices & Staples',
          sellingType: 'UNIT',
          quantity: 1,
          unitPrice: 28.00,
          totalPrice: 28.00,
        ),
        InvoiceItem(
          id: 2,
          product: 902,
          productName: '[DEMO] Aashirvaad Shudh Chakki Atta (5kg)',
          productCategory: 'Grains & Flours',
          sellingType: 'UNIT',
          quantity: 1,
          unitPrice: 245.00,
          totalPrice: 245.00,
        ),
        InvoiceItem(
          id: 3,
          product: 903,
          productName: '[DEMO] Fortune Sunlite Sunflower Oil (1L)',
          productCategory: 'Edible Oils',
          sellingType: 'UNIT',
          quantity: 1,
          unitPrice: 140.00,
          totalPrice: 140.00,
        ),
      ],
    ),
    Invoice(
      id: 7002,
      totalAmount: 230.00,
      status: 'PAID (UPI)',
      itemCount: 2,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      items: [
        InvoiceItem(
          id: 4,
          product: 907,
          productName: '[DEMO] Maggi 2-Minute Masala Noodles (70g)',
          productCategory: 'Instant Food',
          sellingType: 'UNIT',
          quantity: 5,
          unitPrice: 14.00,
          totalPrice: 70.00,
        ),
        InvoiceItem(
          id: 5,
          product: 904,
          productName: '[DEMO] Premium Toor Dal (Loose)',
          productCategory: 'Pulses & Dals',
          sellingType: 'KG',
          quantity: 1.0,
          unitPrice: 160.00,
          totalPrice: 160.00,
        ),
      ],
    ),
    Invoice(
      id: 7003,
      totalAmount: 180.00,
      status: 'PAID (Cash)',
      itemCount: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      items: [
        InvoiceItem(
          id: 6,
          product: 909,
          productName: '[DEMO] Parle-G Gold Glucose Biscuits (1kg Pack)',
          productCategory: 'Snacks & Biscuits',
          sellingType: 'UNIT',
          quantity: 2,
          unitPrice: 90.00,
          totalPrice: 180.00,
        ),
      ],
    ),
  ];

  static List<Invoice> getDemoInvoices() {
    return List<Invoice>.from(_demoInvoices);
  }

  static Invoice getDemoInvoiceDetail(int id) {
    return _demoInvoices.firstWhere(
      (inv) => inv.id == id,
      orElse: () => _demoInvoices.first,
    );
  }

  /// Generates a temporary in-memory invoice for demo checkout preview
  static Invoice createSimulatedInvoice(List<CartItem> items, double total) {
    return Invoice(
      id: 9900 + (DateTime.now().millisecond % 100),
      totalAmount: total,
      status: 'PREVIEW (Demo - Not Saved)',
      itemCount: items.length,
      createdAt: DateTime.now(),
      items: items.asMap().entries.map((entry) {
        final index = entry.key;
        final cartItem = entry.value;
        return InvoiceItem(
          id: 8000 + index,
          product: cartItem.product.id,
          productName: cartItem.product.name,
          productCategory: cartItem.product.category,
          sellingType: cartItem.product.sellingType,
          quantity: cartItem.quantity,
          unitPrice: cartItem.product.pricePerUnit,
          totalPrice: cartItem.subtotal,
        );
      }).toList(),
    );
  }

  /// Sample workers for Kirana staff management
  static const List<DemoWorker> demoWorkers = [
    DemoWorker(
      id: 101,
      name: 'Ramesh Kumar',
      role: 'Senior Cashier & Billing Operator',
      phone: '+91 98111 22334',
      shift: 'Morning Shift (8:00 AM - 3:00 PM)',
      permissions: ['POS Billing', 'Barcode Scanner', 'Manual Selection'],
      isActive: true,
    ),
    DemoWorker(
      id: 102,
      name: 'Suresh Patel',
      role: 'Store Assistant & Stock Auditor',
      phone: '+91 98222 33445',
      shift: 'Full Day (9:00 AM - 7:00 PM)',
      permissions: ['Inventory Stock Audit', 'Weighing Scale', 'Catalog View'],
      isActive: true,
    ),
    DemoWorker(
      id: 103,
      name: 'Pooja Verma',
      role: 'Inventory & Loose Goods Clerk',
      phone: '+91 98333 44556',
      shift: 'Evening Shift (2:00 PM - 9:00 PM)',
      permissions: ['Loose Item Weight Entry', 'Stock Inspection'],
      isActive: false, // On leave
    ),
  ];
}
