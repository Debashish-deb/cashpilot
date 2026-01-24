/// Email Service
/// Sends emails via Supabase Edge Function (Resend)
library;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  /// Send a budget invitation email
  Future<bool> sendBudgetInvite({
    required String toEmail,
    required String inviterName,
    required String budgetName,
  }) async {
    try {
      final response = await authService.client.functions.invoke(
        'resend-email/resend/send-template',
        body: {
          'to': toEmail,
          'template_id': 'budget_invite', // Create this template in Resend dashboard
          'variables': {
            'inviter_name': inviterName,
            'budget_name': budgetName,
            'app_name': 'CashPilot',
          },
          'idempotency_key': '${toEmail}_${budgetName}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
        },
      );

      if (response.status == 200) {
        if (kDebugMode) {
          debugPrint('[EmailService] Invite sent to $toEmail');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('[EmailService] Failed to send invite: ${response.status} ${response.data}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EmailService] Error sending invite: $e');
      }
      return false;
    }
  }

  /// Send a custom email
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String html,
    String? text,
  }) async {
    try {
      final response = await authService.client.functions.invoke(
        'resend-email/resend/send',
        body: {
          'to': to,
          'subject': subject,
          'html': html,
          'text': text,
        },
      );

      return response.status == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EmailService] Error sending email: $e');
      }
      return false;
    }
  }
}

/// Global instance
final emailService = EmailService();
