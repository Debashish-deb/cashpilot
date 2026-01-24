/// Family Domain - Business Rules and Invariants
/// Enforces family sharing limits and permissions
library;

import '../../../core/errors/app_error.dart';
import '../subscription/subscription_domain.dart';

/// Family member role
enum FamilyRole {
  owner,
  admin,
  member;
  
  static FamilyRole fromString(String role) {
    return switch (role.toLowerCase()) {
      'owner' => FamilyRole.owner,
      'admin' => FamilyRole.admin,
      'member' => FamilyRole.member,
      _ => FamilyRole.member,
    };
  }
}

/// Family domain logic
class FamilyDomain {
  /// Validate adding family member
  static void validateAddMember({
    required int currentMemberCount,
    required SubscriptionTier tier,
  }) {
    final limits = TierLimits.forTier(tier);
    
    if (limits.maxFamilyMembers == 0) {
      throw AppError.subscriptionRequired(
        message: 'Family sharing requires a Pro subscription',
      );
    }
    
    if (currentMemberCount >= limits.maxFamilyMembers) {
      throw AppError(
        code: AppErrorCode.subscriptionLimitReached,
        message: tier == SubscriptionTier.pro
            ? 'Pro plan allows up to 3 family members. Upgrade to Pro Plus for unlimited.'
            : 'You\'ve reached the limit of ${limits.maxFamilyMembers} family members.',
        severity: AppErrorSeverity.actionRequired,
      );
    }
  }
  
  /// Validate member email
  static void validateEmail(String email) {
    if (email.trim().isEmpty) {
      throw AppError.validation(
        message: 'Email cannot be empty',
      );
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw AppError.validation(
        message: 'Invalid email format',
      );
    }
  }
  
  /// Validate member role
  static void validateRole(FamilyRole role) {
    // Owner role can only be assigned internally
    if (role == FamilyRole.owner) {
      throw AppError.validation(
        message: 'Cannot directly assign owner role',
      );
    }
  }
  
  /// Check if user has permission for action
  static bool hasPermission({
    required FamilyRole userRole,
    required String action,
  }) {
    return switch (action.toLowerCase()) {
      // Owner-only actions
      'delete_budget' || 'remove_member' || 'change_tier' => 
        userRole == FamilyRole.owner,
      
      // Admin actions
      'create_budget' || 'edit_budget' || 'invite_member' =>
        userRole == FamilyRole.owner || userRole == FamilyRole.admin,
      
      // Member actions
      'create_expense' || 'edit_expense' || 'view_budget' =>
        true, // All roles can do this
      
      _ => false,
    };
  }
  
  /// Require permission for action
  static void requirePermission({
    required FamilyRole userRole,
    required String action,
  }) {
    if (!hasPermission(userRole: userRole, action: action)) {
      throw AppError(
        code: AppErrorCode.permissionDenied,
        message: 'You don\'t have permission to $action',
        severity: AppErrorSeverity.actionRequired,
      );
    }
  }
  
  /// Validate member name
  static void validateName(String? name) {
    if (name != null && name.length > 100) {
      throw AppError.validation(
        message: 'Name cannot exceed 100 characters',
      );
    }
  }
  
  /// Check if can remove member
  static void validateRemoveMember({
    required int currentMemberCount,
    required FamilyRole memberRole,
  }) {
    // Cannot remove owner
    if (memberRole == FamilyRole.owner) {
      throw AppError.validation(
        message: 'Cannot remove budget owner',
      );
    }
    
    // Need at least one member (the owner)
    if (currentMemberCount <= 1) {
      throw AppError.validation(
        message: 'Cannot remove the last member',
      );
    }
  }
}
