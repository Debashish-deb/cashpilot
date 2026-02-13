/// PII Sanitizer
/// Utility to mask sensitive information in logs and error reports
library;

class PIISanitizer {
  // Regex patterns for common PII
  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );
  
  static final RegExp _phoneRegex = RegExp(
    r'''(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}''',
  );

  // Credit card simple detection (not exhaustive, just for logs)
  static final RegExp _cardRegex = RegExp(r'\b\d{4}[-.\s]?\d{4}[-.\s]?\d{4}[-.\s]?\d{4}\b');

  /// Sanitize a string by masking known PII patterns
  static String sanitize(String input) {
    if (input.isEmpty) return input;
    
    var result = input;
    
    // Mask emails: user@example.com -> u***@example.com
    result = result.replaceAllMapped(_emailRegex, (match) {
      final email = match.group(0)!;
      final parts = email.split('@');
      if (parts.length != 2) return '[EMAIL]';
      final username = parts[0];
      final domain = parts[1];
      if (username.length <= 1) return '*@$domain';
      return '${username[0]}***@$domain';
    });
    
    // Mask phone numbers: +1 (555) 123-4567 -> +1 (***) ***-4567
    result = result.replaceAllMapped(_phoneRegex, (match) {
      final phone = match.group(0)!;
      if (phone.length <= 4) return '[PHONE]';
      return '***-***-${phone.substring(phone.length - 4)}';
    });
    
    // Mask credit cards
    result = result.replaceAllMapped(_cardRegex, (match) {
      final card = match.group(0)!;
      return '****-****-****-${card.substring(card.length - 4)}';
    });

    // Scrape Auth tokens / secrets
    result = result.replaceAll(RegExp(r'bearer\s+[a-zA-Z0-9._-]+', caseSensitive: false), 'Bearer [REDACTED]');
    result = result.replaceAll(RegExp(r'sbp_[a-zA-Z0-9]+'), 'sbp_[REDACTED]'); // Supabase keys
    
    return result;
  }

  /// Sanitize a map (recurring for depth)
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> map) {
    final sanitized = <String, dynamic>{};
    
    map.forEach((key, value) {
      // Sensitive keys to completely mask
      final sensitiveKeys = {'password', 'secret', 'token', 'key', 'cvv', 'card_number'};
      
      if (sensitiveKeys.any((sk) => key.toLowerCase().contains(sk))) {
        sanitized[key] = '[REDACTED]';
      } else if (value is String) {
        sanitized[key] = sanitize(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = sanitizeMap(value);
      } else if (value is List) {
        sanitized[key] = value.map((e) {
          if (e is String) return sanitize(e);
          if (e is Map<String, dynamic>) return sanitizeMap(e);
          return e;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }
}
