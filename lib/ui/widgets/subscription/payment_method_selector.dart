import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

enum PaymentMethod {
  stripe,
  googlePay,
  applePay,
  payPal,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.stripe:
        return 'Credit/Debit Card';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.payPal:
        return 'PayPal';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.stripe:
        return Icons.credit_card_rounded;
      case PaymentMethod.googlePay:
        return Icons.account_balance_wallet_rounded;
      case PaymentMethod.applePay:
        return Icons.apple_rounded;
      case PaymentMethod.payPal:
        return Icons.payment_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case PaymentMethod.stripe:
        return const Color(0xFF635BFF); // Stripe purple
      case PaymentMethod.googlePay:
        return const Color(0xFF4285F4); // Google blue
      case PaymentMethod.applePay:
        return Colors.white;
      case PaymentMethod.payPal:
        return const Color(0xFF0070BA); // PayPal blue
    }
  }
}

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onMethodSelected;
  final bool showApplePay; // Only show on iOS

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
    this.showApplePay = false,
  });

  @override
  Widget build(BuildContext context) {
    final methods = [
      PaymentMethod.stripe,
      PaymentMethod.googlePay,
      if (showApplePay) PaymentMethod.applePay,
      PaymentMethod.payPal,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.payments_outlined, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Payment Method',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...methods.map((method) => _buildMethodOption(method)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodOption(PaymentMethod method) {
    final isSelected = selectedMethod == method;

    return GestureDetector(
      onTap: () => onMethodSelected(method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    method.accentColor.withValues(alpha: 0.3),
                    method.accentColor.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? method.accentColor
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: method.accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                method.icon,
                color: method.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                method.displayName,
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: method.accentColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
