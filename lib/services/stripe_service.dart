/// Stripe Payment Service
/// Handles payment processing via Stripe SDK
library;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import '../core/exceptions/payment_exception.dart';
import '../core/logging/logger.dart';
import '../core/services/error_reporter.dart';
import '../core/sync/idempotency_tracker.dart';

class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  final Logger _logger = Loggers.subscription;
  IdempotencyTracker? _idempotency;
  bool _initialized = false;

  // Stripe keys from environment
  static const String _publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  /// Initialize Stripe SDK
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize idempotency tracker
    try {
      final prefs = await SharedPreferences.getInstance();
      _idempotency = IdempotencyTracker(prefs);
    } catch (e) {
      _logger.warning('Failed to initialize idempotency tracker', context: {'error': e.toString()});
    }
    
    if (_publishableKey.isEmpty) {
      _logger.info('No Stripe publishable key - running in mock mode');
      return;
    }

    try {
      Stripe.publishableKey = _publishableKey;
      _initialized = true;
      _logger.info('Stripe initialized successfully');
      
      errorReporter.addBreadcrumb('Stripe initialized', category: 'payment');
    } catch (e, stack) {
      _logger.error('Stripe initialization failed', error: e, stackTrace: stack);
      await errorReporter.reportException(e, stackTrace: stack, context: {
        'operation': 'stripe_init',
      });
    }
  }

  /// Create a payment intent via Supabase Edge Function
  Future<String?> createPaymentIntent({
    required int amountInCents,
    String currency = 'eur',
  }) async {
    try {
      _logger.info('Creating payment intent', context: {
        'amount': amountInCents,
        'currency': currency,
      });
      
      final response = await authService.client.functions.invoke(
        'create-payment-intent',
        body: {
          'amount': amountInCents,
          'currency': currency,
        },
      );

      if (response.status != 200) {
        _logger.error('Payment intent creation failed', context: {
          'status': response.status,
          'response': response.data.toString(),
        });
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      _logger.info('Payment intent created successfully');
      return data['clientSecret'] as String?;
    } catch (e, stack) {
      _logger.error('Failed to create payment intent', error: e, stackTrace: stack);
      await errorReporter.reportException(e, stackTrace: stack, context: {
        'operation': 'create_payment_intent',
        'amount': amountInCents,
      });
      return null;
    }
  }

  /// Process a subscription payment with IDEMPOTENCY protection
  /// Returns true if successful
  Future<bool> processSubscription({
    required String planId,
    required int amountInCents,
  }) async {
    // Generate idempotency key to prevent duplicate payments
    final idempotencyKey = IdempotencyKey.forExpense(
      authService.currentUser?.id ?? 'anonymous',
      'subscription_$planId',
    );

    // Check if already processed
    if (_idempotency != null && await _idempotency!.wasExecuted(idempotencyKey)) {
      _logger.info('Payment already processed (idempotent skip)', context: {
        'planId': planId,
        'key': idempotencyKey,
      });
      return true;
    }

    if (!_initialized) {
      _logger.error('Stripe not initialized - payment unavailable');
      throw PaymentException(
        'Payment system is not configured. Please contact support.',
      );
    }

    _logger.info('Processing subscription payment', context: {
      'planId': planId,
      'amount': amountInCents,
    });
    
    errorReporter.addBreadcrumb('Payment started', category: 'payment', data: {
      'planId': planId,
      'amount': amountInCents,
    });

    try {
      // 1. Create payment intent
      final clientSecret = await createPaymentIntent(
        amountInCents: amountInCents,
      );

      if (clientSecret == null) {
        _logger.error('Failed to create payment intent');
        return false;
      }

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'CashPilot',
          style: ThemeMode.system,
        ),
      );

      // 3. Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Mark as successfully executed (idempotency)
      if (_idempotency != null) {
        await _idempotency!.markExecuted(idempotencyKey);
      }

      _logger.info('Payment completed successfully', context: {
        'planId': planId,
      });
      
      errorReporter.addBreadcrumb('Payment completed', category: 'payment', data: {
        'planId': planId,
        'success': true,
      });
      
      return true;
    } on StripeException catch (e, stack) {
      _logger.error('Stripe payment failed', error: e, stackTrace: stack, context: {
        'planId': planId,
        'message': e.error.message,
      });
      
      await errorReporter.reportException(e, stackTrace: stack, context: {
        'operation': 'process_subscription',
        'planId': planId,
        'stripeError': e.error.message,
      });
      
      return false;
    } catch (e, stack) {
      _logger.error('Payment failed', error: e, stackTrace: stack, context: {
        'planId': planId,
      });
      
      await errorReporter.reportException(e, stackTrace: stack, context: {
        'operation': 'process_subscription',
        'planId': planId,
      });
      
      return false;
    }
  }

  /// Check if Stripe is available
  bool get isAvailable => _initialized;
}

/// Global stripe service instance
final stripeService = StripeService();
