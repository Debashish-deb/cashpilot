/// Bank Connection Service
/// Handles GoCardless bank account integration for Pro Plus users
library;

import '../core/utils/logger.dart';
import 'auth_service.dart';
import 'subscription_service.dart';

class BankConnectionService {
  static final BankConnectionService _instance = BankConnectionService._internal();
  factory BankConnectionService() => _instance;
  BankConnectionService._internal();

  final _client = authService.client;

  /// Get available banks for a country
  Future<List<BankInstitution>> getInstitutions(String countryCode) async {
    try {
      final response = await _client.functions.invoke(
        'yapily-list-institutions',
        body: {'country': countryCode},
      );

      if (response.status != 200) {
        throw Exception('Failed to fetch institutions');
      }

      final responseData = response.data as Map<String, dynamic>;
      final institutions = responseData['institutions'] as List;
      return institutions.map((e) => BankInstitution.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      logger.error('Failed to fetch institutions', category: LogCategory.feature, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Initiate bank connection
  Future<BankConnectionInit> initiateConnection({
    required String institutionId,
    required String redirectUrl,
  }) async {
    // Verify Pro Plus subscription
    if (!subscriptionService.isProPlus) {
      throw Exception('Bank connectivity requires Pro Plus subscription');
    }

    final response = await _client.functions.invoke(
      'yapily-init-connection',
      body: {
        'institution_id': institutionId,
        'callback_url': redirectUrl,
        'user_uuid': authService.currentUser?.id,
      },
    );

    if (response.status != 200) {
      final error = response.data is Map ? response.data['error'] : 'Unknown error';
      throw Exception('Failed to initiate connection: $error');
    }

    return BankConnectionInit.fromJson(response.data as Map<String, dynamic>);
  }

  /// Sync accounts after user completes auth
  Future<void> syncAccounts(String requisitionId) async {
    final response = await _client.functions.invoke(
      'yapily-sync-accounts',
      body: {'requisition_id': requisitionId},
    );
    
    if (response.status != 200) {
      final error = response.data is Map ? response.data['error'] : 'Unknown error';
      throw Exception('Failed to sync accounts: $error');
    }
  }

  /// Get user's connected accounts
  /// Note: RLS policies automatically filter by user_id
  Stream<List<BankAccount>> watchBankAccounts() {
    return _client
        .from('bank_accounts')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((e) => e['is_active'] == true)
            .map((e) => BankAccount.fromJson(e))
            .toList());
  }

  /// Get transactions for an account
  Future<List<BankTransaction>> getTransactions(String accountId, {int days = 90}) async {
    final response = await _client
        .from('bank_transactions')
        .select()
        .eq('account_id', accountId)
        .gte('booking_date', DateTime.now().subtract(Duration(days: days)).toIso8601String())
        .order('booking_date', ascending: false);

    return (response as List).map((e) => BankTransaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Disconnect a bank connection
  Future<void> disconnect(String connectionId) async {
    await _client
        .from('bank_connections')
        .update({'status': 'expired'})
        .eq('id', connectionId);
  }
}

final bankConnectionService = BankConnectionService();

// Models
class BankInstitution {
  final String id;
  final String name;
  final String? logo;
  final String countryCode;

  BankInstitution({
    required this.id,
    required this.name,
    this.logo,
    required this.countryCode,
  });

  factory BankInstitution.fromJson(Map<String, dynamic> json) => BankInstitution(
        id: json['id'] as String,
        name: json['name'] as String,
        logo: json['logo'] as String?,
        countryCode: (json['countries'] as List?)?.isNotEmpty == true 
            ? json['countries'][0] as String 
            : 'GB',
      );
}

class BankConnectionInit {
  final String requisitionId;
  final String authLink;

  BankConnectionInit({required this.requisitionId, required this.authLink});

  factory BankConnectionInit.fromJson(Map<String, dynamic> json) =>
      BankConnectionInit(
        requisitionId: json['requisition_id'] as String,
        authLink: json['auth_link'] as String,
      );
}

class BankAccount {
  final String id;
  final String accountId;
  final String? iban;
  final String? accountName;
  final String currency;
  final double? balanceAmount;

  BankAccount({
    required this.id,
    required this.accountId,
    this.iban,
    this.accountName,
    required this.currency,
    this.balanceAmount,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
        id: json['id'] as String,
        accountId: json['account_id'] as String,
        iban: json['iban'] as String?,
        accountName: json['account_name'] as String?,
        currency: json['currency'] as String,
        balanceAmount: json['balance_amount'] != null 
            ? (json['balance_amount'] as num).toDouble() 
            : null,
      );
}

class BankTransaction {
  final String id;
  final String accountId;
  final double amount;
  final String currency;
  final DateTime bookingDate;
  final String? description;
  final String? creditorName;
  final bool isReconciled;

  BankTransaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.currency,
    required this.bookingDate,
    this.description,
    this.creditorName,
    required this.isReconciled,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) => BankTransaction(
        id: json['id'] as String,
        accountId: json['account_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        bookingDate: DateTime.parse(json['booking_date'] as String),
        description: json['description'] as String?,
        creditorName: json['creditor_name'] as String?,
        isReconciled: json['is_reconciled'] as bool? ?? false,
      );
}
