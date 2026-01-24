/// Barcode Validator & GS1 Inference (Enterprise-Grade)
/// - Strict validation for EAN-13 / EAN-8 / UPC-A / UPC-E
/// - GS1 prefix → country/region inference (best-effort)
/// - Structured result with reasons + confidence hints
library;

import 'dart:math';

import '../models/barcode_scan_result.dart' show BarcodeFormat;

class BarcodeValidationResult {
  final bool isValid;
  final String normalized;
  final List<String> messages;

  /// Optional machine-readable reason for invalidation (stable key).
  final String? failureReason;

  /// Validation evidence for debugging / analytics (safe to persist).
  /// Keep values JSON-serializable.
  final Map<String, dynamic> evidence;

  /// Best-effort inference from GS1 prefix (EAN-13 primarily).
  /// Note: GS1 prefix indicates the organization that assigned the number,
  /// not always the manufacturing country.
  final String? gs1CountryOrRegion;

  /// 0..1 confidence that GS1 inference is meaningful for this code.
  final double gs1Confidence;

  /// Check digit pass (only applicable to numeric product codes)
  final bool? checksumPassed;

  const BarcodeValidationResult({
    required this.isValid,
    required this.normalized,
    required this.messages,
    this.gs1CountryOrRegion,
    this.gs1Confidence = 0.0,
    this.checksumPassed,
    this.failureReason,
    this.evidence = const {},
  });

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'normalized': normalized,
        'messages': messages,
        'gs1CountryOrRegion': gs1CountryOrRegion,
        'gs1Confidence': gs1Confidence,
        'checksumPassed': checksumPassed,
        'failureReason': failureReason,
        'evidence': evidence,
      };
}

class BarcodeValidator {
  /// Public entrypoint
  static BarcodeValidationResult validate(
    String raw, {
    BarcodeFormat format = BarcodeFormat.unknown,
  }) {
    final normalized = _normalize(raw);
    final messages = <String>[];
    final evidence = <String, dynamic>{
      'raw_length': raw.length,
      'normalized_length': normalized.length,
      'format': format.name,
    };

    if (normalized.isEmpty) {
      return BarcodeValidationResult(
        isValid: false,
        normalized: normalized,
        messages: const ['Empty barcode value'],
        failureReason: 'empty',
        evidence: evidence,
      );
    }

    // Non-numeric formats: we mostly just sanity-check length.
    if (!_isNumericFormat(format)) {
      final ok = _basicSanity(normalized, messages, format);
      evidence['sanity_ok'] = ok;
      return BarcodeValidationResult(
        isValid: ok,
        normalized: normalized,
        messages: messages,
        gs1CountryOrRegion: null,
        gs1Confidence: 0.0,
        checksumPassed: null,
        failureReason: ok ? null : 'sanity_failed',
        evidence: evidence,
      );
    }

    // Numeric formats
    if (!_isAllDigits(normalized)) {
      messages.add('Expected numeric code, found non-digit characters');
      evidence['non_digit'] = true;
      return BarcodeValidationResult(
        isValid: false,
        normalized: normalized,
        messages: messages,
        checksumPassed: false,
        failureReason: 'non_numeric',
        evidence: evidence,
      );
    }

    switch (format) {
      case BarcodeFormat.ean13:
        return _validateEan13(normalized, messages);
      case BarcodeFormat.ean8:
        return _validateEan8(normalized, messages);
      case BarcodeFormat.upc:
      case BarcodeFormat.upcA:
        return _validateUpcA(normalized, messages);
      case BarcodeFormat.upcE:
        return _validateUpcE(normalized, messages);
      default:
        // If format unknown but numeric, do best-effort by length:
        return _validateByLengthBestEffort(normalized, messages);
    }
  }

  // ---------------------------------------------------------------------------
  // FORMAT VALIDATORS
  // ---------------------------------------------------------------------------

