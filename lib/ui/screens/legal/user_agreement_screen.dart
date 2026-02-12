import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

/// Types of legal documents supported
enum LegalDocType {
  userAgreement,
  termsOfService,
  privacyPolicy,
}

/// User Agreement / Terms Screen (Upgraded)
/// - Premium reading experience (progress + sections)
/// - Optional "must scroll to end" gating
/// - Acceptance checkbox + persistence (SharedPreferences)
/// - Feature-aware, honest security language
class UserAgreementScreen extends StatefulWidget {
  const UserAgreementScreen({
    super.key,
    this.requireScrollToEnd = true,
    this.requireCheckbox = true,
    this.persistAcceptance = true,
    this.acceptanceKey = 'user_agreement_accepted_v2025_12',
    this.onAccepted,
    this.onDeclined,
    this.initiallyAccepted = false,

    /// Feature flags to keep legal text truthful.
    /// Set these based on what you ACTUALLY implemented.
    this.localDbEncrypted = false,
    this.clientSideEncryptBeforeSync = false,
    this.cloudSyncUsesTls = true,
    this.usesSupabase = true,
    this.type = LegalDocType.userAgreement,
  });

  /// Which document to display
  final LegalDocType type;

  /// If true: user must scroll near the end before enabling acceptance.
  final bool requireScrollToEnd;

  /// If true: user must tick a checkbox before enabling acceptance.
  final bool requireCheckbox;

  /// Persist acceptance in SharedPreferences.
  final bool persistAcceptance;

  /// Storage key for acceptance persistence. Bump when terms change.
  final String acceptanceKey;

  /// Optional callbacks.
  final VoidCallback? onAccepted;
  final VoidCallback? onDeclined;

  /// If coming from a flow that already checked acceptance.
  final bool initiallyAccepted;

  /// Truthful capability flags (do NOT overclaim).
  final bool localDbEncrypted;
  final bool clientSideEncryptBeforeSync;
  final bool cloudSyncUsesTls;
  final bool usesSupabase;

  @override
  State<UserAgreementScreen> createState() => _UserAgreementScreenState();
}

class _UserAgreementScreenState extends State<UserAgreementScreen> {
  final _scrollController = ScrollController();

  bool _nearEnd = false;
  bool _checked = false;
  bool _loadingPrefs = true;
  bool _alreadyAccepted = false;
  DateTime? _acceptedAt;

  // Simple “reading progress” 0..1
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _checked = widget.initiallyAccepted;
    _loadAccepted();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String get _effectiveKey => '${widget.acceptanceKey}_${widget.type.name}';

