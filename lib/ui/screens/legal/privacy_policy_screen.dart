/// Privacy Policy Screen
/// GDPR & Google Play compliant with OLED glassmorphism styling
library;

import 'dart:ui';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Glassmorphism App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.8),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    background: Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 32,
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.crossAxisExtent < 360 ? 16.0 : 20.0;
              return SliverPadding(
                padding: EdgeInsets.all(horizontalPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildLastUpdated(context, isDark),
                const SizedBox(height: 24),
                
                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.info_outline,
                  title: '1. Introduction',
                  content: '''
CashPilot ("we", "our", or "us") respects your privacy and is committed to protecting your personal data. This privacy policy explains how we collect, use, store, and protect your information in compliance with the General Data Protection Regulation (GDPR) and other applicable data protection laws.

By using CashPilot, you agree to the collection and use of information in accordance with this policy.''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.storage_outlined,
                  title: '2. Data We Collect',
                  content: '''
We collect the following types of data:

**Account Data:**
• Email address (for authentication)
• Display name (optional)
• Profile picture (optional)

**Financial Data:**
• Budget information you create
• Expense records you enter
• Category preferences
• Currency settings

**Device Data:**
• Device identifier (for sync)
• Operating system version
• App version

**Usage Data:**
• Feature usage analytics (anonymized)
• Crash reports (for app stability)''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.lock_outline,
                  title: '3. How We Protect Your Data',
                  content: '''
Your data security is our priority:

• **End-to-End Encryption:** All sensitive financial data is encrypted using AES-256 before leaving your device
• **Secure Storage:** Data is stored in encrypted databases (SQLCipher)
• **Secure Transfer:** All network communications use TLS 1.3
• **Zero-Knowledge:** We cannot read your encrypted financial data
• **Biometric Protection:** Optional biometric lock for app access''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.gavel_outlined,
                  title: '4. Legal Basis (GDPR Article 6)',
                  content: '''
We process your data based on:

• **Consent:** You provide explicit consent when creating an account
• **Contract:** Processing necessary to provide our services
• **Legitimate Interest:** Improving our services and preventing fraud

You can withdraw consent at any time by deleting your account.''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.verified_user_outlined,
                  title: '5. Your Rights (GDPR)',
                  content: '''
Under GDPR, you have the right to:

✓ **Access:** Request a copy of your personal data
✓ **Rectification:** Correct inaccurate data
✓ **Erasure:** Request deletion of your data ("right to be forgotten")
✓ **Portability:** Export your data in a machine-readable format
✓ **Restriction:** Limit how we process your data
✓ **Object:** Object to processing based on legitimate interest
✓ **Withdraw Consent:** Revoke previously given consent

To exercise these rights, contact us at privacy@cashpilot.app''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.share_outlined,
                  title: '6. Data Sharing',
                  content: '''
We do NOT sell your personal data. We may share data with:

• **Service Providers:** Cloud hosting (Supabase), payment processing (Stripe)
• **Legal Requirements:** When required by law or court order
• **With Your Consent:** Only when you explicitly agree

All third parties are GDPR-compliant and bound by data processing agreements.''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.access_time_outlined,
                  title: '7. Data Retention',
                  content: '''
We retain your data:

• **Active Account:** As long as your account is active
• **Deleted Account:** Up to 30 days (for recovery), then permanently deleted
• **Anonymized Analytics:** May be retained indefinitely

You can request immediate deletion at any time.''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.child_care_outlined,
                  title: '8. Children\'s Privacy',
                  content: '''
CashPilot is not intended for children under 16. We do not knowingly collect data from children. If you believe a child has provided us data, contact us immediately.''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.public_outlined,
                  title: '9. International Transfers',
                  content: '''
Your data may be processed in the European Economic Area (EEA) and other countries. We ensure adequate protection through:

• Standard Contractual Clauses (SCCs)
• GDPR-compliant service providers
• Encryption of data in transit and at rest''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.email_outlined,
                  title: '10. Contact Us',
                  content: '''
Data Protection Officer:
Email: privacy@cashpilot.app

Supervisory Authority:
You have the right to lodge a complaint with your local data protection authority.''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.account_balance_outlined,
                  title: '11. Open Banking & Financial Data Consent',
                  content: '''
When you enable Bank Connectivity, you explicitly consent to CashPilot accessing your transaction history via our regulated partner, Nordigen (a GoCardless company). 

**Key Consent Terms:**
• **Access Purpose:** Solely for expense tracking and budgeting.
• **No Credentials Stored:** Your bank login credentials are never stored or seen by CashPilot.
• **Data Retention:** Bank transactions are stored locally and encrypted in your cloud sync.
• **90-Day Renewal:** You must re-authorize access every 90 days as per PSD2 regulations.
• **Revocation:** You can disable connectivity or delete account links at any time in Settings.''',
                ),

                const SizedBox(height: 32),
                _buildAcceptButton(context, isDark, theme),
                const SizedBox(height: 40),
              ]),
            ))
            ;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.update,
            size: 18,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
          const SizedBox(width: 12),
          Text(
            'Last Updated: December 20, 2024',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content.trim(),
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'I Understand',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