  static BarcodeValidationResult _validateEan13(
    String code,
    List<String> messages,
  ) {
    if (code.length != 13) {
      messages.add('EAN-13 must be 13 digits');
      return BarcodeValidationResult(
        isValid: false,
        normalized: code,
        messages: messages,
        checksumPassed: false,
      );
    }

    final checksumOk = _validateGtinChecksum(code);
    if (!checksumOk) messages.add('EAN-13 check digit failed');

    final gs1 = _inferGs1CountryOrRegion(code);
    final gs1Conf = gs1 == null ? 0.0 : 0.85;

    return BarcodeValidationResult(
      isValid: checksumOk,
      normalized: code,
      messages: messages,
      gs1CountryOrRegion: gs1,
      gs1Confidence: gs1Conf,
      checksumPassed: checksumOk,
    );
  }

  static BarcodeValidationResult _validateEan8(
    String code,
    List<String> messages,
  ) {
    if (code.length != 8) {
      messages.add('EAN-8 must be 8 digits');
      return BarcodeValidationResult(
        isValid: false,
        normalized: code,
        messages: messages,
        checksumPassed: false,
      );
    }

    final checksumOk = _validateGtinChecksum(code);
    if (!checksumOk) messages.add('EAN-8 check digit failed');

    // EAN-8 has limited GS1 inference utility; treat as low confidence.
    final gs1 = _inferGs1CountryOrRegion(code.padRight(13, '0'));
    final gs1Conf = gs1 == null ? 0.0 : 0.35;

    return BarcodeValidationResult(
      isValid: checksumOk,
      normalized: code,
      messages: messages,
      gs1CountryOrRegion: gs1,
      gs1Confidence: gs1Conf,
      checksumPassed: checksumOk,
    );
  }

  static BarcodeValidationResult _validateUpcA(
    String code,
    List<String> messages,
  ) {
    // UPC-A is 12 digits (GTIN-12)
    if (code.length != 12) {
      messages.add('UPC-A must be 12 digits');
      return BarcodeValidationResult(
        isValid: false,
        normalized: code,
        messages: messages,
        checksumPassed: false,
      );
    }

    final checksumOk = _validateGtinChecksum(code);
    if (!checksumOk) messages.add('UPC-A check digit failed');

    // UPC is largely US/CA retail domain; GS1 prefix mapping not the same as EAN.
    final gs1 = _inferUpcRegion(code);
    final gs1Conf = gs1 == null ? 0.0 : 0.65;

    return BarcodeValidationResult(
      isValid: checksumOk,
      normalized: code,
      messages: messages,
      gs1CountryOrRegion: gs1,
      gs1Confidence: gs1Conf,
      checksumPassed: checksumOk,
    );
  }

  static BarcodeValidationResult _validateUpcE(
    String code,
    List<String> messages,
  ) {
    // UPC-E is typically 8 digits (including number system + check digit).
    // Some scanners provide 6 digits (compressed core). We support both.
    if (code.length != 8 && code.length != 6) {
      messages.add('UPC-E must be 6 or 8 digits');
      return BarcodeValidationResult(
        isValid: false,
        normalized: code,
        messages: messages,
        checksumPassed: false,
      );
    }

    if (code.length == 6) {
      // Can’t check GTIN checksum without expansion reliably (requires number system).
      messages.add('UPC-E provided in 6-digit compressed form; checksum not verified');
      return BarcodeValidationResult(
        isValid: true,
        normalized: code,
        messages: messages,
        gs1CountryOrRegion: 'US/CA (UPC domain)',
        gs1Confidence: 0.45,
        checksumPassed: null,
      );
    }

    // 8-digit UPC-E: we still can’t always reliably validate without expansion rules
    // (depends on number system + manufacturer code rules). We do a conservative approach:
    messages.add('UPC-E 8-digit: checksum validation requires UPC-E→UPC-A expansion (optional)');
    return BarcodeValidationResult(
      isValid: true,
      normalized: code,
      messages: messages,
      gs1CountryOrRegion: 'US/CA (UPC domain)',
      gs1Confidence: 0.55,
      checksumPassed: null,
    );
  }

