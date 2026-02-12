/// Service to detect duplicate contacts in the family system
class DuplicateDetectionService {
  /// Simple fuzzy matching for names
  double calculateNameSimilarity(String name1, String name2) {
    if (name1 == name2) return 1.0;
    
    final s1 = name1.toLowerCase().trim();
    final s2 = name2.toLowerCase().trim();
    
    if (s1 == s2) return 1.0;
    
    // Levenshtein distance or simple Jaro-Winkler could go here
    // For now, simple containment or word matching
    final words1 = s1.split(RegExp(r'\s+'));
    final words2 = s2.split(RegExp(r'\s+'));
    
    int matches = 0;
    for (final w1 in words1) {
      if (words2.contains(w1)) matches++;
    }
    
    return (2.0 * matches) / (words1.length + words2.length);
  }

  /// Detects potential duplicates based on name, email, and phone
  bool isPotentialDuplicate({
    required String name,
    String? email,
    String? phone,
    required String otherName,
    String? otherEmail,
    String? otherPhone,
  }) {
    // Exact email or phone match is a strong duplicate signal
    if (email != null && otherEmail != null && email == otherEmail) return true;
    if (phone != null && otherPhone != null && _normalizePhone(phone) == _normalizePhone(otherPhone)) return true;
    
    // Fuzzy name match
    final similarity = calculateNameSimilarity(name, otherName);
    return similarity > 0.8;
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }
}
