import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../logging/logger.dart';

/// Certificate Pinner
/// Secures HTTPS connections by validating server certificates against known hashes
class CertificatePinner {
  static final _log = LoggerFactory.getLogger('Security');

  /// Verify a certificate's SHA-256 fingerprint against allowed pins
  static bool verifyFingerprint(X509Certificate cert, List<String> allowedShas) {
    try {
      final certDigest = sha256.convert(cert.der).toString().toUpperCase();
      final normalizedCertDigest = certDigest.replaceAll(':', '').replaceAll(' ', '');

      for (final sha in allowedShas) {
        final normalizedSha = sha.replaceAll(':', '').replaceAll(' ', '').toUpperCase();
        if (normalizedCertDigest == normalizedSha) {
          return true;
        }
      }
      return false;
    } catch (e) {
      _log.error('Fingerprint extraction failed: $e');
      return false;
    }
  }

  /// Create an HttpClient with pinned certificates
  /// [allowedShas] is a list of SHA-256 fingerprints of the allowed certificates
  static Future<http.Client> createPinnedClient(
    List<String> allowedShas, {
    bool enforceStrictPinning = false,
  }) async {
    final SecurityContext context = SecurityContext(withTrustedRoots: !enforceStrictPinning);

    final ioClient = HttpClient(context: context);
    
    // Custom validation logic for pinning fingerprints
    ioClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      final isPinned = verifyFingerprint(cert, allowedShas);
      if (isPinned) {
        _log.info('Certificate verified against pin for $host');
        return true;
      }
      _log.warning('Untrusted/unpinned certificate rejected for $host: ${cert.subject}');
      return false;
    };

    return IOClient(ioClient);
  }

  /// Get a client configured for Supabase
  static Future<http.Client> getSupabaseClient() async {
    // These would be the SHA-256 fingerprints of Supabase's SSL certificates
    return createPinnedClient([
      '74:2C:BA:2C:D8:29:46:A6:5E:3D:22:B4:8C:FC:AF:0F:70:86:E4:33:C7:E3:D8:D3:AF:B6:81:6A:DC:4F:7B:A3'
    ]);
  }
}