  static BarcodeValidationResult _validateByLengthBestEffort(
    String code,
    List<String> messages,
  ) {
    // If scanner didn’t tell format, infer by digit count.
    if (code.length == 13) return _validateEan13(code, messages);
    if (code.length == 12) return _validateUpcA(code, messages);
    if (code.length == 8) return _validateEan8(code, messages);

    messages.add('Unknown numeric format length: ${code.length}');
    return BarcodeValidationResult(
      isValid: false,
      normalized: code,
      messages: messages,
      checksumPassed: false,
    );
  }

  // ---------------------------------------------------------------------------
  // CHECKSUM (GTIN / EAN / UPC-A)
  // ---------------------------------------------------------------------------

  /// Validates GTIN checksum for lengths 8, 12, 13, 14 (EAN-8, UPC-A, EAN-13, ITF-14)
  static bool _validateGtinChecksum(String code) {
    if (code.length < 8) return false;
    final digits = code.split('').map((c) => int.parse(c)).toList();

    int sum = 0;
    // Weighting: from rightmost (excluding check digit), alternate 3/1.
    // Works for GTIN-8/12/13/14.
    // Example: EAN-13 uses weights 1,3,1,3... from right.
    for (int i = digits.length - 2, pos = 1; i >= 0; i--, pos++) {
      final weight = (pos % 2 == 1) ? 3 : 1;
      sum += digits[i] * weight;
    }

    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == digits.last;
  }

  // ---------------------------------------------------------------------------
  // GS1 INFERENCE (EAN-13 prefix mapping)
  // ---------------------------------------------------------------------------

