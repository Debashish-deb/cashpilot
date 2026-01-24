/// Bank Connection Flow Screen
/// Guides user through connecting their bank via GoCardless
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../../services/bank_connection_service.dart';
import 'bank_auth_webview_screen.dart';

class BankConnectionFlowScreen extends ConsumerStatefulWidget {
  const BankConnectionFlowScreen({super.key});

  @override
  ConsumerState<BankConnectionFlowScreen> createState() => _BankConnectionFlowScreenState();
}

class _BankConnectionFlowScreenState extends ConsumerState<BankConnectionFlowScreen> {
  String _selectedCountry = 'GB';
  BankInstitution? _selectedBank;
  bool _isLoading = false;

  static const _countries = [
    {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪'},
    {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
    {'code': 'ES', 'name': 'Spain', 'flag': '🇪🇸'},
    {'code': 'IT', 'name': 'Italy', 'flag': '🇮🇹'},
    {'code': 'NL', 'name': 'Netherlands', 'flag': '🇳🇱'},
    {'code': 'BE', 'name': 'Belgium', 'flag': '🇧🇪'},
    {'code': 'IE', 'name': 'Ireland', 'flag': '🇮🇪'},
    {'code': 'PT', 'name': 'Portugal', 'flag': '🇵🇹'},
    {'code': 'AT', 'name': 'Austria', 'flag': '🇦🇹'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Your Bank'),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: theme.colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.account_balance,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Automatic Transaction Sync',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Securely connect your bank to automatically import transactions.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Select Country
                  Text(
                    'Step 1: Select Your Country',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCountrySelector(theme),
                  
                  const SizedBox(height: 32),
                  
                  // Step 2: Select Bank
                  Text(
                    'Step 2: Select Your Bank',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBankSelector(theme),
                  
                  if (_selectedBank != null) ...[
                    const SizedBox(height: 32),
                    _buildConnectButton(theme),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountrySelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCountry,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: _countries.map((country) {
          return DropdownMenuItem(
            value: country['code'],
            child: Text('${country['flag']} ${country['name']}'),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedCountry = value;
              _selectedBank = null; // Reset bank selection
            });
          }
        },
      ),
    );
  }

  Widget _buildBankSelector(ThemeData theme) {
    final institutionsAsync = ref.watch(institutionsProvider(_selectedCountry));
    
    return institutionsAsync.when(
      data: (institutions) {
        if (institutions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No banks available for this country yet.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          );
        }
        
        return Column(
          children: institutions.map((bank) {
            final isSelected = _selectedBank?.id == bank.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected 
                      ? theme.colorScheme.primary 
                      : theme.dividerColor,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected 
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : null,
              ),
              child: ListTile(
                leading: bank.logo != null 
                    ? Image.network(
                        bank.logo!,
                        width: 40,
                        height: 40,
                        errorBuilder: (_, __, ___) => const Icon(Icons.account_balance),
                      )
                    : const Icon(Icons.account_balance),
                title: Text(
                  bank.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
                trailing: isSelected 
                    ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                    : null,
                onTap: () => setState(() => _selectedBank = bank),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Error loading banks: $e',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildConnectButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleConnect,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Connect Bank'),
      ),
    );
  }

  Future<void> _handleConnect() async {
    if (_selectedBank == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Initiate connection
      final init = await bankConnectionService.initiateConnection(
        institutionId: _selectedBank!.id,
        redirectUrl: 'cashpilot://bank-callback',
      );
      
      // Open bank auth in WebView
      if (!mounted) return;
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => BankAuthWebViewScreen(
            authUrl: init.authLink,
            requisitionId: init.requisitionId,
          ),
        ),
      );
      
      if (success == true && mounted) {
        // Sync accounts
        await bankConnectionService.syncAccounts(init.requisitionId);
        
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Bank connected successfully!');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to connect bank: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Provider for bank institutions
final institutionsProvider =
    FutureProvider.family<List<BankInstitution>, String>((ref, country) async {
  return bankConnectionService.getInstitutions(country);
});
