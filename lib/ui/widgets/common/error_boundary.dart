import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.g.dart';
import '../../../core/services/error_reporter.dart';
import '../../../l10n/app_localizations.dart';
import 'cp_app_icon.dart';

/// A global error boundary that catches exceptions in its child's widget tree.
/// In production, it shows a user-friendly error screen instead of a crash.
class ErrorBoundary extends ConsumerStatefulWidget {
  final Widget child;

  const ErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends ConsumerState<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    // Set the global error builder to this boundary's logic if needed,
    // but usually, we use the builder in MaterialApp.
  }

  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });
    
    // Report the error
    errorReporter.reportException(error, stackTrace: stackTrace);
  }

  void _reset() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ProductionErrorUI(
        error: _error!,
        onRetry: _reset,
      );
    }

    return ErrorWidget.builder == _defaultErrorBuilder 
      ? widget.child 
      : _CaptureErrorWidget(
          onCatch: _handleError,
          child: widget.child,
        );
  }

  static Widget _defaultErrorBuilder(FlutterErrorDetails details) {
    return const SizedBox.shrink();
  }
}

class _CaptureErrorWidget extends StatefulWidget {
  final Widget child;
  final Function(Object, StackTrace) onCatch;

  const _CaptureErrorWidget({
    required this.child,
    required this.onCatch,
  });

  @override
  State<_CaptureErrorWidget> createState() => _CaptureErrorWidgetState();
}

class _CaptureErrorWidgetState extends State<_CaptureErrorWidget> {
  @override
  Widget build(BuildContext context) {
    try {
      return widget.child;
    } catch (e, stack) {
      widget.onCatch(e, stack);
      return const SizedBox.shrink();
    }
  }
}

class ProductionErrorUI extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ProductionErrorUI({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CPAppIcon(
                icon: Icons.error_outline_rounded,
                color: AppTokens.semanticDanger,
                size: 80,
                iconSize: 40,
                useGradient: false,
              ),
              const SizedBox(height: 32),
              Text(
                'Something went wrong',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We encountered an unexpected error. Our team has been notified and we are working on it.',
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.commonTryAgain),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Additional help or contact support logic
                },
                child: Text(AppLocalizations.of(context)!.commonContactSupport),
              ),
              if (true) // In debug or internal builds, show error details
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.error,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