  static String? _inferGs1CountryOrRegion(String ean13ish) {
    // Need at least 3 digits to infer prefix.
    if (ean13ish.length < 3) return null;

    final prefix3 = int.tryParse(ean13ish.substring(0, 3));
    if (prefix3 == null) return null;

    // GS1 prefix ranges (best-effort, not exhaustive)
    // Keep it conservative and useful for UX (“assigned by GS1 member org”).
    if (_inRange(prefix3, 0, 19)) return 'US/CA (UPC / reserved)';
    if (_inRange(prefix3, 30, 39)) return 'US (drugs / national)';
    if (_inRange(prefix3, 40, 49)) return 'Reserved / internal use';
    if (_inRange(prefix3, 50, 59)) return 'Coupons / reserved';
    if (_inRange(prefix3, 60, 139)) return 'US/CA';
    if (_inRange(prefix3, 200, 299)) return 'Restricted distribution';
    if (_inRange(prefix3, 300, 379)) return 'France / Monaco';
    if (_inRange(prefix3, 380, 380)) return 'Bulgaria';
    if (_inRange(prefix3, 383, 383)) return 'Slovenia';
    if (_inRange(prefix3, 385, 385)) return 'Croatia';
    if (_inRange(prefix3, 387, 387)) return 'Bosnia & Herzegovina';
    if (_inRange(prefix3, 400, 440)) return 'Germany';
    if (_inRange(prefix3, 450, 459)) return 'Japan';
    if (_inRange(prefix3, 460, 469)) return 'Russia';
    if (_inRange(prefix3, 470, 470)) return 'Kyrgyzstan';
    if (_inRange(prefix3, 471, 471)) return 'Taiwan';
    if (_inRange(prefix3, 474, 474)) return 'Estonia';
    if (_inRange(prefix3, 475, 475)) return 'Latvia';
    if (_inRange(prefix3, 476, 476)) return 'Azerbaijan';
    if (_inRange(prefix3, 477, 477)) return 'Lithuania';
    if (_inRange(prefix3, 478, 478)) return 'Uzbekistan';
    if (_inRange(prefix3, 479, 479)) return 'Sri Lanka';
    if (_inRange(prefix3, 480, 480)) return 'Philippines';
    if (_inRange(prefix3, 481, 481)) return 'Belarus';
    if (_inRange(prefix3, 482, 482)) return 'Ukraine';
    if (_inRange(prefix3, 484, 484)) return 'Moldova';
    if (_inRange(prefix3, 485, 485)) return 'Armenia';
    if (_inRange(prefix3, 486, 486)) return 'Georgia';
    if (_inRange(prefix3, 487, 487)) return 'Kazakhstan';
    if (_inRange(prefix3, 489, 489)) return 'Hong Kong';
    if (_inRange(prefix3, 490, 499)) return 'Japan';
    if (_inRange(prefix3, 500, 509)) return 'UK';
    if (_inRange(prefix3, 520, 521)) return 'Greece';
    if (_inRange(prefix3, 528, 528)) return 'Lebanon';
    if (_inRange(prefix3, 529, 529)) return 'Cyprus';
    if (_inRange(prefix3, 530, 530)) return 'Albania';
    if (_inRange(prefix3, 531, 531)) return 'North Macedonia';
    if (_inRange(prefix3, 535, 535)) return 'Malta';
    if (_inRange(prefix3, 539, 539)) return 'Ireland';
    if (_inRange(prefix3, 540, 549)) return 'Belgium / Luxembourg';
    if (_inRange(prefix3, 560, 560)) return 'Portugal';
    if (_inRange(prefix3, 569, 569)) return 'Iceland';
    if (_inRange(prefix3, 570, 579)) return 'Denmark / Faroe / Greenland';
    if (_inRange(prefix3, 590, 590)) return 'Poland';
    if (_inRange(prefix3, 594, 594)) return 'Romania';
    if (_inRange(prefix3, 599, 599)) return 'Hungary';
    if (_inRange(prefix3, 600, 601)) return 'South Africa';
    if (_inRange(prefix3, 603, 603)) return 'Ghana';
    if (_inRange(prefix3, 608, 608)) return 'Bahrain';
    if (_inRange(prefix3, 609, 609)) return 'Mauritius';
    if (_inRange(prefix3, 611, 611)) return 'Morocco';
    if (_inRange(prefix3, 613, 613)) return 'Algeria';
    if (_inRange(prefix3, 616, 616)) return 'Kenya';
    if (_inRange(prefix3, 618, 618)) return 'Ivory Coast';
    if (_inRange(prefix3, 619, 619)) return 'Tunisia';
    if (_inRange(prefix3, 621, 621)) return 'Syria';
    if (_inRange(prefix3, 622, 622)) return 'Egypt';
    if (_inRange(prefix3, 624, 624)) return 'Libya';
    if (_inRange(prefix3, 625, 625)) return 'Jordan';
    if (_inRange(prefix3, 626, 626)) return 'Iran';
    if (_inRange(prefix3, 627, 627)) return 'Kuwait';
    if (_inRange(prefix3, 628, 628)) return 'Saudi Arabia';
    if (_inRange(prefix3, 629, 629)) return 'UAE';
    if (_inRange(prefix3, 630, 630)) return 'Qatar';
    if (_inRange(prefix3, 640, 649)) return 'Finland';
    if (_inRange(prefix3, 690, 699)) return 'China';
    if (_inRange(prefix3, 700, 709)) return 'Norway';
    if (_inRange(prefix3, 729, 729)) return 'Israel';
    if (_inRange(prefix3, 730, 739)) return 'Sweden';
    if (_inRange(prefix3, 740, 740)) return 'Guatemala';
    if (_inRange(prefix3, 741, 741)) return 'El Salvador';
    if (_inRange(prefix3, 742, 742)) return 'Honduras';
    if (_inRange(prefix3, 743, 743)) return 'Nicaragua';
    if (_inRange(prefix3, 744, 744)) return 'Costa Rica';
    if (_inRange(prefix3, 745, 745)) return 'Panama';
    if (_inRange(prefix3, 746, 746)) return 'Dominican Republic';
    if (_inRange(prefix3, 750, 750)) return 'Mexico';
    if (_inRange(prefix3, 754, 755)) return 'Canada';
    if (_inRange(prefix3, 760, 769)) return 'Switzerland / Liechtenstein';
    if (_inRange(prefix3, 770, 771)) return 'Colombia';
    if (_inRange(prefix3, 773, 773)) return 'Uruguay';
    if (_inRange(prefix3, 775, 775)) return 'Peru';
    if (_inRange(prefix3, 777, 777)) return 'Bolivia';
    if (_inRange(prefix3, 779, 779)) return 'Argentina';
    if (_inRange(prefix3, 780, 780)) return 'Chile';
    if (_inRange(prefix3, 784, 784)) return 'Paraguay';
    if (_inRange(prefix3, 786, 786)) return 'Ecuador';
    if (_inRange(prefix3, 789, 790)) return 'Brazil';
    if (_inRange(prefix3, 800, 839)) return 'Italy / San Marino / Vatican';
    if (_inRange(prefix3, 840, 849)) return 'Spain / Andorra';
    if (_inRange(prefix3, 850, 850)) return 'Cuba';
    if (_inRange(prefix3, 858, 858)) return 'Slovakia';
    if (_inRange(prefix3, 859, 859)) return 'Czech Republic';
    if (_inRange(prefix3, 860, 860)) return 'Serbia';
    if (_inRange(prefix3, 865, 865)) return 'Mongolia';
    if (_inRange(prefix3, 867, 867)) return 'North Korea';
    if (_inRange(prefix3, 868, 869)) return 'Turkey';
    if (_inRange(prefix3, 870, 879)) return 'Netherlands';
    if (_inRange(prefix3, 880, 880)) return 'South Korea';
    if (_inRange(prefix3, 884, 884)) return 'Cambodia';
    if (_inRange(prefix3, 885, 885)) return 'Thailand';
    if (_inRange(prefix3, 888, 888)) return 'Singapore';
    if (_inRange(prefix3, 890, 890)) return 'India';
    if (_inRange(prefix3, 893, 893)) return 'Vietnam';
    if (_inRange(prefix3, 896, 896)) return 'Pakistan';
    if (_inRange(prefix3, 899, 899)) return 'Indonesia';
    if (_inRange(prefix3, 900, 919)) return 'Austria';
    if (_inRange(prefix3, 930, 939)) return 'Australia';
    if (_inRange(prefix3, 940, 949)) return 'New Zealand';
    if (_inRange(prefix3, 950, 950)) return 'GS1 Global Office';
    if (_inRange(prefix3, 955, 955)) return 'Malaysia';
    if (_inRange(prefix3, 958, 958)) return 'Macau';

    return null;
  }

  static String? _inferUpcRegion(String upcA) {
    // UPC-A is mostly used in North America.
    if (upcA.length == 12) return 'US/CA (UPC domain)';
    return null;
  }

  // ---------------------------------------------------------------------------
  // BASIC SANITY for non-numeric formats
  // ---------------------------------------------------------------------------

  static bool _basicSanity(String normalized, List<String> messages, BarcodeFormat format) {
    if (normalized.length < 3) {
      messages.add('Value too short for format ${format.name}');
      return false;
    }
    if (normalized.length > 4096) {
      messages.add('Value too long (possible corruption)');
      return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // UTIL
  // ---------------------------------------------------------------------------

  static String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '');

  static bool _isAllDigits(String value) =>
      value.isNotEmpty && value.codeUnits.every((c) => c >= 48 && c <= 57);

  static bool _isNumericFormat(BarcodeFormat format) {
    return format == BarcodeFormat.ean13 ||
        format == BarcodeFormat.ean8 ||
        format == BarcodeFormat.upc ||
        format == BarcodeFormat.upcA ||
        format == BarcodeFormat.upcE;
  }

  static bool _inRange(int x, int a, int b) => x >= min(a, b) && x <= max(a, b);
}
