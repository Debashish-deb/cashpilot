/// Global Category Knowledge Base
/// Contains massive multilingual and multicultural keyword mappings for ML training.
library;

class GlobalCategoryKnowledge {
  /// Extensive map of Category -> List of Keywords/Tokens
  /// Includes various languages, slang, and cultural specifics.
  static const Map<String, List<String>> keywords = {
    // =========================================================================
    // FOOD & DINING
    // =========================================================================
    'Food & Dining': [
      // General
      'restaurant', 'cafe', 'bistro', 'diner', 'eatery', 'food', 'meal', 'lunch', 'dinner', 'breakfast', 'brunch', 'snack', 'buffet',
      // Fast Food
      'mcdonalds', 'kfc', 'burger king', 'subway', 'dominos', 'pizza hut', 'starbucks', 'dunkin', 'wendys', 'taco bell', 'chipotle',
      'shakeshack', 'five guys', 'panda express', 'nandos', 'bojangles', 'sonic', 'dairy queen', 'arby', 'popeyes', 'jimmy johns',
      // Asian / Oriental
      'sushi', 'ramen', 'dim sum', 'dumpling', 'pho', 'banh mi', 'curry', 'biryani', 'masala', 'tikka', 'naan', 'dosa', 'thali', 'chaat',
      'sashimi', 'tempura', 'udon', 'soba', 'teriyaki', 'kimchi', 'bibimbap', 'bulgogi', 'kbbq', 'hotpot', 'pad thai', 'satay', 'nasi goreng',
      'laksa', 'bubble tea', 'boba', 'matcha', 'chai', 'tea',
      // European / Western
      'pasta', 'pizza', 'gelato', 'tapas', 'paella', 'crepe', 'croissant', 'baguette', 'schnitzel', 'bratwurst', 'pretzel', 'fish and chips',
      'steak', 'bbq', 'grill', 'roast', 'pub', 'bar', 'brewery', 'winery',
      // Latin American
      'tacos', 'burrito', 'quesadilla', 'enchilada', 'fajita', 'salsa', 'guacamole', 'arepa', 'empanada', 'ceviche', 'churros',
      // Middle Eastern
      'kebab', 'shawarma', 'falafel', 'hummus', 'baklava', 'mezze', 'pita',
      // Specific Keywords
      'bakery', 'patisserie', 'dessert', 'ice cream', 'cake', 'donut', 'coffee', 'espresso', 'latte', 'cappuccino',
      'uber eats', 'doordash', 'grubhub', 'postmates', 'deliveroo', 'zomato', 'swiggy', 'foodpanda',
    ],

    'Groceries': [
      // General
      'grocery', 'supermarket', 'market', 'convenience store', 'mart', 'food store',
      // Chains (Global/Regional)
      'walmart', 'target', 'costco', 'whole foods', 'trader joes', 'aldi', 'lidl', 'kroger', 'safeway', 'tesco', 'sainsburys', 'asda', 'carrefour',
      'rewe', 'edeka', 'woolworths', 'coles', 'aeon', '7-eleven', 'seven eleven', 'wawa', 'sheetz', 'circle k', 'family mart', 'lawson',
      // Items
      'fruit', 'vegetable', 'meat', 'dairy', 'bakery', 'seafood', 'produce', 'deli', 'butcher',
    ],

    // =========================================================================
    // TRANSPORTATION
    // =========================================================================
    'Transportation': [
      // Ride Share / Taxi
      'uber', 'lyft', 'grab', 'gojek', 'ola', 'bolt', 'didi', 'cab', 'taxi', 'limo', 'chauffeur',
      // Public Transport
      'bus', 'train', 'subway', 'metro', 'tram', 'trolley', 'shuttle', 'ferry', 'monorail', 'mrt', 'lrt', 'jr pass', 'oyster card', 'clipper',
      'amtrak', 'eurostar', 'greyhound', 'flixbus',
      // Auto / Car
      'fuel', 'gas', 'petrol', 'diesel', 'gas station', 'petrol station', 'shell', 'bp', 'exxon', 'mobil', 'texaco', 'chevron', 'total', 'caltex',
      'parking', 'garage', 'valet', 'toll', 'meter', 'ezpass', 'fastag',
      'car wash', 'auto repair', 'mechanic', 'oil change', 'tire', 'service', 'maintenance',
      // Cultural
      'rickshaw', 'tuk tuk', 'auto', 'jeepney', 'songthaew', 'boda boda', 'matatu',
    ],

    // =========================================================================
    // HOUSING & UTILITIES
    // =========================================================================
    'Rent': ['rent', 'lease', 'landlord', 'tenant', 'apartment', 'housing', 'lodging'],
    'Mortgage': ['mortgage', 'home loan', 'principal', 'interest', 'escrow'],
    'Utilities': [
      'electric', 'electricity', 'power', 'energy', 'utility', 'bill', 'water', 'sewage', 'trash', 'garbage', 'recycling', 'gas', 'heating',
      'internet', 'wifi', 'fiber', 'cable', 'broadband', 'comcast', 'xfinity', 'verizon', 'att', 't-mobile', 'vodafone', 'orange', 'telstra',
      'spectrum', 'charter', 'phone bill', 'mobile bill', 'prepaid', 'postpaid',
    ],

    // =========================================================================
    // SHOPPING
    // =========================================================================
    'Shopping': [
      // General
      'shopping', 'store', 'retail', 'mall', 'outlet', 'boutique',
      // Online
      'amazon', 'ebay', 'etsy', 'aliexpress', 'alibaba', 'taobao', 'rakuten', 'flipkart', 'shopee', 'lazada', 'shopify',
      // Clothing
      'clothing', 'apparel', 'fashion', 'wear', 'shoes', 'footwear', 'zara', 'h&m', 'uniqlo', 'nike', 'adidas', 'puma', 'gucci', 'prada', 'lv',
      // Electronics
      'electronics', 'tech', 'gadget', 'computer', 'phone', 'apple', 'best buy', 'media markt', 'fry', 'micro center',
    ],

    // =========================================================================
    // HEALTH & WELLNESS
    // =========================================================================
    'Health': [
      'doctor', 'medical', 'hospital', 'clinic', 'urgent care', 'physician', 'specialist', 'dentist', 'dental', 'vision', 'optometrist',
      'pharmacy', 'drugstore', 'medicine', 'prescription', 'rx', 'cvs', 'walgreens', 'rite aid', 'boots',
      'gym', 'fitness', 'workout', 'yoga', 'pilates', 'crossfit', 'trainer', 'golds gym', 'planet fitness', 'equinox',
    ],

    // =========================================================================
    // TRAVEL
    // =========================================================================
    'Travel': [
      'flight', 'airline', 'airfare', 'ticket', 'booking', 'expedia', 'kayak', 'skyscanner', 'delta', 'united', 'american', 'lufthansa', 'emirates',
      'hotel', 'motel', 'resort', 'inn', 'hostel', 'airbnb', 'booking.com', 'agoda', 'hotels.com', 'marriott', 'hilton', 'hyatt', 'ihg',
      'vacation', 'trip', 'tour', 'cruise', 'passport', 'visa', 'duty free',
    ],

    // =========================================================================
    // ENTERTAINMENT
    // =========================================================================
    'Entertainment': [
      'movie', 'cinema', 'theater', 'film', 'amc', 'regal', 'cinemark',
      'concert', 'gig', 'show', 'ticketmaster', 'stubhub',
      'game', 'gaming', 'steam', 'playstation', 'xbox', 'nintendo', 'twitch',
      'bar', 'nightclub', 'club', 'pub', 'lounge',
      'bowling', 'golf', 'karaoke', 'museum', 'gallery', 'zoo', 'aquarium',
      'netflix', 'hulu', 'disney', 'spotify', 'youtube', 'prime video', 'hbo', 'apple music', 'soundcloud', 'audible', 'kindle',
    ],
  };

  /// Flattened list of all keywords for validation or other uses
  static Set<String> get allKeywords => keywords.values.expand((x) => x).toSet();
}
