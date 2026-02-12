
/// Defines the authority level of different data sources.
/// Higher values indicate higher trustworthiness.
enum SourceAuthority {
  bank(100),
  receipt(80),
  manual(50);

  final int level;
  const SourceAuthority(this.level);

  static SourceAuthority fromString(String? source) {
    switch (source?.toLowerCase()) {
      case 'bank':
      case 'api':
      case 'bank_sync':
        return SourceAuthority.bank;
      case 'ocr':
      case 'receipt':
        return SourceAuthority.receipt;
      case 'manual':
      default:
        return SourceAuthority.manual;
    }
  }
}

/// Rule engine for resolving conflicts between financial data points.
class TruthHierarchy {
  /// Compares two sources and determines which one is the "Truth".
  /// Returns true if [incomingSource] should override [existingSource].
  static bool shouldOverride({
    required String? incomingSource,
    required String? existingSource,
  }) {
    final incoming = SourceAuthority.fromString(incomingSource);
    final existing = SourceAuthority.fromString(existingSource);

    return incoming.level >= existing.level;
  }

  /// Resolves which source to use as the anchor for a transaction.
  static String resolvePrimarySource(List<String> sources) {
    if (sources.isEmpty) return 'manual';
    
    return sources
        .map((s) => SourceAuthority.fromString(s))
        .reduce((current, next) => next.level > current.level ? next : current)
        .name;
  }
}
