/// Industrial-standard category list for personal finance
/// Uses localization keys for dynamic language switching.
library;
import 'package:flutter/material.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

/// Localized category for industry-standard categories
/// Named differently from DefaultCategory in category_defaults.dart
class LocalizedCategory {
  final String localizationKey; 
  final String groupKey; 
  final String iconName; 
  final String colorHex;
  final String? parentKey; // Added for hierarchy support

  const LocalizedCategory({
    required this.localizationKey,
    required this.groupKey,
    this.iconName = 'category',
    this.colorHex = '#808080',
    this.parentKey,
  });

  /// Returns localized name using the app's current locale.
  String getLocalizedName(BuildContext context) {
    return _getCategoryLocalized(context, localizationKey);
  }

  /// Returns localized group name using the app's current locale.
  String getLocalizedGroup(BuildContext context) {
    return _getGroupLocalized(context, groupKey);
  }
}

/// Helper to map category localization keys to their localized strings.
/// Falls back to converting the key to a human-readable format if not found.
String _getCategoryLocalized(BuildContext context, String key) {
  // Convert camelCase key to human-readable: 'catRestaurants' -> 'Restaurants'
  String humanReadable(String k) {
    // Remove 'cat' prefix
    final withoutPrefix = k.startsWith('cat') ? k.substring(3) : k;
    // Add spaces before capitals and capitalize first letter
    final spaced = withoutPrefix.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => ' ${m.group(1)}',
    ).trim();
    return spaced.isEmpty ? k : spaced;
  }

  // For now, return human-readable version of the key
  // In the future, localized versions can be added to ARB files
  return humanReadable(key);
}

/// Helper to map group localization keys to their localized strings.
String _getGroupLocalized(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context)!;
  switch (key) {
    case 'catGroupHousing': return l10n.catGroupHousing;
    case 'catGroupUtilities': return l10n.catGroupUtilities;
    case 'catGroupFood': return l10n.catGroupFood;
    case 'catGroupTransportation': return l10n.catGroupTransportation;
    case 'catGroupHealth': return l10n.catGroupHealth;
    case 'catGroupLifestyle': return l10n.catGroupLifestyle;
    case 'catGroupFinance': return l10n.catGroupFinance;
    case 'catGroupFamily': return l10n.catGroupFamily;
    case 'catGroupTech': return l10n.catGroupTech;
    default: return key;
  }
}

