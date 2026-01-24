
library;

class Validators {
  /// Email validation using RFC 5322 simplified regex
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    // Use a double-quoted raw string here because the pattern contains a single quote
    // which would prematurely close a single-quoted raw string.
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );
    
    return emailRegex.hasMatch(email) && email.length <= 254;
  }

  /// Password strength validation
  /// Requirements: 8+ chars, uppercase, number
  static bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  /// Get password strength message
  static String getPasswordStrengthMessage(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    return '';
  }

  /// Financial amount validation
  /// Checks for NaN, Infinity, negative, overflow
  static bool isValidAmount(double amount) {
    if (amount.isNaN || amount.isInfinite) return false;
    if (amount < 0) return false;
    if (amount > 999999999.99) return false; // Max reasonable amount
    return true;
  }

  /// Validate amount and return error message
  static String? validateAmount(double? amount) {
    if (amount == null) return 'Amount is required';
    if (amount.isNaN) return 'Invalid amount';
    if (amount.isInfinite) return 'Amount is too large';
    if (amount < 0) return 'Amount cannot be negative';
    if (amount > 999999999.99) return 'Amount exceeds maximum (999,999,999.99)';
    return null;
  }

  /// Validate amount in cents (for storage)
  static bool isValidAmountInCents(int amountInCents) {
    if (amountInCents < 0) return false;
    if (amountInCents > 99999999999) return false; // 999,999,999.99 in cents
    return true;
  }

  /// MIME type validation for receipts
  static bool isValidReceiptMimeType(String mimeType) {
    const allowedTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/webp',
      'image/heic',
      'image/heif',
      'application/pdf',
    ];
    return allowedTypes.contains(mimeType.toLowerCase());
  }

  /// Get allowed receipt file extensions
  static List<String> getAllowedReceiptExtensions() {
    return ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif', '.pdf'];
  }

  /// Validate file extension for receipts
  static bool isValidReceiptExtension(String filename) {
    final lowercaseFilename = filename.toLowerCase();
    return getAllowedReceiptExtensions().any((ext) => lowercaseFilename.endsWith(ext));
  }

  /// Currency code validation (ISO 4217)
  static bool isValidCurrencyCode(String code) {
    if (code.length != 3) return false;
    
    // Basic check: all uppercase letters
    final currencyRegex = RegExp(r'^[A-Z]{3}$');
    if (!currencyRegex.hasMatch(code)) return false;
    
    // Common currencies
    const commonCurrencies = {
      'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'INR', 'CAD', 'AUD',
      'CHF', 'SEK', 'NOK', 'DKK', 'NZD', 'SGD', 'HKD', 'KRW',
      'MXN', 'BRL', 'ZAR', 'RUB', 'TRY', 'PLN', 'THB', 'IDR',
      'MYR', 'PHP', 'NPR', 'BDT', 'PKR', 'LKR', 'VND', 'AED',
    };
    
    return commonCurrencies.contains(code);
  }

  /// Budget name validation
  static String? validateBudgetName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Budget name is required';
    }
    if (name.trim().length < 2) {
      return 'Budget name must be at least 2 characters';
    }
    if (name.length > 100) {
      return 'Budget name is too long (max 100 characters)';
    }
    return null;
  }

  /// Category name validation
  static String? validateCategoryName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Category name is required';
    }
    if (name.trim().length < 2) {
      return 'Category name must be at least 2 characters';
    }
    if (name.length > 50) {
      return 'Category name is too long (max 50 characters)';
    }
    return null;
  }

  /// Expense description validation
  static String? validateExpenseDescription(String? description) {
    if (description != null && description.length > 500) {
      return 'Description is too long (max 500 characters)';
    }
    return null;
  }
}
  