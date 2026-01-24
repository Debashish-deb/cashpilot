/// Bank Accounts Screen
/// Displays connected bank accounts and transactions
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../services/bank_connection_service.dart';
import '../../widgets/common/empty_state.dart';

class BankAccountsScreen extends ConsumerWidget {
  const BankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accountsStream = bankConnectionService.watchBankAccounts();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.bankConnectionFlow),
            tooltip: 'Connect Bank',
          ),
        ],
      ),
      body: StreamBuilder<List<BankAccount>>(
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
          context.push('${AppRoutes.bankTransactions}/${account.accountId}');
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
                  Icons.account_balance_wallet,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.accountName ?? account.iban ?? 'Bank Account',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (account.iban != null)
                      Text(
                        account.iban!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    account.balanceAmount != null
                        ? '${account.currency} ${account.balanceAmount!.toStringAsFixed(2)}'
                        : 'N/A',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Balance',
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
}
