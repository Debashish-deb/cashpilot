import '../../../domain/family/models/relationship_model.dart';

/// Service to infer relationships based on contact data and heuristics
class RelationshipInferenceService {
  /// Infers relationship type from contact names/tags
  RelationshipType? inferTypeFromName(String contactName) {
    final name = contactName.toLowerCase();
    
    if (name.contains('mom') || name.contains('mother') || name.contains('maa')) {
      return RelationshipType.parent;
    }
    
    if (name.contains('dad') || name.contains('father') || name.contains('papa') || name.contains('baba')) {
      return RelationshipType.parent;
    }
    
    if (name.contains('wife') || name.contains('wifey')) {
      return RelationshipType.spouse;
    }
    
    if (name.contains('husband') || name.contains('hubby')) {
      return RelationshipType.spouse;
    }

    if (name.contains('bhai') || name.contains('brother') || name.contains('bro')) {
      return RelationshipType.sibling;
    }

    if (name.contains('bon') || name.contains('sister') || name.contains('sis')) {
      return RelationshipType.sibling;
    }

    if (name.contains('son') || name.contains('daughter')) {
      return RelationshipType.child;
    }

    return null;
  }

  /// Calculates confidence score for an inferred relationship
  double calculateConfidence(RelationshipType type, {bool hasSameLastName = false}) {
    double confidence = 0.5;
    
    if (hasSameLastName) {
      if (type == RelationshipType.parent || type == RelationshipType.sibling) {
        confidence += 0.3;
      }
    }
    
    return confidence.clamp(0.0, 1.0);
  }
}
