/// Heuristic Rules for Expense Categorization
/// Amount, time, and day-based heuristics
library;

class HeuristicRules {
  /// Amount-based category suggestions
  /// Returns Map<category, confidence_boost>
  static Map<String, int> getAmountBasedSuggestions(int amountInCents) {
    final amount = amountInCents / 100;
    final suggestions = <String, int>{};
    
    // Micro-transactions (< $5)
    if (amount < 5) {
      suggestions['Food & Dining'] = 15; // Coffee, snacks
      suggestions['Transportation'] = 10; // Parking meters
    }
    
    // Small purchases ($5-$30)
    else if (amount >= 5 && amount < 30) {
      suggestions['Food & Dining'] = 20; // Meals
      suggestions['Personal Care'] = 10;
    }
    
    // Medium purchases ($30-$100)
    else if (amount >= 30 && amount < 100) {
      suggestions['Groceries'] = 15;
      suggestions['Shopping'] = 10;
      suggestions['Entertainment'] = 10;
    }
    
    // Large purchases ($100-$500)
    else if (amount >= 100 && amount < 500) {
      suggestions['Shopping'] = 15;
      suggestions['Home & Garden'] = 10;
      suggestions['Groceries'] = 10;
    }
    
    // Very large purchases (> $500)
    else {
      suggestions['Shopping'] = 10;
      suggestions['Home & Garden'] = 15;
      suggestions['Utilities'] = 5;
    }
    
    return suggestions;
  }
  
  /// Time-of-day based suggestions
  /// hour: 0-23
  static Map<String, int> getTimeBasedSuggestions(int hour) {
    final suggestions = <String, int>{};
    
    // Early morning (6-9 AM)
    if (hour >= 6 && hour < 9) {
      suggestions['Food & Dining'] = 20; // Breakfast/Coffee
      suggestions['Transportation'] = 10; // Commute
    }
    
    // Lunch time (12-2 PM)
    else if (hour >= 12 && hour < 14) {
      suggestions['Food & Dining'] = 25; // Lunch
    }
    
    // Dinner time (6-9 PM)
    else if (hour >= 18 && hour < 21) {
      suggestions['Food & Dining'] = 20; // Dinner
      suggestions['Entertainment'] = 10;
    }
    
    // Late night (10 PM - 2 AM)
    else if (hour >= 22 || hour < 2) {
      suggestions['Food & Dining'] = 15; // Late night food
      suggestions['Entertainment'] = 15; // Movies, bars
    }
    
    // Business hours (9 AM - 5 PM)
    else if (hour >= 9 && hour < 17) {
      suggestions['Shopping'] = 5;
      suggestions['Healthcare'] = 5;
    }
    
    return suggestions;
  }
  
  /// Day-of-week based suggestions
  /// weekday: 1 = Monday, 7 = Sunday
  static Map<String, int> getDayBasedSuggestions(int weekday) {
    final suggestions = <String, int>{};
    
    // Weekend (Saturday, Sunday)
    if (weekday >= 6) {
      suggestions['Entertainment'] = 15;
      suggestions['Food & Dining'] = 10;
      suggestions['Shopping'] = 10;
      suggestions['Home & Garden'] = 5;
    }
    
    // Weekdays
    else {
      suggestions['Transportation'] = 10; // Commute
      suggestions['Food & Dining'] = 5; // Work lunches
    }
    
    return suggestions;
  }
  
  /// Combine all heuristic scores
  static Map<String, int> getCombinedHeuristics({
    required int amountInCents,
    int? hour,
    int? weekday,
  }) {
    final combined = <String, int>{};
    
    // Amount-based (always available)
    final amountSuggestions = getAmountBasedSuggestions(amountInCents);
    for (final entry in amountSuggestions.entries) {
      combined[entry.key] = (combined[entry.key] ?? 0) + entry.value;
    }
    
    // Time-based (if available)
    if (hour != null) {
      final timeSuggestions = getTimeBasedSuggestions(hour);
      for (final entry in timeSuggestions.entries) {
        combined[entry.key] = (combined[entry.key] ?? 0) + entry.value;
      }
    }
    
    // Day-based (if available)
    if (weekday != null) {
      final daySuggestions = getDayBasedSuggestions(weekday);
      for (final entry in daySuggestions.entries) {
        combined[entry.key] = (combined[entry.key] ?? 0) + entry.value;
      }
    }
    
    return combined;
  }
}
