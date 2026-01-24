/// Terms of Service Screen
/// GDPR & Google Play compliant with OLED glassmorphism styling
library;

import 'dart:ui';
import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : theme.scaffoldBackgroundColor,
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
                      'Terms of Service',
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
                        Icons.description_outlined,
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
                  icon: Icons.handshake_outlined,
                  title: '1. Agreement to Terms',
                  content: '''
By downloading, installing, or using CashPilot ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree, do not use the App.

These Terms constitute a legally binding agreement between you and CashPilot ("Company", "we", "us").''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.app_registration_outlined,
                  title: '2. Use of the Service',
                  content: '''
**Eligibility:**
• You must be at least 16 years old
• You must provide accurate account information
• You are responsible for maintaining account security

**Permitted Use:**
• Personal finance tracking and budgeting
• Family expense sharing (with consent)
• Data backup and synchronization

**Prohibited Use:**
• Illegal activities or fraud
• Circumventing security measures
• Sharing account credentials
• Automated data scraping
• Reverse engineering the App''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.account_circle_outlined,
                  title: '3. User Accounts',
                  content: '''
**Account Creation:**
You may create an account using email or social authentication. You agree to:
• Provide accurate information
• Keep your password secure
• Notify us of unauthorized access
• Not share your account

**Account Termination:**
We may suspend or terminate accounts that:
• Violate these Terms
• Engage in fraudulent activity
• Remain inactive for extended periods
• Are used for illegal purposes''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.payment_outlined,
                  title: '4. Subscriptions & Payments',
                  content: '''
**Free Tier:**
Basic features are available at no cost.

**Premium Subscriptions:**
• Pro and Pro+ plans unlock additional features
• Prices are displayed before purchase
• Subscriptions auto-renew unless cancelled
• Refunds follow app store policies

**Cancellation:**
• Cancel anytime via app store settings
• Access continues until period ends
• No partial refunds for unused time

**Price Changes:**
We may change prices with 30 days notice.''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.copyright_outlined,
                  title: '5. Intellectual Property',
                  content: '''
**Our Property:**
CashPilot, including its code, design, content, and trademarks, is owned by us and protected by intellectual property laws.

**Your Content:**
You retain ownership of data you enter. By using the App, you grant us a license to store, process, and display your data to provide our services.

**Restrictions:**
You may not:
• Copy or modify the App
• Create derivative works
• Use our trademarks without permission''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.security_outlined,
                  title: '6. Privacy & Data Protection',
                  content: '''
Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your data.

**Key Points:**
• Data is encrypted end-to-end
• We do not sell your data
• You can export or delete your data
• We comply with GDPR and CCPA

See our Privacy Policy for full details.''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.warning_amber_outlined,
                  title: '7. Disclaimers',
                  content: '''
**No Financial Advice:**
CashPilot is a budgeting tool, NOT a financial advisor. We do not provide investment, tax, or legal advice.

**Accuracy:**
While we strive for accuracy, we do not guarantee:
• Error-free operation
• Uninterrupted service
• Data accuracy (user-entered data)

**Third-Party Services:**
We are not responsible for third-party services (payment processors, cloud providers).''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.gavel_outlined,
                  title: '8. Limitation of Liability',
                  content: '''
TO THE MAXIMUM EXTENT PERMITTED BY LAW:

• We are not liable for indirect, incidental, or consequential damages
• Our total liability is limited to fees paid in the last 12 months
• We are not liable for data loss (maintain your own backups)

This does not affect your statutory rights under European consumer law.''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.shield_outlined,
                  title: '9. Indemnification',
                  content: '''
You agree to indemnify and hold us harmless from claims arising from:
• Your use of the App
• Violation of these Terms
• Infringement of third-party rights
• Your user content''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.edit_note_outlined,
                  title: '10. Changes to Terms',
                  content: '''
We may modify these Terms at any time. Changes will be:
• Posted in the App
• Effective 30 days after posting
• Notified via email for material changes

Continued use after changes constitutes acceptance.''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.balance_outlined,
                  title: '11. Governing Law',
                  content: '''
These Terms are governed by the laws of the European Union and specifically:
• For EU residents: Your local consumer protection laws apply
• Disputes will be resolved in EU courts

For non-EU users, Finnish law applies with disputes resolved in Helsinki courts.''',
                ),

                _buildSection(
                  context,
                  isDark: isDark,
                  icon: Icons.contact_mail_outlined,
                  title: '12. Contact Information',
                  content: '''
CashPilot
Email: legal@cashpilot.app
Support: support@cashpilot.app

For GDPR inquiries: privacy@cashpilot.app''',
                ),

                const SizedBox(height: 32),
                _buildAcceptButton(context, isDark, theme),
                const SizedBox(height: 40),
              ]),
            )
              );
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
            'Effective: December 20, 2024',
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
                  'I Accept These Terms',
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