  Future<void> _loadAccepted() async {
    if (!widget.persistAcceptance) {
      if (mounted) setState(() => _loadingPrefs = false);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check both the specific key and the legacy/base key for migration/compatibility
      final accepted = prefs.getBool(_effectiveKey) ?? 
                      prefs.getBool(widget.acceptanceKey) ?? 
                      false;
      
      final acceptedTs = prefs.getString('${_effectiveKey}_ts');
      
      if (mounted) {
        setState(() {
          _alreadyAccepted = accepted;
          _checked = _checked || accepted;
          if (accepted) {
            _nearEnd = true; // Waive scroll requirement if already accepted
            if (acceptedTs != null) {
              _acceptedAt = DateTime.tryParse(acceptedTs);
            }
          }
          _loadingPrefs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPrefs = false);
    }
  }

  Future<void> _persistAccepted(bool value) async {
    if (!widget.persistAcceptance) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_effectiveKey, value);
    if (value) {
      await prefs.setString('${_effectiveKey}_ts', DateTime.now().toIso8601String());
    } else {
      await prefs.remove('${_effectiveKey}_ts');
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final pos = _scrollController.position;
    final maxExtent = math.max(pos.maxScrollExtent, 1.0);
    final p = (pos.pixels / maxExtent).clamp(0.0, 1.0);

    // Near-end threshold: last ~6% (tweakable)
    final nearEndNow = pos.pixels >= (pos.maxScrollExtent * 0.94);

    if (p != _progress || nearEndNow != _nearEnd) {
      if (mounted) {
        setState(() {
          _progress = p;
          _nearEnd = nearEndNow || pos.maxScrollExtent == 0;
        });
      }
    }
  }

  bool get _canAccept {
    if (_loadingPrefs) return false;
    if (widget.requireCheckbox && !_checked) return false;
    if (widget.requireScrollToEnd && !_nearEnd) return false;
    return true;
  }

  Future<void> _accept() async {
    if (!_canAccept) return;
    await _persistAccepted(true);
    widget.onAccepted?.call();
    if (mounted) Navigator.pop(context, true);
  }

  void _decline() {
    widget.onDeclined?.call();
    Navigator.pop(context, false);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Localized agreement text
  // ─────────────────────────────────────────────────────────────

  String _getAgreementText(AppLocalizations l10n) {
    switch (widget.type) {
      case LegalDocType.termsOfService:
        return l10n.legalTOSContent;
      case LegalDocType.privacyPolicy:
        return l10n.legalPrivacyContent;
      case LegalDocType.userAgreement:
        return '${l10n.legalTOSContent}\n\n---\n\n${l10n.legalPrivacyContent}';
    }
  }

  String _getTitle(AppLocalizations l10n) {
    switch (widget.type) {
      case LegalDocType.termsOfService:
        return l10n.legalTermsOfServiceTitle;
      case LegalDocType.privacyPolicy:
        return l10n.legalPrivacyPolicyTitle;
      case LegalDocType.userAgreement:
        return l10n.legalUserAgreementTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(_getTitle(l10n)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          // Reading progress
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Container(
              height: 6,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ],
       ),
      
      body: SafeArea(
        child: Column(
          children: [
            // Optional: small guidance banner
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: _alreadyAccepted 
                ? _InfoBanner(
                    icon: Icons.check_circle_outline,
                    text: _acceptedAt != null 
                        ? '${l10n.labelAccepted} ${_formatDate(_acceptedAt!)}'
                        : l10n.labelAccepted,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  )
                : _InfoBanner(
                    icon: Icons.lock_outline,
                    text: widget.requireScrollToEnd
                        ? l10n.legalReadToBottom
                        : l10n.legalReviewTerms,
                  ),
            ),

            // Scrollable agreement container
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.14),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Markdown(
                    controller: _scrollController,
                    data: _getAgreementText(l10n),
                    selectable: true,
                    shrinkWrap: false,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    onTapLink: (text, href, title) async {
                      if (href != null && href.isNotEmpty) {
                        try {
                          final uri = Uri.parse(href);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Open: $href')),
                            );
                          }
                        } catch (e) {
                          debugPrint('Invalid URL: $href');
                        }
                      }
                    },
                    styleSheet: _markdownStyle(theme),
                  ),
                ),
              ),
            ),

            // Acknowledgment / acceptance bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.18),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.requireCheckbox)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _checked,
                          onChanged: _loadingPrefs
                              ? null
                              : (v) => setState(() => _checked = v ?? false),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              l10n.legalIHaveRead,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.35,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.82),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Icon(
                          _nearEnd ? Icons.verified_user_outlined : Icons.info_outline,
                          size: 20,
                          color: _nearEnd
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.requireScrollToEnd && !_nearEnd
                              ? l10n.legalScrollToEnable
                              : l10n.legalByContinuing,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 24),
                  
                        // Decline (optional but recommended for compliance)
                        TextButton(
                          onPressed: _loadingPrefs ? null : _decline,
                          child: Text(l10n.legalDecline, maxLines: 1),
                        ),
                        const SizedBox(width: 6),
                  
                        FilledButton(
                          onPressed: _canAccept ? _accept : _scrollToBottom,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            child: _loadingPrefs
                                ? const SizedBox(
                                    key: ValueKey('loading'),
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    _alreadyAccepted 
                                        ? l10n.commonClose
                                        : (_canAccept ? l10n.legalAccept : l10n.legalReadMore),
                                    key: ValueKey(_alreadyAccepted ? 'close' : (_canAccept ? 'accept' : 'read')),
                                    maxLines: 1,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle(ThemeData theme) {
    return MarkdownStyleSheet(
      h1: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.25,
        letterSpacing: -0.2,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.35,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      p: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
      strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      listBullet: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.28),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.text,
    this.color,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
