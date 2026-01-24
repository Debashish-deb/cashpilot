import 'package:flutter/material.dart';

/// AppGradeIcons
/// Apple-grade semantic icon system
/// - Intent-first naming
/// - Alias support
/// - Stable fallback logic
/// - Future-ready for SF Symbols migration
class AppGradeIcons {
  /// Primary semantic icon registry
  static const Map<String, IconData> _iconMap = {
    // Shopping & Daily
    'shopping': Icons.shopping_bag_rounded,
    'groceries': Icons.shopping_cart_checkout_rounded,
    'food': Icons.restaurant_rounded,
    'coffee': Icons.local_cafe_rounded,
    'bar': Icons.wine_bar_rounded,
    'clothing': Icons.checkroom_rounded,
    'beauty': Icons.face_retouching_natural_rounded,
    'charity': Icons.volunteer_activism_rounded,
    'parking': Icons.local_parking_rounded,

    // Transport & Travel
    'transport': Icons.directions_car_rounded,
    'public transport': Icons.directions_bus_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'travel': Icons.flight_rounded,
    'hotel': Icons.hotel_rounded,

    // Home & Living
    'home': Icons.home_rounded,
    'rent': Icons.home_work_rounded,
    'utilities': Icons.bolt_rounded,
    'internet': Icons.router_rounded,
    'electricity': Icons.lightbulb_rounded,
    'water': Icons.water_drop_rounded,
    'gas': Icons.local_fire_department_rounded,
    'heating': Icons.thermostat_rounded,

    // Health & Wellness
    'health': Icons.favorite_rounded,
    'medical': Icons.local_hospital_rounded,
    'fitness': Icons.fitness_center_rounded,
    'wellness': Icons.spa_rounded,

    // Work & Education
    'work': Icons.work_rounded,
    'education': Icons.school_rounded,
    'books': Icons.menu_book_rounded,

    // Finance
    'savings': Icons.savings_rounded,
    'investment': Icons.trending_up_rounded,
    'insurance': Icons.verified_user_rounded,
    'tax': Icons.receipt_long_rounded,

    // Digital & Subscriptions
    'subscriptions': Icons.autorenew_rounded,
    'phone': Icons.phone_iphone_rounded,
    'apps': Icons.apps_rounded,

    // Social & Family
    'family': Icons.family_restroom_rounded,
    'pets': Icons.pets_rounded,
    'gifts': Icons.card_giftcard_rounded,

    // Entertainment
    'entertainment': Icons.movie_rounded,
    'music': Icons.music_note_rounded,
    'games': Icons.sports_esports_rounded,
    'hobbies': Icons.palette_rounded,
    
    // Expanded Categories (New)
    'electronics': Icons.devices_rounded,
    'repair': Icons.handyman_rounded,
    'garden': Icons.yard_rounded,
    'baby': Icons.child_friendly_rounded,
    'sports': Icons.sports_soccer_rounded,
    'liquor': Icons.liquor_rounded,
    'fees': Icons.account_balance_rounded,
    'pharmacy': Icons.medication_rounded,
    'laundry': Icons.local_laundry_service_rounded,
    'furniture': Icons.chair_rounded,
    
    // Batch 2 (Lifestyle & Specifics)
    'motorcycle': Icons.two_wheeler_rounded,
    'bike': Icons.pedal_bike_rounded,
    'taxi': Icons.local_taxi_rounded,
    'shipping': Icons.local_shipping_rounded,
    'photography': Icons.camera_alt_rounded,
    'art': Icons.brush_rounded,
    'pizza': Icons.local_pizza_rounded,
    'burger': Icons.lunch_dining_rounded,
    'icecream': Icons.icecream_rounded,
    'party': Icons.celebration_rounded,
    'haircut': Icons.content_cut_rounded,
    'recycling': Icons.recycling_rounded,
    'software': Icons.terminal_rounded,
    'printing': Icons.print_rounded,
    'cloud': Icons.cloud_rounded,
    'swimming': Icons.pool_rounded,
    'beach': Icons.beach_access_rounded,
  };