const List<LocalizedCategory> industrialCategories = [
  // Master Categories (Top Level)
  LocalizedCategory(localizationKey: 'catHousing', groupKey: 'catGroupHousing', iconName: 'home', colorHex: '#4285F4'),
  LocalizedCategory(localizationKey: 'catUtilities', groupKey: 'catGroupUtilities', iconName: 'electrical_services', colorHex: '#FBBC05'),
  LocalizedCategory(localizationKey: 'catFood', groupKey: 'catGroupFood', iconName: 'restaurant', colorHex: '#EA4335'),
  LocalizedCategory(localizationKey: 'catTransportation', groupKey: 'catGroupTransportation', iconName: 'directions_car', colorHex: '#34A853'),
  LocalizedCategory(localizationKey: 'catHealth', groupKey: 'catGroupHealth', iconName: 'medical_services', colorHex: '#FF6D01'),
  LocalizedCategory(localizationKey: 'catLifestyle', groupKey: 'catGroupLifestyle', iconName: 'self_improvement', colorHex: '#9C27B0'),
  LocalizedCategory(localizationKey: 'catFinance', groupKey: 'catGroupFinance', iconName: 'savings', colorHex: '#009688'),
  LocalizedCategory(localizationKey: 'catEducation', groupKey: 'catGroupEducation', iconName: 'school', colorHex: '#1A73E8'),
  LocalizedCategory(localizationKey: 'catFamily', groupKey: 'catGroupFamily', iconName: 'family_restroom', colorHex: '#795548'),
  LocalizedCategory(localizationKey: 'catTech', groupKey: 'catGroupTech', iconName: 'computer', colorHex: '#607D8B'),
  LocalizedCategory(localizationKey: 'catHobbies', groupKey: 'catGroupHobby', iconName: 'palette', colorHex: '#FBBC04'),
  LocalizedCategory(localizationKey: 'catUndeclared', groupKey: 'catGroupNone', iconName: 'question_mark', colorHex: '#808080'),

  // Housing
  LocalizedCategory(localizationKey: 'catRent', groupKey: 'catGroupHousing', iconName: 'home', colorHex: '#4285F4', parentKey: 'catHousing'),
  LocalizedCategory(localizationKey: 'catMortgage', groupKey: 'catGroupHousing', iconName: 'home_work', colorHex: '#1967D2', parentKey: 'catHousing'),
  LocalizedCategory(localizationKey: 'catPropertyTax', groupKey: 'catGroupHousing', iconName: 'receipt', colorHex: '#185ABC', parentKey: 'catHousing'),
  LocalizedCategory(localizationKey: 'catHomeInsurance', groupKey: 'catGroupHousing', iconName: 'security', colorHex: '#4285F4', parentKey: 'catHousing'),
  LocalizedCategory(localizationKey: 'catRepairsMaintenance', groupKey: 'catGroupHousing', iconName: 'build', colorHex: '#FBBC04', parentKey: 'catHousing'),
  LocalizedCategory(localizationKey: 'catGardening', groupKey: 'catGroupHousing', iconName: 'park', colorHex: '#4CAF50', parentKey: 'catHousing'),
  LocalizedCategory(localizationKey: 'catHomeHardware', groupKey: 'catGroupHousing', iconName: 'handyman', colorHex: '#795548', parentKey: 'catHousing'),
  
  // Utilities
  LocalizedCategory(localizationKey: 'catElectricity', groupKey: 'catGroupUtilities', iconName: 'electric_bolt', colorHex: '#FBBC04', parentKey: 'catUtilities'),
  LocalizedCategory(localizationKey: 'catWater', groupKey: 'catGroupUtilities', iconName: 'water_drop', colorHex: '#4285F4', parentKey: 'catUtilities'),
  LocalizedCategory(localizationKey: 'catGas', groupKey: 'catGroupUtilities', iconName: 'local_fire_department', colorHex: '#EA4335', parentKey: 'catUtilities'),
  LocalizedCategory(localizationKey: 'catInternet', groupKey: 'catGroupUtilities', iconName: 'wifi', colorHex: '#34A853', parentKey: 'catUtilities'),
  LocalizedCategory(localizationKey: 'catPhone', groupKey: 'catGroupUtilities', iconName: 'phone_iphone', colorHex: '#34A853', parentKey: 'catUtilities'),
  LocalizedCategory(localizationKey: 'catPublicServices', groupKey: 'catGroupUtilities', iconName: 'account_balance', colorHex: '#607D8B', parentKey: 'catUtilities'),
  
  // Food
  LocalizedCategory(localizationKey: 'catGroceries', groupKey: 'catGroupFood', iconName: 'shopping_cart', colorHex: '#34A853', parentKey: 'catFood'),
  LocalizedCategory(localizationKey: 'catRestaurants', groupKey: 'catGroupFood', iconName: 'restaurant', colorHex: '#EA4335', parentKey: 'catFood'),
  LocalizedCategory(localizationKey: 'catCoffeeShops', groupKey: 'catGroupFood', iconName: 'coffee', colorHex: '#795548', parentKey: 'catFood'),
  LocalizedCategory(localizationKey: 'catAlcohol', groupKey: 'catGroupFood', iconName: 'wine_bar', colorHex: '#9C27B0', parentKey: 'catFood'),
  LocalizedCategory(localizationKey: 'catDelivery', groupKey: 'catGroupFood', iconName: 'delivery_dining', colorHex: '#EA4335', parentKey: 'catFood'),
  LocalizedCategory(localizationKey: 'catStreetFood', groupKey: 'catGroupFood', iconName: 'restaurant', colorHex: '#FF5722', parentKey: 'catFood'),
  LocalizedCategory(localizationKey: 'catTiffin', groupKey: 'catGroupFood', iconName: 'lunch_dining', colorHex: '#8BC34A', parentKey: 'catFood'),
  LocalizedCategory(localizationKey: 'catPizza', groupKey: 'catGroupFood', iconName: 'pizza', colorHex: '#FF9800', parentKey: 'catFood'),
  LocalizedCategory(localizationKey: 'catBurger', groupKey: 'catGroupFood', iconName: 'burger', colorHex: '#FFA000', parentKey: 'catFood'),
  LocalizedCategory(localizationKey: 'catIcecream', groupKey: 'catGroupFood', iconName: 'icecream', colorHex: '#F06292', parentKey: 'catFood'),
  LocalizedCategory(localizationKey: 'catBakery', groupKey: 'catGroupFood', iconName: 'bakery_dining', colorHex: '#D2B48C', parentKey: 'catFood'),

  // Transportation
  LocalizedCategory(localizationKey: 'catFuel', groupKey: 'catGroupTransportation', iconName: 'local_gas_station', colorHex: '#EA4335', parentKey: 'catTransportation'),
  LocalizedCategory(localizationKey: 'catPublicTransport', groupKey: 'catGroupTransportation', iconName: 'directions_bus', colorHex: '#4285F4', parentKey: 'catTransportation'),
  LocalizedCategory(localizationKey: 'catCarMaintenance', groupKey: 'catGroupTransportation', iconName: 'car_repair', colorHex: '#5F6368', parentKey: 'catTransportation'),
  LocalizedCategory(localizationKey: 'catParking', groupKey: 'catGroupTransportation', iconName: 'local_parking', colorHex: '#5F6368', parentKey: 'catTransportation'),
  LocalizedCategory(localizationKey: 'catCarInsurance', groupKey: 'catGroupTransportation', iconName: 'security', colorHex: '#4285F4', parentKey: 'catTransportation'),
  LocalizedCategory(localizationKey: 'catRideshare', groupKey: 'catGroupTransportation', iconName: 'local_taxi', colorHex: '#000000', parentKey: 'catTransportation'),
  LocalizedCategory(localizationKey: 'catMotorcycle', groupKey: 'catGroupTransportation', iconName: 'motorcycle', colorHex: '#5F6368', parentKey: 'catTransportation'),
  LocalizedCategory(localizationKey: 'catBike', groupKey: 'catGroupTransportation', iconName: 'bike', colorHex: '#34A853', parentKey: 'catTransportation'),
  LocalizedCategory(localizationKey: 'catTaxi', groupKey: 'catGroupTransportation', iconName: 'taxi', colorHex: '#FFC107', parentKey: 'catTransportation'),
  LocalizedCategory(localizationKey: 'catShipping', groupKey: 'catGroupTransportation', iconName: 'shipping', colorHex: '#795548', parentKey: 'catTransportation'),
  LocalizedCategory(localizationKey: 'catParkingFees', groupKey: 'catGroupTransportation', iconName: 'local_parking', colorHex: '#546E7A', parentKey: 'catTransportation'),
  LocalizedCategory(localizationKey: 'catBridgeTolls', groupKey: 'catGroupTransportation', iconName: 'drive_eta', colorHex: '#455A64', parentKey: 'catTransportation'),

  // Health
  LocalizedCategory(localizationKey: 'catMedical', groupKey: 'catGroupHealth', iconName: 'medical_services', colorHex: '#EA4335', parentKey: 'catHealth'),
  LocalizedCategory(localizationKey: 'catPharmacy', groupKey: 'catGroupHealth', iconName: 'medication', colorHex: '#EA4335', parentKey: 'catHealth'),
  LocalizedCategory(localizationKey: 'catDental', groupKey: 'catGroupHealth', iconName: 'masks', colorHex: '#4285F4', parentKey: 'catHealth'),
  LocalizedCategory(localizationKey: 'catFitness', groupKey: 'catGroupHealth', iconName: 'fitness_center', colorHex: '#34A853', parentKey: 'catHealth'),

  // Lifestyle
  LocalizedCategory(localizationKey: 'catClothing', groupKey: 'catGroupLifestyle', iconName: 'checkroom', colorHex: '#9C27B0', parentKey: 'catLifestyle'),
  LocalizedCategory(localizationKey: 'catPersonalCare', groupKey: 'catGroupLifestyle', iconName: 'face', colorHex: '#EC407A', parentKey: 'catLifestyle'),
  LocalizedCategory(localizationKey: 'catEntertainment', groupKey: 'catGroupLifestyle', iconName: 'movie', colorHex: '#8E24AA', parentKey: 'catLifestyle'),
  LocalizedCategory(localizationKey: 'catTravel', groupKey: 'catGroupLifestyle', iconName: 'flight', colorHex: '#00ACC1', parentKey: 'catLifestyle'),
  LocalizedCategory(localizationKey: 'catPhotography', groupKey: 'catGroupLifestyle', iconName: 'camera', colorHex: '#607D8B', parentKey: 'catLifestyle'),
  LocalizedCategory(localizationKey: 'catArt', groupKey: 'catGroupLifestyle', iconName: 'brush', colorHex: '#E91E63', parentKey: 'catLifestyle'),
  LocalizedCategory(localizationKey: 'catParty', groupKey: 'catGroupLifestyle', iconName: 'party', colorHex: '#9C27B0', parentKey: 'catLifestyle'),
  LocalizedCategory(localizationKey: 'catHaircut', groupKey: 'catGroupLifestyle', iconName: 'haircut', colorHex: '#795548', parentKey: 'catLifestyle'),
  LocalizedCategory(localizationKey: 'catSwimming', groupKey: 'catGroupLifestyle', iconName: 'pool', colorHex: '#03A9F4', parentKey: 'catLifestyle'),
  LocalizedCategory(localizationKey: 'catFestivals', groupKey: 'catGroupLifestyle', iconName: 'celebration', colorHex: '#9C27B0', parentKey: 'catLifestyle'),
  
  // Hobbies (New Master Structure)
  LocalizedCategory(localizationKey: 'catGaming', groupKey: 'catGroupHobby', iconName: 'sports_esports', colorHex: '#7E57C2', parentKey: 'catHobbies'),
  LocalizedCategory(localizationKey: 'catMusic', groupKey: 'catGroupHobby', iconName: 'music_note', colorHex: '#EC407A', parentKey: 'catHobbies'),
  LocalizedCategory(localizationKey: 'catReading', groupKey: 'catGroupHobby', iconName: 'menu_book', colorHex: '#5D4037', parentKey: 'catHobbies'),
  LocalizedCategory(localizationKey: 'catSports', groupKey: 'catGroupHobby', iconName: 'sports_soccer', colorHex: '#4CAF50', parentKey: 'catHobbies'),
  LocalizedCategory(localizationKey: 'catCollecting', groupKey: 'catGroupHobby', iconName: 'category', colorHex: '#FFB300', parentKey: 'catHobbies'),
  LocalizedCategory(localizationKey: 'catDIY', groupKey: 'catGroupHobby', iconName: 'handyman', colorHex: '#F4511E', parentKey: 'catHobbies'),
  LocalizedCategory(localizationKey: 'catPottery', groupKey: 'catGroupHobby', iconName: 'brush', colorHex: '#795548', parentKey: 'catHobbies'),
  
  // Finance
  LocalizedCategory(localizationKey: 'catSavings', groupKey: 'catGroupFinance', iconName: 'savings', colorHex: '#34A853', parentKey: 'catFinance'),
  LocalizedCategory(localizationKey: 'catInvestments', groupKey: 'catGroupFinance', iconName: 'trending_up', colorHex: '#34A853', parentKey: 'catFinance'),
  LocalizedCategory(localizationKey: 'catDebtRepayment', groupKey: 'catGroupFinance', iconName: 'credit_card_off', colorHex: '#EA4335', parentKey: 'catFinance'),
  LocalizedCategory(localizationKey: 'catTaxes', groupKey: 'catGroupFinance', iconName: 'account_balance', colorHex: '#5F6368', parentKey: 'catFinance'),
  LocalizedCategory(localizationKey: 'catFees', groupKey: 'catGroupFinance', iconName: 'remove_circle_outline', colorHex: '#EA4335', parentKey: 'catFinance'),
  LocalizedCategory(localizationKey: 'catCharity', groupKey: 'catGroupFinance', iconName: 'favorite', colorHex: '#E91E63', parentKey: 'catFinance'),
  LocalizedCategory(localizationKey: 'catAdvisorFees', groupKey: 'catGroupFinance', iconName: 'person_outline', colorHex: '#607D8B', parentKey: 'catFinance'),
  LocalizedCategory(localizationKey: 'catBankFees', groupKey: 'catGroupFinance', iconName: 'money_off', colorHex: '#D32F2F', parentKey: 'catFinance'),

  // Family
  LocalizedCategory(localizationKey: 'catChildcare', groupKey: 'catGroupFamily', iconName: 'child_care', colorHex: '#FBBC04', parentKey: 'catFamily'),
  LocalizedCategory(localizationKey: 'catPets', groupKey: 'catGroupFamily', iconName: 'pets', colorHex: '#795548', parentKey: 'catFamily'),
  LocalizedCategory(localizationKey: 'catGifts', groupKey: 'catGroupFamily', iconName: 'card_giftcard', colorHex: '#E91E63', parentKey: 'catFamily'),
  LocalizedCategory(localizationKey: 'catReligious', groupKey: 'catGroupFamily', iconName: 'account_balance', colorHex: '#FFC107', parentKey: 'catFamily'),

  // Education (New Subcategories)
  LocalizedCategory(localizationKey: 'catTuition', groupKey: 'catGroupEducation', iconName: 'school', colorHex: '#1A73E8', parentKey: 'catEducation'),
  LocalizedCategory(localizationKey: 'catBooks', groupKey: 'catGroupEducation', iconName: 'menu_book', colorHex: '#795548', parentKey: 'catEducation'),
  LocalizedCategory(localizationKey: 'catOnlineCourses', groupKey: 'catGroupEducation', iconName: 'laptop_mac', colorHex: '#00BCD4', parentKey: 'catEducation'),
  LocalizedCategory(localizationKey: 'catSupplies', groupKey: 'catGroupEducation', iconName: 'edit', colorHex: '#FFC107', parentKey: 'catEducation'),
  LocalizedCategory(localizationKey: 'catStudentLoans', groupKey: 'catGroupEducation', iconName: 'account_balance_wallet', colorHex: '#F44336', parentKey: 'catEducation'),
  LocalizedCategory(localizationKey: 'catCertifications', groupKey: 'catGroupEducation', iconName: 'workspace_premium', colorHex: '#FF9800', parentKey: 'catEducation'),

  // Tech & Services
  LocalizedCategory(localizationKey: 'catSoftware', groupKey: 'catGroupTech', iconName: 'code', colorHex: '#4285F4', parentKey: 'catTech'),
  LocalizedCategory(localizationKey: 'catElectronics', groupKey: 'catGroupTech', iconName: 'devices', colorHex: '#5F6368', parentKey: 'catTech'),
  LocalizedCategory(localizationKey: 'catSubscriptions', groupKey: 'catGroupTech', iconName: 'subscriptions', colorHex: '#EA4335', parentKey: 'catTech'),
  LocalizedCategory(localizationKey: 'catCloud', groupKey: 'catGroupTech', iconName: 'cloud', colorHex: '#4285F4', parentKey: 'catTech'),
  LocalizedCategory(localizationKey: 'catPrinting', groupKey: 'catGroupTech', iconName: 'print', colorHex: '#5F6368', parentKey: 'catTech'),
  LocalizedCategory(localizationKey: 'catElectronicsRepair', groupKey: 'catGroupTech', iconName: 'settings_suggest', colorHex: '#607D8B', parentKey: 'catTech'),
  LocalizedCategory(localizationKey: 'catAI', groupKey: 'catGroupTech', iconName: 'psychology', colorHex: '#673AB7', parentKey: 'catTech'),
  LocalizedCategory(localizationKey: 'catTechHardware', groupKey: 'catGroupTech', iconName: 'memory', colorHex: '#4CAF50', parentKey: 'catTech'),
];

