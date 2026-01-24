/// Industrial-standard category list for personal finance
/// Uses localization keys for dynamic language switching.
library;
import 'package:flutter/material.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

/// Localized category for industry-standard categories
/// Named differently from DefaultCategory in category_defaults.dart
class LocalizedCategory {
  final String localizationKey; // ARB key, e.g., 'catRent'
  final String groupKey; // ARB key for group, e.g., 'catGroupHousing'
  final String iconName; // Simple string identifier for mapping to IconData
  final String colorHex;

  const LocalizedCategory({
    required this.localizationKey,
    required this.groupKey,
    this.iconName = 'category',
    this.colorHex = '#808080',
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
String _getCategoryLocalized(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context)!;
  switch (key) {
    // Housing
    case 'catRent': return l10n.catRent;
    case 'catMortgage': return l10n.catMortgage;
    case 'catPropertyTax': return l10n.catPropertyTax;
    case 'catHomeInsurance': return l10n.catHomeInsurance;
    case 'catRepairsMaintenance': return l10n.catRepairsMaintenance;
    // Utilities
    case 'catElectricity': return l10n.catElectricity;
    case 'catWater': return l10n.catWater;
    case 'catGas': return l10n.catGas;
    case 'catInternet': return l10n.catInternet;
    case 'catPhone': return l10n.catPhone;
    // Food
    case 'catGroceries': return l10n.catGroceries;
    case 'catRestaurants': return l10n.catRestaurants;
    case 'catCoffeeShops': return l10n.catCoffeeShops;
    case 'catAlcohol': return l10n.catAlcohol;
    case 'catDelivery': return l10n.catDelivery;
    // Transportation
    case 'catFuel': return l10n.catFuel;
    case 'catPublicTransport': return l10n.catPublicTransport;
    case 'catCarMaintenance': return l10n.catCarMaintenance;
    case 'catParking': return l10n.catParking;
    case 'catCarInsurance': return l10n.catCarInsurance;
    case 'catRideshare': return l10n.catRideshare;
    // Health
    case 'catMedical': return l10n.catMedical;
    case 'catPharmacy': return l10n.catPharmacy;
    case 'catDental': return l10n.catDental;
    case 'catFitness': return l10n.catFitness;
    // Lifestyle
    case 'catClothing': return l10n.catClothing;
    case 'catPersonalCare': return l10n.catPersonalCare;
    case 'catEntertainment': return l10n.catEntertainment;
    case 'catHobbies': return l10n.catHobbies;
    case 'catTravel': return l10n.catTravel;
    // Finance
    case 'catSavings': return l10n.catSavings;
    case 'catInvestments': return l10n.catInvestments;
    case 'catDebtRepayment': return l10n.catDebtRepayment;
    case 'catTaxes': return l10n.catTaxes;
    case 'catFees': return l10n.catFees;
    // Family
    case 'catChildcare': return l10n.catChildcare;
    case 'catEducation': return l10n.catEducation;
    case 'catPets': return l10n.catPets;
    case 'catGifts': return l10n.catGifts;
    // Tech
    case 'catSoftware': return l10n.catSoftware;
    case 'catElectronics': return l10n.catElectronics;
    case 'catSubscriptions': return l10n.catSubscriptions;
    // New Batches
    case 'catPizza': return 'Pizza';
    case 'catBurger': return 'Burger';
    case 'catIcecream': return 'Ice Cream';
    case 'catMotorcycle': return 'Motorcycle';
    case 'catBike': return 'Bike';
    case 'catTaxi': return 'Taxi';
    case 'catShipping': return 'Shipping';
    case 'catPhotography': return 'Photography';
    case 'catArt': return 'Art';
    case 'catParty': return 'Party';
    case 'catHaircut': return 'Haircut';
    case 'catSwimming': return 'Swimming';
    case 'catCloud': return 'Cloud Services';
    case 'catPrinting': return 'Printing';
    default: return key; // Fallback to the key itself
  }
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
  // Housing
  LocalizedCategory(localizationKey: 'catRent', groupKey: 'catGroupHousing', iconName: 'home', colorHex: '#4285F4'),
  LocalizedCategory(localizationKey: 'catMortgage', groupKey: 'catGroupHousing', iconName: 'home_work', colorHex: '#1967D2'),
  LocalizedCategory(localizationKey: 'catPropertyTax', groupKey: 'catGroupHousing', iconName: 'receipt', colorHex: '#185ABC'),
  LocalizedCategory(localizationKey: 'catHomeInsurance', groupKey: 'catGroupHousing', iconName: 'security', colorHex: '#4285F4'),
  LocalizedCategory(localizationKey: 'catRepairsMaintenance', groupKey: 'catGroupHousing', iconName: 'build', colorHex: '#FBBC04'),
  
  // Utilities
  LocalizedCategory(localizationKey: 'catElectricity', groupKey: 'catGroupUtilities', iconName: 'electric_bolt', colorHex: '#FBBC04'),
  LocalizedCategory(localizationKey: 'catWater', groupKey: 'catGroupUtilities', iconName: 'water_drop', colorHex: '#4285F4'),
  LocalizedCategory(localizationKey: 'catGas', groupKey: 'catGroupUtilities', iconName: 'local_fire_department', colorHex: '#EA4335'),
  LocalizedCategory(localizationKey: 'catInternet', groupKey: 'catGroupUtilities', iconName: 'wifi', colorHex: '#34A853'),
  LocalizedCategory(localizationKey: 'catPhone', groupKey: 'catGroupUtilities', iconName: 'phone_iphone', colorHex: '#34A853'),
  
  // Food
  LocalizedCategory(localizationKey: 'catGroceries', groupKey: 'catGroupFood', iconName: 'shopping_cart', colorHex: '#34A853'),
  LocalizedCategory(localizationKey: 'catRestaurants', groupKey: 'catGroupFood', iconName: 'restaurant', colorHex: '#EA4335'),
  LocalizedCategory(localizationKey: 'catCoffeeShops', groupKey: 'catGroupFood', iconName: 'coffee', colorHex: '#795548'),
  LocalizedCategory(localizationKey: 'catAlcohol', groupKey: 'catGroupFood', iconName: 'wine_bar', colorHex: '#9C27B0'),
  LocalizedCategory(localizationKey: 'catDelivery', groupKey: 'catGroupFood', iconName: 'delivery_dining', colorHex: '#EA4335'),

  // Transportation
  LocalizedCategory(localizationKey: 'catFuel', groupKey: 'catGroupTransportation', iconName: 'local_gas_station', colorHex: '#EA4335'),
  LocalizedCategory(localizationKey: 'catPublicTransport', groupKey: 'catGroupTransportation', iconName: 'directions_bus', colorHex: '#4285F4'),
  LocalizedCategory(localizationKey: 'catCarMaintenance', groupKey: 'catGroupTransportation', iconName: 'car_repair', colorHex: '#5F6368'),
  LocalizedCategory(localizationKey: 'catParking', groupKey: 'catGroupTransportation', iconName: 'local_parking', colorHex: '#5F6368'),
  LocalizedCategory(localizationKey: 'catCarInsurance', groupKey: 'catGroupTransportation', iconName: 'security', colorHex: '#4285F4'),
  LocalizedCategory(localizationKey: 'catRideshare', groupKey: 'catGroupTransportation', iconName: 'local_taxi', colorHex: '#000000'),

  // Health
  LocalizedCategory(localizationKey: 'catMedical', groupKey: 'catGroupHealth', iconName: 'medical_services', colorHex: '#EA4335'),
  LocalizedCategory(localizationKey: 'catPharmacy', groupKey: 'catGroupHealth', iconName: 'medication', colorHex: '#EA4335'),
  LocalizedCategory(localizationKey: 'catDental', groupKey: 'catGroupHealth', iconName: 'masks', colorHex: '#4285F4'),
  LocalizedCategory(localizationKey: 'catFitness', groupKey: 'catGroupHealth', iconName: 'fitness_center', colorHex: '#34A853'),

  // Lifestyle
  LocalizedCategory(localizationKey: 'catClothing', groupKey: 'catGroupLifestyle', iconName: 'checkroom', colorHex: '#9C27B0'),
  LocalizedCategory(localizationKey: 'catPersonalCare', groupKey: 'catGroupLifestyle', iconName: 'face', colorHex: '#EC407A'),
  LocalizedCategory(localizationKey: 'catEntertainment', groupKey: 'catGroupLifestyle', iconName: 'movie', colorHex: '#8E24AA'),
  LocalizedCategory(localizationKey: 'catHobbies', groupKey: 'catGroupLifestyle', iconName: 'palette', colorHex: '#FBBC04'),
  LocalizedCategory(localizationKey: 'catTravel', groupKey: 'catGroupLifestyle', iconName: 'flight', colorHex: '#00ACC1'),
  
  // Finance
  LocalizedCategory(localizationKey: 'catSavings', groupKey: 'catGroupFinance', iconName: 'savings', colorHex: '#34A853'),
  LocalizedCategory(localizationKey: 'catInvestments', groupKey: 'catGroupFinance', iconName: 'trending_up', colorHex: '#34A853'),
  LocalizedCategory(localizationKey: 'catDebtRepayment', groupKey: 'catGroupFinance', iconName: 'credit_card_off', colorHex: '#EA4335'),
  LocalizedCategory(localizationKey: 'catTaxes', groupKey: 'catGroupFinance', iconName: 'account_balance', colorHex: '#5F6368'),
  LocalizedCategory(localizationKey: 'catFees', groupKey: 'catGroupFinance', iconName: 'remove_circle_outline', colorHex: '#EA4335'),

  // Family
  LocalizedCategory(localizationKey: 'catChildcare', groupKey: 'catGroupFamily', iconName: 'child_care', colorHex: '#FBBC04'),
  LocalizedCategory(localizationKey: 'catEducation', groupKey: 'catGroupFamily', iconName: 'school', colorHex: '#4285F4'),
  LocalizedCategory(localizationKey: 'catPets', groupKey: 'catGroupFamily', iconName: 'pets', colorHex: '#795548'),
  LocalizedCategory(localizationKey: 'catGifts', groupKey: 'catGroupFamily', iconName: 'card_giftcard', colorHex: '#E91E63'),

  // Tech & Services
  LocalizedCategory(localizationKey: 'catSoftware', groupKey: 'catGroupTech', iconName: 'code', colorHex: '#4285F4'),
  LocalizedCategory(localizationKey: 'catElectronics', groupKey: 'catGroupTech', iconName: 'devices', colorHex: '#5F6368'),
  LocalizedCategory(localizationKey: 'catSubscriptions', groupKey: 'catGroupTech', iconName: 'subscriptions', colorHex: '#EA4335'),
  LocalizedCategory(localizationKey: 'catCloud', groupKey: 'catGroupTech', iconName: 'cloud', colorHex: '#4285F4'),
  LocalizedCategory(localizationKey: 'catPrinting', groupKey: 'catGroupTech', iconName: 'print', colorHex: '#5F6368'),

  // New Food
  LocalizedCategory(localizationKey: 'catPizza', groupKey: 'catGroupFood', iconName: 'pizza', colorHex: '#FF9800'),
  LocalizedCategory(localizationKey: 'catBurger', groupKey: 'catGroupFood', iconName: 'burger', colorHex: '#FFA000'),
  LocalizedCategory(localizationKey: 'catIcecream', groupKey: 'catGroupFood', iconName: 'icecream', colorHex: '#F06292'),

  // New Transport
  LocalizedCategory(localizationKey: 'catMotorcycle', groupKey: 'catGroupTransportation', iconName: 'motorcycle', colorHex: '#5F6368'),
  LocalizedCategory(localizationKey: 'catBike', groupKey: 'catGroupTransportation', iconName: 'bike', colorHex: '#34A853'),
  LocalizedCategory(localizationKey: 'catTaxi', groupKey: 'catGroupTransportation', iconName: 'taxi', colorHex: '#FFC107'),
  LocalizedCategory(localizationKey: 'catShipping', groupKey: 'catGroupTransportation', iconName: 'shipping', colorHex: '#795548'),

  // New Lifestyle
  LocalizedCategory(localizationKey: 'catPhotography', groupKey: 'catGroupLifestyle', iconName: 'camera', colorHex: '#607D8B'),
  LocalizedCategory(localizationKey: 'catArt', groupKey: 'catGroupLifestyle', iconName: 'brush', colorHex: '#E91E63'),
  LocalizedCategory(localizationKey: 'catParty', groupKey: 'catGroupLifestyle', iconName: 'party', colorHex: '#9C27B0'),
  LocalizedCategory(localizationKey: 'catHaircut', groupKey: 'catGroupLifestyle', iconName: 'haircut', colorHex: '#795548'),
  LocalizedCategory(localizationKey: 'catSwimming', groupKey: 'catGroupLifestyle', iconName: 'pool', colorHex: '#03A9F4'),
];

// ============================================================================
// CATEGORY UTILITIES (NON-BREAKING, ADDITIVE)
// ============================================================================

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

// ============================================================================
// ICON MAPPER (SINGLE SOURCE OF TRUTH)
// ============================================================================

class CategoryIconMapper {
  static const Map<String, IconData> _materialIcons = {
    // Housing
    'home': Icons.home_outlined,
    'home_work': Icons.home_work_outlined,
    'receipt': Icons.receipt_long_outlined,
    'security': Icons.verified_user_outlined,
    'build': Icons.build_outlined,

    // Utilities
    'electric_bolt': Icons.electric_bolt_outlined,
    'water_drop': Icons.water_drop_outlined,
    'local_fire_department': Icons.local_fire_department_outlined,
    'wifi': Icons.wifi_outlined,
    'phone_iphone': Icons.phone_iphone_outlined,

    // Food
    'shopping_cart': Icons.local_grocery_store_outlined,
    'restaurant': Icons.restaurant_outlined,
    'coffee': Icons.coffee_outlined,
    'wine_bar': Icons.wine_bar_outlined,
    'delivery_dining': Icons.delivery_dining_outlined,

    // Transport
    'local_gas_station': Icons.local_gas_station_outlined,
    'directions_bus': Icons.directions_bus_outlined,
    'car_repair': Icons.car_repair_outlined,
    'local_parking': Icons.local_parking_outlined,
    'local_taxi': Icons.local_taxi_outlined,

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

    // Finance
    'savings': Icons.savings_outlined,
    'trending_up': Icons.trending_up_outlined,
    'credit_card_off': Icons.credit_card_off_outlined,
    'account_balance': Icons.account_balance_outlined,
    'remove_circle_outline': Icons.remove_circle_outline,

    // Family
    'child_care': Icons.child_care_outlined,
    'school': Icons.school_outlined,
    'pets': Icons.pets_outlined,
    'card_giftcard': Icons.card_giftcard_outlined,

    // Tech
    'code': Icons.code_outlined,
    'devices': Icons.devices_outlined,
    'subscriptions': Icons.subscriptions_outlined,

    'cloud': Icons.cloud_outlined,
    'print': Icons.print,

    // New Food
    'pizza': Icons.local_pizza_outlined,
    'burger': Icons.lunch_dining_outlined,
    'icecream': Icons.icecream_outlined,

    // New Transport
    'motorcycle': Icons.two_wheeler_outlined,
    'bike': Icons.pedal_bike_outlined,
    'taxi': Icons.local_taxi_outlined,
    'shipping': Icons.local_shipping_outlined,

    // New Lifestyle
    'camera': Icons.camera_alt_outlined,
    'brush': Icons.brush_outlined,
    'party': Icons.celebration_outlined,
    'haircut': Icons.content_cut_outlined,
    'pool': Icons.pool_outlined,
  };

  static IconData resolve(String name) {
    return _materialIcons[name] ?? Icons.category_outlined;
  }
}

// ============================================================================
// COLOR HELPERS (PURE FUNCTIONS)
// ============================================================================

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