  /// Alias map — makes the system feel “intelligent”
  static const Map<String, String> _aliases = {
    'cart': 'shopping',
    'market': 'groceries',
    'restaurant': 'food',
    'dining': 'food',
    'car': 'transport',
    // 'bus' moved to public transport
    'fuel': 'transport',
    'net': 'internet',
    'wifi': 'internet',
    'mobile': 'phone',
    'cell': 'phone',
    'streaming': 'subscriptions',
    'netflix': 'subscriptions',
    'spotify': 'music',
    'doctor': 'medical',
    'hospital': 'medical',
    'gym': 'fitness',
    'salary': 'work',
    'office': 'work',
    'kids': 'family',
    'investments': 'investment',
    'stocks': 'investment',
    'crypto': 'investment',
    'movies': 'entertainment',
    'fun': 'entertainment',
    'bus': 'public transport',
    'train': 'public transport',
    'subway': 'public transport',
    'metro': 'public transport',
    'power': 'electricity',
    'tech': 'electronics',
    'computer': 'electronics',
    'gadget': 'electronics',
    'maintenance': 'repair',
    'fix': 'repair',
    'service': 'repair',
    'plants': 'garden',
    'flowers': 'garden',
    'lawn': 'garden',
    'nursery': 'baby',
    'childcare': 'baby',
    'soccer': 'sports',
    'football': 'sports',
    'alcohol': 'liquor',
    'beer': 'liquor',
    'wine': 'liquor',
    'bank': 'fees',
    'interest': 'fees',
    'medicine': 'pharmacy',
    'pills': 'pharmacy',
    'wash': 'laundry',
    'decor': 'furniture',
    'sofa': 'furniture',
    'delivery': 'shipping',
    'courier': 'shipping',
    'cycling': 'bike',
    'cab': 'taxi',
    'uber': 'taxi',
    'photos': 'photography',
    'painting': 'art',
    'design': 'art',
    'salon': 'haircut',
    'barber': 'haircut',
    'birthday': 'party',
    'cake': 'party',
    'software': 'software',
    'code': 'software',
    'ocean': 'beach',
    'sea': 'beach',
    'pool': 'swimming',
    'lights': 'electricity',
    'hydro': 'water',
    'propane': 'gas',
  };

  /// Public accessor
  /// This is what you should use everywhere
  static IconData getIcon(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) {
      return _fallback;
    }

    final key = rawName.toLowerCase().trim();

    // Direct hit
    if (_iconMap.containsKey(key)) {
      return _iconMap[key]!;
    }

    // Alias hit
    if (_aliases.containsKey(key)) {
      final resolved = _aliases[key]!;
      return _iconMap[resolved] ?? _fallback;
    }

    // Fuzzy keyword scan (Apple-style forgiveness)
    for (final entry in _iconMap.entries) {
      if (key.contains(entry.key)) {
        return entry.value;
      }
    }

    return _fallback;
  }

  /// Default fallback (changed to receipt for expenses visibility)
  static const IconData _fallback = Icons.receipt_outlined;

  /// Exposed list for pickers / grids
  /// Ordered intentionally (Apple grouping logic)
  static List<Map<String, IconData>> get pickerIcons => [
        // Daily
        {'shopping': Icons.shopping_bag_rounded},
        {'groceries': Icons.shopping_cart_checkout_rounded},
        {'food': Icons.restaurant_rounded},
        {'pizza': Icons.local_pizza_rounded},
        {'burger': Icons.lunch_dining_rounded},
        {'coffee': Icons.local_cafe_rounded},
        {'bar': Icons.wine_bar_rounded},
        {'liquor': Icons.liquor_rounded},

        // Transport
        {'transport': Icons.directions_car_rounded},
        {'fuel': Icons.local_gas_station_rounded},
        {'public transport': Icons.directions_bus_rounded},
        {'bike': Icons.pedal_bike_rounded},
        {'taxi': Icons.local_taxi_rounded},

        // Home & Utilities
        {'home': Icons.home_rounded},
        {'rent': Icons.home_work_rounded},
        {'utilities': Icons.bolt_rounded},
        {'electricity': Icons.lightbulb_rounded},
        {'water': Icons.water_drop_rounded},
        {'gas': Icons.local_fire_department_rounded},
        {'internet': Icons.router_rounded},
        {'phone': Icons.phone_iphone_rounded},
        {'furniture': Icons.chair_rounded},
        {'repair': Icons.handyman_rounded},
        {'garden': Icons.yard_rounded},

        // Health & Personal
        {'health': Icons.favorite_rounded},
        {'medical': Icons.local_hospital_rounded},
        {'pharmacy': Icons.medication_rounded},
        {'fitness': Icons.fitness_center_rounded},
        {'beauty': Icons.face_retouching_natural_rounded},
        {'haircut': Icons.content_cut_rounded},
        {'clothing': Icons.checkroom_rounded},

        // Life & Leisure
        {'entertainment': Icons.movie_rounded},
        {'music': Icons.music_note_rounded},
        {'party': Icons.celebration_rounded},
        {'hobbies': Icons.palette_rounded},
        {'photography': Icons.camera_alt_rounded},
        {'games': Icons.sports_esports_rounded},
        {'sports': Icons.sports_soccer_rounded},
        {'travel': Icons.flight_rounded},
        {'hotel': Icons.hotel_rounded},

        // Finance & Work
        {'work': Icons.work_rounded},
        {'education': Icons.school_rounded},
        {'electronics': Icons.devices_rounded},
        {'cloud': Icons.cloud_rounded},
        {'savings': Icons.savings_rounded},
        {'investment': Icons.trending_up_rounded},
        {'fees': Icons.account_balance_rounded},
        {'subscriptions': Icons.autorenew_rounded},

        // Family
        {'family': Icons.family_restroom_rounded},
        {'baby': Icons.child_friendly_rounded},
        {'pets': Icons.pets_rounded},
        {'gifts': Icons.card_giftcard_rounded},
        {'charity': Icons.volunteer_activism_rounded},
      ];
}