// CATEGORY UTILITIES (NON-BREAKING, ADDITIVE)

extension LocalizedCategoryUI on LocalizedCategory {
  /// Resolve Material icon from iconName
  IconData resolveIcon({TargetPlatform? platform}) {
    return CategoryIconMapper.resolve(iconName);
  }

  /// Primary color (theme-aware)
  Color resolveColor(BuildContext context) {
    final base = _parseHex(colorHex);
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? _lighten(base, 0.18)
        : base;
  }

  /// Secondary accent color (computed)
  Color resolveAccentColor(BuildContext context) {
    final base = resolveColor(context);
    return _lighten(base, 0.28);
  }

  /// Gradient pair (primary → accent)
  List<Color> gradient(BuildContext context) {
    return [
      resolveColor(context),
      resolveAccentColor(context),
    ];
  }

  /// Chart-safe color (desaturated, stable)
  Color chartColor(BuildContext context) {
    final base = resolveColor(context);
    final hsl = HSLColor.fromColor(base);
    return hsl.withSaturation(hsl.saturation * 0.65).toColor();
  }

  /// Needs / Wants heuristic (derived, not stored)
  bool get isNeed {
    return const {
      'catGroupHousing',
      'catGroupUtilities',
      'catGroupTransportation',
      'catGroupHealth',
      'catGroupFinance',
    }.contains(groupKey);
  }

