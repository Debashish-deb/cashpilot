library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/drift/app_database.dart' hide User;

import '../../../core/theme/tokens.g.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/subscription/providers/subscription_providers.dart';
import '../../../core/constants/subscription.dart';
import '../../../services/auth_service.dart';
import '../../../features/accounts/providers/account_providers.dart';
import '../../../features/expenses/providers/expense_providers.dart';
import '../../../features/banking/providers/bank_connectivity_provider.dart';
import '../../../core/utils/number_formatter.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

import '../settings/sections/sync_section.dart';
import '../settings/sections/data_sync_section.dart';
import '../settings/sections/danger_zone_section.dart';
import '../../widgets/settings/settings_group_card.dart';
import '../../widgets/settings/settings_selection_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _editingName = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initName();
  }

  void _initName() {
    final user = ref.read(authProvider).user;
    _nameController.text = user?.userMetadata?['name'] ??
        user?.userMetadata?['full_name'] ??
        user?.email?.split('@').first ??
        'User';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    // Data Providers
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final tierAsync = ref.watch(currentTierProvider);
    final tier = tierAsync.value ?? SubscriptionTier.free;
    
    // State Determination
    final allExpensesAsync = ref.watch(allExpensesProvider);
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
        bottom: TabBar(
          labelColor: AppColors.indigo600,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          indicatorColor: AppColors.indigo600,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: "OVERVIEW"),
            Tab(text: "INSIGHTS"),
            Tab(text: "SETTINGS"),
          ],
        ),
      ),
      body: SafeArea(
        child: allExpensesAsync.when(
          data: (expenses) {
            final isEmpty = expenses.isEmpty;
            return TabBarView(
              children: [
                // 1. OVERVIEW TAB
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(user, tier, l10n),
                      const SizedBox(height: 20),
                      _buildFinancialSnapshot(isEmpty, l10n),
                      const SizedBox(height: 16),
                      _buildSyncSecurityStatus(isEmpty, l10n),
                      const SizedBox(height: 16),
                      _buildFinancialConsistency(isEmpty, l10n, expenses),
                      const SizedBox(height: 32),
                      _buildMotivationFooter(isEmpty, l10n, user),
                    ],
                  ),
                ),

                // 2. INSIGHTS TAB
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildFinancialInsights(isEmpty, l10n),
                    ],
                  ),
                ),

                // 3. SETTINGS TAB
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildConnectedAccounts(l10n),
                      const SizedBox(height: 12),
                      const SyncSection(),
                      const SizedBox(height: 12),
                      const DataSyncSection(),
                      const SizedBox(height: 12),
                      SettingsGroupCard(
                        title: "ACCOUNT",
                        padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              SettingsSelectionButton(
                                label: l10n.settingsSignOut,
                                icon: Icons.logout_rounded,
                                isSelected: false,
                                onTap: _logout,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const DangerZoneSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, r) => Center(child: Text(l10n.commonErrorMessage(e.toString()))),
        ),
      ),
    ),
  );
}

  Widget _buildFinancialSnapshot(bool isEmpty, AppLocalizations l10n) {
    // Mock data for snapshot
    final netWorth = isEmpty ? "\$0.00" : "\$24,500";
    final monthlyFlow = isEmpty ? "\$0.00" : "+\$1,200";

    return SettingsGroupCard(
      title: "FINANCIAL SNAPSHOT",
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: "Net Worth",
                  value: netWorth,
                  helper: "+5% vs last month",
                  color: Colors.green,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MiniStat(
                  label: "Monthly Flow",
                  value: monthlyFlow,
                  helper: "Income > Expenses",
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Visual: Simple bar or progress
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 70,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(flex: 30, child: const SizedBox()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Assets: 70%",
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                "Liabilities: 30%",
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SECTION WIDGETS ---

  Color _getTierColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.proPlus: return AppColors.indigo600;
      case SubscriptionTier.pro: return AppColors.indigo400;
      default: return Colors.grey;
    }
  }



  Widget _buildSyncSecurityStatus(bool isEmpty, AppLocalizations l10n) {
    final accountsAsync = ref.watch(bankAccountStreamProvider);
    
    return _StatCard(
      padding: const EdgeInsets.all(16),
      child: accountsAsync.when(
        data: (accounts) {
          final isConnected = accounts.isNotEmpty;
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isConnected ? Theme.of(context).colorScheme.onSurface : const Color(0xFFF1F5F9)).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: isConnected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? l10n.profileLastSynced("2 mins ago") : l10n.profileBankNotConnected,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected ? "Securely connected via Nordigen" : l10n.profileSyncHelper,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isConnected)
                const _PulseButton(),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFinancialConsistency(bool isEmpty, AppLocalizations l10n, List<Expense> expenses) {
    if (isEmpty) return const SizedBox.shrink();

    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileFinancialConsistency.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ConsistencyItem(
                  label: l10n.profileStreak(4),
                  subLabel: l10n.profileConsistencyBetter,
                  icon: Icons.local_fire_department_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _ConsistencyItem(
                  label: l10n.profileActiveDays(5),
                  subLabel: "Expected: 7",
                  icon: Icons.calendar_today_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialInsights(bool isEmpty, AppLocalizations l10n) {
    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
              const SizedBox(width: 12),
              Text(
                l10n.profileFinancialInsight.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isEmpty ? l10n.profileInsightEmpty : "Your spending on 'Dining Out' is down 12% this month. At this rate, you'll reach your 'New Car' goal 3 weeks early.",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedAccounts(AppLocalizations l10n) {
    final accountsAsync = ref.watch(bankAccountStreamProvider);

    return SettingsGroupCard(
      title: l10n.profileConnectedAccounts.toUpperCase(),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: accountsAsync.when(
        data: (accounts) {
          final isConnected = accounts.isNotEmpty;
          return IntrinsicHeight(
            child: Row(
              children: [
                SettingsSelectionButton(
                  label: isConnected ? l10n.profileAccountsCount(accounts.length) : l10n.profileNoBankConnected,
                  icon: Icons.account_balance_rounded,
                  isSelected: isConnected, // Highlight if connected
                  onTap: () => context.push(AppRoutes.bankAccounts),
                ),
                // Add more actions if needed, or fill width
              ],
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }


  Widget _buildMotivationFooter(bool isEmpty, AppLocalizations l10n, User? user) {
    return Column(
      children: [
        Text(
          isEmpty ? l10n.profileMotivationEmpty : l10n.profileMotivationActive,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            height: 1.6,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.profileTrackingSince("Feb 2026"),
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildHeader(User? user, SubscriptionTier tier, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final tierColor = _getTierColor(tier);
    
    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedScale(
            scale: 1.0, // This would ideally be driven by a hover state, for now we'll match the design spec's intent
            duration: const Duration(milliseconds: 200),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ambient Glow
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indigo600.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                // Avatar Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indigo600.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [AppColors.indigo600, AppColors.indigo600.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ClipOval(
                    child: user?.userMetadata?['avatar_url'] != null
                        ? Image.network(
                            user!.userMetadata!['avatar_url'] as String,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              _getInitials(user),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _nameController.text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? 'guest@cashpilot.ai',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        _buildTierBadge(tier, l10n),
      ],
    );
  }

  Widget _buildTierBadge(SubscriptionTier tier, AppLocalizations l10n) {
    final label = tier == SubscriptionTier.proPlus ? "PRO PLUS" : tier == SubscriptionTier.pro ? "PRO" : "FREE";
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.indigo600, Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo600.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getInitials(User? user) {
    if (user == null) return "U";
    final name = user.userMetadata?['name'] as String? ?? user.email ?? "User";
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0].substring(0, 2).toUpperCase();
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _saveProfile() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    
    setState(() => _saving = true);
    try {
      await authService.updateProfile(name: _nameController.text.trim());
      if (mounted) {
        setState(() {
          _saving = false;
          _editingName = false;
        });
        AppSnackBar.showSuccess(context, AppLocalizations.of(context)!.profileUpdated);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackBar.showError(context, e.toString());
      }
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;
  final Color? color;

  const _MiniStat({
    required this.label,
    required this.value,
    this.helper,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 2),
          Text(
            helper!,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ],
    );
  }
}

class _ConsistencyItem extends StatelessWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final Color color;

  const _ConsistencyItem({
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subLabel, 
                style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class _StatCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _StatCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3); // Monochrome border

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
class _PulseButton extends StatefulWidget {
  const _PulseButton();

  @override
  State<_PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<_PulseButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnColor = isDark ? Colors.white : Colors.black;
    final updateTextColor = isDark ? Colors.black : Colors.white;

    return ScaleTransition(
      scale: _animation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutes.bankAccounts),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: btnColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: btnColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              "CONNECT",
              style: TextStyle(
                color: updateTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
