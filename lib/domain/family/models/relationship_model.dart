/// Types of family and social relationships supported by CashPilot
enum RelationshipType {
  // Direct Family
  spouse('spouse'),
  partner('partner'),
  parent('parent'),
  child('child'),
  sibling('sibling'),
  
  // Extended Family
  grandparent('grandparent'),
  grandchild('grandchild'),
  aunt('aunt'),
  uncle('uncle'),
  cousin('cousin'),
  nephew('nephew'),
  niece('niece'),
  
  // In-laws
  motherInLaw('mother_in_law'),
  fatherInLaw('father_in_law'),
  brotherInLaw('brother_in_law'),
  sisterInLaw('sister_in_law'),
  
  // Other
  friend('friend'),
  colleague('colleague'),
  other('other');

  final String value;
  const RelationshipType(this.value);

  static RelationshipType fromString(String value) {
    return RelationshipType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => RelationshipType.other,
    );
  }
}

/// Model representing a relationship between two contacts
class RelationshipModel {
  final String id;
  final String fromContactId;
  final String toContactId;
  final RelationshipType type;
  final double confidence;
  final String inferredBy; // 'manual' or 'ai_logic'
  final Map<String, dynamic>? metadata;

  const RelationshipModel({
    required this.id,
    required this.fromContactId,
    required this.toContactId,
    required this.type,
    this.confidence = 1.0,
    this.inferredBy = 'manual',
    this.metadata,
  });

  bool get isAIInferred => inferredBy == 'ai_logic';

  RelationshipModel copyWith({
    String? id,
    String? fromContactId,
    String? toContactId,
    RelationshipType? type,
    double? confidence,
    String? inferredBy,
    Map<String, dynamic>? metadata,
  }) {
    return RelationshipModel(
      id: id ?? this.id,
      fromContactId: fromContactId ?? this.fromContactId,
      toContactId: toContactId ?? this.toContactId,
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      inferredBy: inferredBy ?? this.inferredBy,
      metadata: metadata ?? this.metadata,
    );
  }
}