  bool get isWant => !isNeed;
}

// ICON MAPPER (SINGLE SOURCE OF TRUTH)

class CategoryIconMapper {
  static const Map<String, IconData> _materialIcons = {
    // Housing
    'home': Icons.home_outlined,
    'home_work': Icons.home_work_outlined,
    'receipt': Icons.receipt_long_outlined,
    'security': Icons.verified_user_outlined,
    'build': Icons.build_outlined,
    'park': Icons.park_outlined,
    'handyman': Icons.handyman_outlined,

    // Utilities
    'electric_bolt': Icons.electric_bolt_outlined,
    'water_drop': Icons.water_drop_outlined,
    'local_fire_department': Icons.local_fire_department_outlined,
    'wifi': Icons.wifi_outlined,
    'phone_iphone': Icons.phone_iphone_outlined,
    'account_balance': Icons.account_balance_outlined,

    // Food
    'shopping_cart': Icons.local_grocery_store_outlined,
    'restaurant': Icons.restaurant_outlined,
    'coffee': Icons.coffee_outlined,
    'wine_bar': Icons.wine_bar_outlined,
    'delivery_dining': Icons.delivery_dining_outlined,
    'lunch_dining': Icons.lunch_dining_outlined,

    // Transport
    'local_gas_station': Icons.local_gas_station_outlined,
    'directions_bus': Icons.directions_bus_outlined,
    'car_repair': Icons.car_repair_outlined,
    'local_parking': Icons.local_parking_outlined,
    'local_taxi': Icons.local_taxi_outlined,
    'drive_eta': Icons.drive_eta_outlined,

    // Health
    'medical_services': Icons.medical_services_outlined,
    'medication': Icons.medication_outlined,
    'masks': Icons.masks_outlined,
    'fitness_center': Icons.fitness_center_outlined,

    // Lifestyle
    'checkroom': Icons.checkroom_outlined,
    'face': Icons.face_outlined,
    'movie': Icons.movie_outlined,
    'palette': Icons.palette_outlined,
    'flight': Icons.flight_outlined,
    'camera': Icons.camera_alt_outlined,
    'brush': Icons.brush_outlined,
    'party': Icons.celebration_outlined,
    'haircut': Icons.content_cut_outlined,
    'pool': Icons.pool_outlined,
    'celebration': Icons.celebration_outlined,

    // Finance
    'savings': Icons.savings_outlined,
    'trending_up': Icons.trending_up_outlined,
    'credit_card_off': Icons.credit_card_off_outlined,
    'remove_circle_outline': Icons.remove_circle_outline,
    'favorite': Icons.favorite_outline,
    'person_outline': Icons.person_outline,
    'money_off': Icons.money_off_outlined,

    // Family / Education
    'child_care': Icons.child_care_outlined,
    'school': Icons.school_outlined,
    'pets': Icons.pets_outlined,
    'card_giftcard': Icons.card_giftcard_outlined,
    'menu_book': Icons.menu_book_outlined,
    'laptop_mac': Icons.laptop_mac_outlined,
    'edit': Icons.edit_outlined,
    'account_balance_wallet': Icons.account_balance_wallet_outlined,
    'workspace_premium': Icons.workspace_premium_outlined,

    // Tech
    'code': Icons.code_outlined,
    'devices': Icons.devices_outlined,
    'subscriptions': Icons.subscriptions_outlined,
    'cloud': Icons.cloud_outlined,
    'print': Icons.print,
    'settings_suggest': Icons.settings_suggest_outlined,
    'psychology': Icons.psychology_outlined,
    'memory': Icons.memory_outlined,

    // Hobbies (Material 3)
    'sports_esports': Icons.sports_esports_outlined,
    'music_note': Icons.music_note_outlined,
    'sports_soccer': Icons.sports_soccer_outlined,
    'category': Icons.category_outlined,
    
    // New Food
    'pizza': Icons.local_pizza_outlined,
    'burger': Icons.lunch_dining_outlined,
    'icecream': Icons.icecream_outlined,
    'bakery_dining': Icons.bakery_dining_outlined,

    // New Transport
    'motorcycle': Icons.two_wheeler_outlined,
    'bike': Icons.pedal_bike_outlined,
    'taxi': Icons.local_taxi_outlined,
    'shipping': Icons.local_shipping_outlined,
  };

  static IconData resolve(String name) {
    return _materialIcons[name] ?? Icons.category_outlined;
  }
}

// COLOR HELPERS (PURE FUNCTIONS)

Color _parseHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

Color _lighten(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
      .toColor();
}
