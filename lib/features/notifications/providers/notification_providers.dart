import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification.dart';

/// Stream of real-time notifications for the current user
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final client = Supabase.instance.client;
  // Assuming the user is authenticated, RLS will filter by auth.uid()
  return client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((list) => list.map((json) => AppNotification.fromJson(json)).toList());
});

/// Count of unread notifications
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

/// Actions for notifications
class NotificationActions {
  static Future<void> markAsRead(String id) async {
    await Supabase.instance.client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  static Future<void> markAllAsRead() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);
    }
  }

  /// Accept a Budget Invitation
  /// This updates the `budget_members` status to 'active'.
  static Future<void> acceptBudgetInvite(String budgetId) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) throw Exception('User not logged in');

    await Supabase.instance.client
        .from('budget_members')
        .update({'status': 'active'})
        .eq('budget_id', budgetId)
        .eq('user_id', uid);
  }

  /// Decline a Budget Invitation
  /// This removes the pending row from `budget_members`.
  static Future<void> declineBudgetInvite(String budgetId) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) throw Exception('User not logged in');

    await Supabase.instance.client
        .from('budget_members')
        .delete()
        .eq('budget_id', budgetId)
        .eq('user_id', uid);
  }
  
  /// Send an invite (Frontend helper acting as Repository)
  static Future<void> sendBudgetInvite(String email, String budgetId) async {
    // Call the Secure Postgres Function
    final res = await Supabase.instance.client.rpc('invite_user_to_budget', params: {
      'target_email': email,
      'target_budget_id': budgetId,
    });
    
    // Supabase RPC returns a dynamic specific to the function return type
    // If our function returns json or table, handling might vary. 
    // Usually rpc returns the data directly.
    if (res is Map && res['success'] == false) {
      throw Exception(res['message'] ?? 'Failed to invite user');
    }
  }
}
