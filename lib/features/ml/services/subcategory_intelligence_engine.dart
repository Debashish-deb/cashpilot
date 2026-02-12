import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/drift/app_database.dart';
import '../../../../core/providers/app_providers.dart'; // Import app_providers.dart for databaseProvider
import 'semantic_normalization_service.dart';

part 'subcategory_intelligence_engine.g.dart';

@Riverpod(keepAlive: true)
SubcategoryIntelligenceEngine subcategoryIntelligenceEngine(SubcategoryIntelligenceEngineRef ref) {
  return SubcategoryIntelligenceEngine(
    ref.read(databaseProvider), // Used correct provider from app_providers.dart
    ref.read(semanticNormalizationServiceProvider),
  );
}

/// Source type for weighted inference
enum InferenceSource {
  manual,  // Weight 1.0
  ocr,     // Weight 1.8
  barcode, // Weight 3.0
}

/// Result of an intelligence query
class IntelligencePrediction {
  final SubCategory? subCategory;
  final double confidence;
  final List<String> explanation; // "Matched 'spinach' (OCR) with 98% confidence"

  IntelligencePrediction({
    this.subCategory,
    required this.confidence,
    this.explanation = const [],
  });
  
  bool get shouldAutoFill => confidence >= 0.90;
  bool get shouldSuggest => confidence >= 0.70 && confidence < 0.90;
}

class SubcategoryIntelligenceEngine {
  final AppDatabase _db;
  final SemanticNormalizationService _normalizer;

  SubcategoryIntelligenceEngine(this._db, this._normalizer);

  /// Main Prediction Pipeline
  Future<IntelligencePrediction> predict({
    required String rawInput,
    required InferenceSource source,
  }) async {
    final tokens = _normalizer.normalize(rawInput);
    if (tokens.isEmpty) {
      return IntelligencePrediction(confidence: 0.0, explanation: ["No valid tokens found"]);
    }

    // 1. Fetch Learning Patterns
    // specialized query to find patterns matching ANY of the tokens
    // Since tokens are stored as JSON strings in DB, we might need a broader fetch or 
    // rely on the old 'merchantPattern' if 'semanticTokens' is null during migration.
    
    // For MVP/Phase 1: We will fetch all learning entries and filter in memory 
    // (Optimization: In future, use FTS or indexed token table)
    
    final allPatterns = await _db.select(_db.categoryLearning).get();
    
    // 2. Score Candidates
    final scores = <String, double>{}; // SubCategoryId -> Score
    final matchCounts = <String, int>{}; // SubCategoryId -> Token Hit Count

    final sourceWeight = _getSourceWeight(source);
    
    // Only search recent high-confidence patterns
    for (final pattern in allPatterns) {
      if (pattern.subCategoryId == null) continue;
      
      // Parse pattern tokens
      List<String> patternTokens = [];
      if (pattern.semanticTokens != null) {
        try {
          patternTokens = List<String>.from(jsonDecode(pattern.semanticTokens!));
        } catch (_) {}
      } else {
        // Fallback to legacy merchant pattern normalization
        patternTokens = _normalizer.normalize(pattern.merchantPattern);
      }
      
      if (patternTokens.isEmpty) continue;

      // Calculate Jaccard Similarity or Overlap
      final intersection = tokens.toSet().intersection(patternTokens.toSet());
      
      if (intersection.isNotEmpty) {
        final overlapScore = intersection.length / tokens.length; // How much of input is covered?
        
        // Base Score = (ConfidenceBoost * UsageCount * SourceWeight * Overlap)
        // Normalized roughly to 0-1 range logic later
        double entryScore = (pattern.confidenceBoost * 0.1) * 
                            (1 + (pattern.usageCount * 0.05)) * 
                            pattern.sourceWeight * 
                            overlapScore;

        scores[pattern.subCategoryId!] = (scores[pattern.subCategoryId!] ?? 0.0) + entryScore;
        matchCounts[pattern.subCategoryId!] = (matchCounts[pattern.subCategoryId!] ?? 0) + intersection.length;
      }
    }

    if (scores.isEmpty) {
      return IntelligencePrediction(confidence: 0.0);
    }

    // 3. Find Winner
    final sortedCandidates = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    final bestCandidateId = sortedCandidates.first.key;
    final bestScore = sortedCandidates.first.value;

    // Normalize final confidence (Sigmoid or capped linear)
    // Rough heuristic: Score > 5.0 is incredibly high. Score 1.0 is decent.
    double finalConfidence = (bestScore / 5.0).clamp(0.0, 1.0);
    
    // Fetch actual entity
    final subCategory = await (_db.select(_db.subCategories)..where((tbl) => tbl.id.equals(bestCandidateId))).getSingleOrNull();

    if (subCategory == null) {
       return IntelligencePrediction(confidence: 0.0, explanation: ["Best match subcategory deletion detected"]);
    }

    return IntelligencePrediction(
      subCategory: subCategory,
      confidence: finalConfidence,
      explanation: ["Matched tokens with score $bestScore from ${source.name}"],
    );
  }

  /// Learning Reinforcement Loop
  Future<void> reinforce({
    required String rawInput,
    required String subCategoryId,
    required InferenceSource source,
  }) async {
    final tokens = _normalizer.normalize(rawInput);
    if (tokens.isEmpty) return;
    
    final tokensJson = jsonEncode(tokens);
    final weight = _getSourceWeight(source);

    // Check if a similar pattern exists for this subcategory
    // For now, simpler exact match on tokens or create new
    // We try to find a learning entry that matches these exact tokens
    
    // Note: In real production, we might fuzzy match existing patterns to merge them.
    // Here we append a new distinct learning pattern if unique to preserve nuance.
    
    // Clean up old patterns for this subCateogry to avoid bloat? Maybe later (Drift Control).
    
    await _db.into(_db.categoryLearning).insert(
      CategoryLearningCompanion.insert(
        id: tokensJson.hashCode.toString(), // Simple ID generation
        merchantPattern: rawInput, // Keep raw for legacy/audit
        semanticTokens: Value(tokensJson),
        categoryName: 'Linked-SubCategory', // Legacy filler
        subCategoryId: Value(subCategoryId),
        sourceWeight: Value(weight),
        confidenceBoost: const Value(10),
        usageCount: const Value(1),
        lastUsedAt: DateTime.now(),
      ),
      mode: InsertMode.replace, // Upsert if ID collision (tokens same) 
      // Ideally we want to UPDATE usageCount if exists.
      // Drift's insertOnConflictUpdate is better.
    ); 

    // Also update the SubCategory's own usage stats
    final subCat = await (_db.select(_db.subCategories)..where((tbl) => tbl.id.equals(subCategoryId))).getSingleOrNull();
    if (subCat != null) {
      await (_db.update(_db.subCategories)..where((tbl) => tbl.id.equals(subCategoryId))).write(
        SubCategoriesCompanion(
          usageCount: Value(subCat.usageCount + 1),
          lastUsedAt: Value(DateTime.now()),
          // Improve confidence if it was low
          confidence: Value((subCat.confidence + 0.05).clamp(0.0, 1.0)), 
        ),
      );
    }
  }

  double _getSourceWeight(InferenceSource source) {
    switch (source) {
      case InferenceSource.manual: return 1.0;
      case InferenceSource.ocr: return 1.8;
      case InferenceSource.barcode: return 3.0; // Strongest signal
    }
  }
}
