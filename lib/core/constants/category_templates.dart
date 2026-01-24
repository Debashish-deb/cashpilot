/// Category Template System
/// Defines all category groups with subcategories and smart allocation
library;

import 'package:flutter/material.dart';

/// Main category groups with vibrant colors
enum CategoryGroup {
  housing('Housing & Rent', Icons.home, 0.30, Color(0xFF5C6BC0)),  // Indigo
  food('Food & Dining', Icons.restaurant, 0.12, Color(0xFFFF7043)),  // Deep Orange
  transport('Transport', Icons.directions_car, 0.10, Color(0xFF42A5F5)),  // Blue
  bills('Bills & Utilities', Icons.receipt_long, 0.08, Color(0xFF66BB6A)),  // Green
  subscriptions('Subscriptions', Icons.subscriptions, 0.04, Color(0xFFAB47BC)),  // Purple
  debt('Debt & Loans', Icons.account_balance, 0.05, Color(0xFFEF5350)),  // Red
  healthcare('Healthcare', Icons.local_hospital, 0.05, Color(0xFFEC407A)),  // Pink
  shopping('Shopping', Icons.shopping_bag, 0.05, Color(0xFFFFCA28)),  // Amber
  entertainment('Entertainment', Icons.movie, 0.04, Color(0xFF26C6DA)),  // Cyan
  personal('Personal Care', Icons.spa, 0.02, Color(0xFFFF8A65)),  // Light Orange
  travel('Travel & Vacation', Icons.flight, 0.03, Color(0xFF29B6F6)),  // Light Blue
  pets('Pets', Icons.pets, 0.02, Color(0xFF8D6E63)),  // Brown
  gifts('Gifts & Donations', Icons.card_giftcard, 0.02, Color(0xFFD4E157)),  // Lime
  education('Education', Icons.school, 0.03, Color(0xFF7E57C2)),  // Deep Purple
  family('Family & Kids', Icons.family_restroom, 0.03, Color(0xFF26A69A)),  // Teal
  savings('Savings & Investments', Icons.savings, 0.10, Color(0xFF4CAF50)),  // Green
  other('Other', Icons.more_horiz, 0.02, Color(0xFF78909C));  // Blue Grey

  final String name;
  final IconData icon;
  final double suggestedPercent;
  final Color color;
  
  const CategoryGroup(this.name, this.icon, this.suggestedPercent, this.color);
}

/// Subcategory template
class SubcategoryTemplate {
  final String name;
  final IconData icon;
  final double suggestedPercent; // Of parent category
  
  const SubcategoryTemplate(
    this.name,
    this.icon,
    this.suggestedPercent,
  );
}

