/// Bank Accounts Screen
/// Displays connected bank accounts and transactions
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/providers/app_providers.dart';
import '../../../services/bank_connection_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../../core/utils/app_snackbar.dart';

class BankAccountsScreen extends ConsumerStatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  ConsumerState<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends ConsumerState<BankAccountsScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // Trigger auto-sync on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = ref.read(databaseProvider);
      bankConnectionService.triggerAutoSync(db);
    });
  }

  Future<void> _handleManualSync() async {
    setState(() => _isSyncing = true);
    try {
      final db = ref.read(databaseProvider);
      await bankConnectionService.triggerManualSync(db);
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Bank data synced successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Sync failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountsStream = bankConnectionService.watchBankAccounts();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bankingTitle),
        actions: [
          IconButton(
            icon: _isSyncing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isSyncing ? null : _handleManualSync,
            tooltip: 'Sync Now',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.bankConnectionFlow),
            tooltip: 'Connect Bank',
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<BankAccount>>(
          stream: accountsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading accounts',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            
            final accounts = snapshot.data ?? [];
            
            if (accounts.isEmpty) {
              return EmptyState(
                title: 'No Banks Connected',
                message: 'Connect your bank to automatically sync transactions and track spending in real-time.',
                icon: Icons.account_balance,
                buttonLabel: 'Connect Bank',
                onAction: () => context.push(AppRoutes.bankConnectionFlow),
                useGlass: true,
              );
            }
            
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final account = accounts[index];
                return _BankAccountCard(account: account);
              },
            );
          },
        ),
      ),
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  final BankAccount account;

  const _BankAccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to transactions for this account
          context.pushNamed(
            'bank-transactions',
            pathParameters: {'accountId': account.accountId},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getAccountIcon(account.accountType),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            account.accountName ?? account.iban ?? 'Bank Account',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (account.accountType != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              account.accountType!.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (account.lastSyncAt != null)
                      Text(
                        'Updated ${_getTimeAgo(account.lastSyncAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      )
                    else
                      Text(
                        'Never synced',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    
                    if (account.consentExpiry != null && account.consentExpiry!.isBefore(DateTime.now()))
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'REAUTH REQUIRED',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.7,
                        child: Switch.adaptive(
                          value: account.isActive,
                          onChanged: (value) async {
                            await bankConnectionService.toggleAccountActive(account.id, value);
                          },
                          activeThumbColor: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        account.balanceAmount != null
                            ? '${account.currency} ${account.balanceAmount!.toStringAsFixed(2)}'
                            : 'N/A',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: account.isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.isActive ? 'Active Balance' : 'Sync Disabled',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'just now';
  }

  IconData _getAccountIcon(String? type) {
    if (type == null) return Icons.account_balance_wallet;
    
    final t = type.toLowerCase();
    if (t.contains('credit')) return Icons.credit_card;
    if (t.contains('save') || t.contains('saving')) return Icons.savings;
    if (t.contains('checking') || t.contains('current')) return Icons.account_balance;
    
    return Icons.account_balance_wallet;
  }
}
