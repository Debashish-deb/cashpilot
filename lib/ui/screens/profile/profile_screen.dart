/// Profile Screen - Premium Design
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/subscription/providers/subscription_providers.dart';
import '../../../core/constants/subscription.dart';
import '../../../services/auth_service.dart';
import '../../../ui/widgets/common/glass_card.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

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
    final user = ref.read(authProvider).user;
    _nameController.text = user?.userMetadata?['name'] ??
        user?.userMetadata?['full_name'] ??
        user?.email?.split('@').first ??
        AppLocalizations.of(context)?.profileGuestUser ?? 'User';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final tierAsync = ref.watch(currentTierProvider);
    final user = authState.user;
    final tier = tierAsync.value ?? SubscriptionTier.free;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsProfile, style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(user, tier),
            const SizedBox(height: 32),

            // Name Editor Card
            _buildNameCard(),
            const SizedBox(height: 16),

            // Subscription Card
            _buildSubscriptionCard(tier),
            const SizedBox(height: 16),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user, SubscriptionTier tier) {
    final tierColor = tier == SubscriptionTier.proPlus
        ? AppColors.primaryGold
        : tier == SubscriptionTier.pro
            ? AppColors.primaryGreen
            : Colors.grey;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tierColor.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            // Avatar with border
            Container(
              width: 110,
              height: 110,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [tierColor, tierColor.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                backgroundImage: user?.userMetadata?['avatar_url'] != null
                    ? NetworkImage(user!.userMetadata!['avatar_url'] as String)
                    : null,
                child: user?.userMetadata?['avatar_url'] == null
                    ? Icon(Icons.person, size: 50, color: Theme.of(context).iconTheme.color)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _nameController.text,
          style: AppTypography.headlineLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? 'guest@cashpilot.app',
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        _buildTierBadge(tier),
      ],
    );
  }

  Widget _buildTierBadge(SubscriptionTier tier) {
    final l10n = AppLocalizations.of(context)!;
    final config = {
      SubscriptionTier.proPlus: (
        label: l10n.settingsProPlus,
        icon: Icons.star_rounded,
        color: AppColors.primaryGold,
      ),
      SubscriptionTier.pro: (
        label: l10n.commonPro,
        icon: Icons.bolt_rounded,
        color: AppColors.primaryGreen,
      ),
      SubscriptionTier.free: (
        label: l10n.settingsFree.toUpperCase(),
        icon: Icons.person_outline,
        color: Colors.grey,
      ),
    }[tier]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.color.withValues(alpha: 0.2),
            config.color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: config.color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 16, color: config.color),
          const SizedBox(width: 8),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameCard() {
    final l10n = AppLocalizations.of(context)!;
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_rounded, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Display Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              if (!_editingName)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  onPressed: () => setState(() => _editingName = true),
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_editingName) ...[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: l10n.profileEnterName,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _editingName = false);
                      final user = ref.read(authProvider).user;
                      _nameController.text = user?.userMetadata?['name'] ??
                          user?.email?.split('@').first ??
                          'User';
                    },
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _saveProfile,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.commonSave),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              l10n.profileSharingNote,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(SubscriptionTier tier) {
    final l10n = AppLocalizations.of(context)!;
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.workspace_premium_rounded,
              color: tier == SubscriptionTier.free ? Colors.grey : AppColors.primaryGold,
            ),
            title: Text(l10n.settingsSubscription),
            subtitle: Text(tier.name.toUpperCase()),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.paywall),
          ),
          Divider(height: 1, indent: 72, color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
          ListTile(
            leading: Icon(Icons.cloud_done_rounded, color: Theme.of(context).primaryColor),
            title: Text(l10n.settingsCloudSync),
            subtitle: Text(l10n.profileSyncStatus),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final l10n = AppLocalizations.of(context)!;
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: Text(l10n.settingsTitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.settings),
          ),
          Divider(height: 1, indent: 72, color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: AppColors.danger),
            title: Text(l10n.settingsSignOut, style: TextStyle(color: AppColors.danger)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
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

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }
}
