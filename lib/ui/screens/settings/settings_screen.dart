/// Settings Screen - Modular V2
/// 
/// Coordinators logic for settings sections.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

// Sections
import 'sections/profile_card.dart';
import 'sections/subscription_section.dart';
import 'sections/preferences_section.dart';
import 'sections/data_sync_section.dart';
import 'sections/security_section.dart';
import 'sections/danger_zone_section.dart';
import 'sections/about_section.dart';
import '../../../features/settings/viewmodels/settings_view_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settingsState = ref.watch(settingsViewModelProvider);

    // Listen for error messages
    ref.listen(settingsViewModelProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(settingsViewModelProvider.notifier).clearError();
      }
    });

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(l10n.settingsTitle),
            centerTitle: true,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(180), // Space for Profile + Tabs
              child: Column(
                children: [
                  // Profile Section
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: ProfileCard(),
                  ),
                  
                  // Custom Tab Selector
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 0.5,
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              color: isDark 
                                  ? theme.colorScheme.primary.withValues(alpha: 0.9)
                                  : theme.colorScheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.4 : 0.3),
                                  blurRadius: 12,
                                  spreadRadius: -2,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: -0.3,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                            padding: const EdgeInsets.all(3),
                            tabs: [
                              Tab(text: l10n.settingsTabGeneral),
                              Tab(text: l10n.settingsTabAdvanced),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              _GeneralTab(),
              _AdvancedTab(),
            ],
          ),
        ),
        if (settingsState.isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _GeneralTab extends StatelessWidget {
  const _GeneralTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: const [
        SubscriptionSection(),
        SizedBox(height: 24),
        PreferencesSection(),
        SizedBox(height: 24),
        DataSyncSection(), // Basic Sync Toggle
        SizedBox(height: 24),
        AboutSection(),
        SizedBox(height: 100),
      ],
    );
  }
}

class _AdvancedTab extends StatelessWidget {
  const _AdvancedTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: const [
        SecuritySection(),
        SizedBox(height: 24),
        // Sync & Data Management could go here if different from simple toggle
        // For now, Security acts as the main "Advanced" feature implemented
        DangerZoneSection(),
        SizedBox(height: 100),
      ],
    );
  }
}