/// Category templates with subcategories
class CategoryTemplates {
  static const Map<CategoryGroup, List<SubcategoryTemplate>> templates = {
    CategoryGroup.housing: [
      SubcategoryTemplate('Rent/Mortgage', Icons.home_work, 0.85),
      SubcategoryTemplate('Property Tax', Icons.gavel, 0.05),
      SubcategoryTemplate('Home Insurance', Icons.security, 0.05),
      SubcategoryTemplate('Maintenance & Repairs', Icons.build, 0.05),
    ],
    
    CategoryGroup.food: [
      SubcategoryTemplate('Groceries', Icons.shopping_cart, 0.60),
      SubcategoryTemplate('Restaurants', Icons.restaurant_menu, 0.25),
      SubcategoryTemplate('Coffee & Cafes', Icons.local_cafe, 0.10),
      SubcategoryTemplate('Delivery & Takeout', Icons.delivery_dining, 0.05),
    ],
    
    CategoryGroup.shopping: [
      SubcategoryTemplate('Clothing', Icons.checkroom, 0.40),
      SubcategoryTemplate('Electronics', Icons.devices, 0.30),
      SubcategoryTemplate('Home & Garden', Icons.home, 0.20),
      SubcategoryTemplate('Books & Media', Icons.menu_book, 0.10),
    ],
    
    CategoryGroup.entertainment: [
      SubcategoryTemplate('Movies & Shows', Icons.movie_filter, 0.30),
      SubcategoryTemplate('Streaming Services', Icons.subscriptions, 0.25),
      SubcategoryTemplate('Games', Icons.sports_esports, 0.25),
      SubcategoryTemplate('Events & Concerts', Icons.event, 0.20),
    ],
    
    CategoryGroup.transport: [
      SubcategoryTemplate('Gas & Fuel', Icons.local_gas_station, 0.60),
      SubcategoryTemplate('Public Transit', Icons.directions_bus, 0.25),
      SubcategoryTemplate('Parking', Icons.local_parking, 0.15),
    ],
    
    CategoryGroup.bills: [
      SubcategoryTemplate('Electricity', Icons.bolt, 0.30),
      SubcategoryTemplate('Water', Icons.water_drop, 0.15),
      SubcategoryTemplate('Internet', Icons.wifi, 0.25),
      SubcategoryTemplate('Phone', Icons.phone_android, 0.20),
      SubcategoryTemplate('Insurance', Icons.security, 0.10),
    ],
    
    CategoryGroup.subscriptions: [
      SubcategoryTemplate('Streaming (Netflix, etc.)', Icons.play_circle, 0.40),
      SubcategoryTemplate('Software & Apps', Icons.computer, 0.25),
      SubcategoryTemplate('News & Magazines', Icons.article, 0.15),
      SubcategoryTemplate('Fitness & Wellness', Icons.fitness_center, 0.20),
    ],
    
    CategoryGroup.debt: [
      SubcategoryTemplate('Credit Cards', Icons.credit_card, 0.40),
      SubcategoryTemplate('Student Loans', Icons.school, 0.30),
      SubcategoryTemplate('Car Payments', Icons.directions_car, 0.20),
      SubcategoryTemplate('Personal Loans', Icons.account_balance_wallet, 0.10),
    ],
    
    CategoryGroup.healthcare: [
      SubcategoryTemplate('Prescriptions', Icons.medication, 0.40),
      SubcategoryTemplate('Doctor Visits', Icons.medical_services, 0.35),
      SubcategoryTemplate('Dental', Icons.health_and_safety, 0.15),
      SubcategoryTemplate('Vision', Icons.visibility, 0.10),
    ],
    
    CategoryGroup.personal: [
      SubcategoryTemplate('Haircuts', Icons.content_cut, 0.40),
      SubcategoryTemplate('Beauty Products', Icons.face, 0.40),
      SubcategoryTemplate('Spa & Wellness', Icons.spa, 0.20),
    ],
    
    CategoryGroup.education: [
      SubcategoryTemplate('Books & Supplies', Icons.auto_stories, 0.40),
      SubcategoryTemplate('Courses', Icons.laptop_mac, 0.40),
      SubcategoryTemplate('Tuition', Icons.school, 0.20),
    ],
    
    CategoryGroup.travel: [
      SubcategoryTemplate('Flights', Icons.flight, 0.40),
      SubcategoryTemplate('Hotels', Icons.hotel, 0.35),
      SubcategoryTemplate('Activities & Tours', Icons.explore, 0.15),
      SubcategoryTemplate('Transportation', Icons.directions, 0.10),
    ],
    
    CategoryGroup.pets: [
      SubcategoryTemplate('Pet Food', Icons.food_bank, 0.50),
      SubcategoryTemplate('Veterinary', Icons.medical_services, 0.30),
      SubcategoryTemplate('Grooming', Icons.spa, 0.10),
      SubcategoryTemplate('Supplies & Toys', Icons.shopping_bag, 0.10),
    ],
    
    CategoryGroup.gifts: [
      SubcategoryTemplate('Birthday Gifts', Icons.cake, 0.40),
      SubcategoryTemplate('Holiday Gifts', Icons.celebration, 0.30),
      SubcategoryTemplate('Charitable Donations', Icons.volunteer_activism, 0.20),
      SubcategoryTemplate('Special Occasions', Icons.card_giftcard, 0.10),
    ],
    
    CategoryGroup.family: [
      SubcategoryTemplate('Childcare', Icons.child_care, 0.50),
      SubcategoryTemplate('Activities', Icons.sports_soccer, 0.30),
      SubcategoryTemplate('Toys & Games', Icons.toys, 0.20),
    ],
    
    CategoryGroup.savings: [
      SubcategoryTemplate('Emergency Fund', Icons.emergency, 0.40),
      SubcategoryTemplate('Investments', Icons.trending_up, 0.40),
      SubcategoryTemplate('Goals', Icons.flag, 0.20),
    ],
    
    CategoryGroup.other: [
      SubcategoryTemplate('Miscellaneous', Icons.category, 1.0),
    ],
  };
  
  /// Get subcategories for a category group
  static List<SubcategoryTemplate> getSubcategories(CategoryGroup group) {
    return templates[group] ?? [];
  }
  
  /// Calculate suggested limit for category
  static int calculateCategoryLimit(int totalBudget, CategoryGroup group) {
    return (totalBudget * group.suggestedPercent).round();
  }
  
  /// Calculate suggested limit for subcategory
  static int calculateSubcategoryLimit(int categoryLimit, SubcategoryTemplate subcategory) {
    return (categoryLimit * subcategory.suggestedPercent).round();
  }
  
  /// Get all categories with limits
  static Map<CategoryGroup, int> getSmartAllocation(int totalBudget) {
    return Map.fromEntries(
      CategoryGroup.values.map((group) => MapEntry(
        group,
        calculateCategoryLimit(totalBudget, group),
      )),
    );
  }
}
