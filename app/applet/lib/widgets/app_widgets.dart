import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../theme/app_theme.dart';

class SellingTypeBadge extends StatelessWidget {
  final String sellingType;
  final bool isLoose;

  const SellingTypeBadge({
    super.key,
    required this.sellingType,
    required this.isLoose,
  });

  @override
  Widget build(BuildContext context) {
    final isUnit = sellingType.toUpperCase() == 'UNIT';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUnit ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnit ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUnit ? Icons.inventory_2_outlined : Icons.scale_outlined,
            size: 12,
            color: isUnit ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
          ),
          const SizedBox(width: 4),
          Text(
            isUnit ? 'UNIT (Packaged)' : 'LOOSE (By Weight)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isUnit ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }
}

class StockStatusBadge extends StatelessWidget {
  final Product product;

  const StockStatusBadge({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isLow = product.isUnit ? product.quantity <= 5.0 : product.quantity <= 2.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLow ? const Color(0xFFFFEBEE) : const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isLow ? 'Low: ${product.formattedQuantity}' : 'Stock: ${product.formattedQuantity}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isLow ? AppTheme.dangerRed : const Color(0xFF33691E),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: product.isUnit
                      ? AppTheme.primaryGreen.withOpacity(0.08)
                      : AppTheme.accentAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  product.isUnit ? Icons.shopping_bag_outlined : Icons.scale_outlined,
                  color: product.isUnit ? AppTheme.primaryGreen : AppTheme.accentAmber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          product.category,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${product.pricePerUnit.toStringAsFixed(2)}/${product.sellingType}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryGreenDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SellingTypeBadge(
                          sellingType: product.sellingType,
                          isLoose: product.isLoose,
                        ),
                        const SizedBox(width: 8),
                        StockStatusBadge(product: product),
                      ],
                    ),
                  ],
                ),
              ),
              if (onAddToCart != null)
                IconButton.filledTonal(
                  onPressed: onAddToCart,
                  icon: const Icon(Icons.add_shopping_cart, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
                    foregroundColor: AppTheme.primaryGreen,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingStateView extends StatelessWidget {
  final String? message;

  const LoadingStateView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryGreen),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final VoidCallback? onConfigureServer;

  const ErrorStateView({
    super.key,
    required this.error,
    this.onRetry,
    this.onConfigureServer,
  });

  @override
  Widget build(BuildContext context) {
    final isConnectionError = error.contains('Failed to connect') ||
        error.contains('SocketException') ||
        error.contains('Connection refused') ||
        error.contains('timed out') ||
        error.contains('Cannot reach server');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConnectionError ? Icons.cloud_off_rounded : Icons.error_outline,
                size: 40,
                color: AppTheme.dangerRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isConnectionError ? 'Server Connection Failed' : 'Something went wrong',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (isConnectionError) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: const Text(
                  '10.0.2.2 is an emulator alias for your computer\'s localhost.\nIf running locally, ensure Django is running:\npython manage.py runserver 0.0.0.0:8000',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry Connection'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CartBadgeButton extends StatelessWidget {
  final VoidCallback onTap;

  const CartBadgeButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartService(),
      builder: (context, _) {
        final count = CartService().itemCount;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              tooltip: 'Cart',
              onPressed: onTap,
            ),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentAmber,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
