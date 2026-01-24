import 'dart:convert';
import 'package:drift/drift.dart';

// ============================================================
// USERS TABLE
// ============================================================

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  TextColumn get languagePreference => text().withDefault(const Constant('en'))();
  TextColumn get avatarUrl => text().nullable()();
  
  // Subscription fields
  TextColumn get subscriptionTier => text().withDefault(const Constant('free'))();
  TextColumn get subscriptionStatus => text().withDefault(const Constant('active'))();
  DateTimeColumn get trialStartedAt => dateTime().nullable()();
  DateTimeColumn get trialExpiresAt => dateTime().nullable()();
  DateTimeColumn get subscriptionExpiresAt => dateTime().nullable()();
  DateTimeColumn get lastPaymentDate => dateTime().nullable()();
  TextColumn get paymentProvider => text().nullable()(); // 'app_store', 'play_store', 'stripe'
  TextColumn get paymentProviderId => text().nullable()();
  
  // OCR usage tracking
  IntColumn get ocrUsageCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get ocrUsageResetAt => dateTime().nullable()();
  
  // Experience Mode (synced with Supabase profiles.experience_mode)
  TextColumn get experienceMode => text().withDefault(const Constant('beginner'))(); // 'beginner' or 'expert'
  
  // Other fields
  TextColumn get role => text().withDefault(const Constant('user'))();
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()(); // JSONB
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get baseRevision => integer().nullable()(); // For conflict detection
  TextColumn get operationId => text().nullable()(); // For idempotency
  TextColumn get lastModifiedByDeviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  // ADDED: For Sync to work
  TextColumn get syncState => text().withDefault(const Constant('clean'))(); // clean, dirty, conflict

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// BUDGETS TABLE
// ============================================================

@TableIndex(name: 'idx_budgets_owner', columns: {#ownerId})
@TableIndex(name: 'idx_budgets_dates', columns: {#startDate, #endDate})
@TableIndex(name: 'idx_budgets_type', columns: {#type})
@TableIndex(name: 'idx_budgets_owner_dates', columns: {#ownerId, #startDate, #endDate})
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()(); // V9 has this
  TextColumn get type => text()(); // monthly, weekly, annual, custom, event, savings, project
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  IntColumn get totalLimit => integer().nullable()(); // in cents
  BoolColumn get isShared => boolean().withDefault(const Constant(false))();
  BoolColumn get isTemplate => boolean().withDefault(const Constant(false))(); // V9 has this
  TextColumn get status => text().withDefault(const Constant('active'))(); // active, completed, archived, template
  TextColumn get iconName => text().nullable()(); // V9 has this
  TextColumn get colorHex => text().nullable()(); // V9 has this
  TextColumn get notes => text().nullable()();
  TextColumn get tags => text().nullable()(); // JSON array of tags
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()(); // JSONB
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get baseRevision => integer().nullable()(); // For conflict detection
  TextColumn get operationId => text().nullable()(); // For idempotency
  TextColumn get lastModifiedByDeviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get globalSeq => integer().nullable()(); // Sync ordering
  TextColumn get syncState => text().withDefault(const Constant('clean'))(); // clean, dirty, conflict

  @override
  Set<Column> get primaryKey => {id};
}


// ============================================================
// SEMI-BUDGETS (CATEGORIES) TABLE
// ============================================================

@TableIndex(name: 'idx_semi_budgets_budget', columns: {#budgetId})
class SemiBudgets extends Table {
  TextColumn get id => text()();
  TextColumn get budgetId => text().references(Budgets, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get limitAmount => integer()(); // in cents
  IntColumn get priority => integer().withDefault(const Constant(3))(); // 1-5
  TextColumn get iconName => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()(); // JSONB
  
  // Category hierarchy support
  TextColumn get parentCategoryId => text().nullable().references(SemiBudgets, #id, onDelete: KeyAction.cascade)()
; // For subcategories
  BoolColumn get isSubcategory => boolean().withDefault(const Constant(false))(); // True if this is a subcategory
  RealColumn get suggestedPercent => real().nullable()(); // Suggested allocation % (e.g., 0.25 = 25%)
  IntColumn get displayOrder => integer().withDefault(const Constant(0))(); // For sorting
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get baseRevision => integer().nullable()(); // For conflict detection
  TextColumn get operationId => text().nullable()(); // For idempotency
  TextColumn get lastModifiedByDeviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncState => text().withDefault(const Constant('clean'))(); // clean, dirty, conflict

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// ACCOUNTS TABLE
// ============================================================

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get name => text()();
  TextColumn get type => text()(); // checking, savings, credit, cash
  IntColumn get balance => integer()(); // in cents
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  TextColumn get iconName => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  TextColumn get institutionName => text().nullable()();
  TextColumn get accountNumberLast4 => text().nullable()();
  
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()(); // JSONB
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get baseRevision => integer().nullable()(); // For conflict detection
  TextColumn get operationId => text().nullable()(); // For idempotency
  TextColumn get lastModifiedByDeviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncState => text().withDefault(const Constant('clean'))(); // For sync tracking

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// EXPENSES TABLE
// ============================================================

@TableIndex(name: 'idx_expenses_date', columns: {#date})
@TableIndex(name: 'idx_expenses_budget', columns: {#budgetId})
@TableIndex(name: 'idx_expenses_semi_budget', columns: {#semiBudgetId})
@TableIndex(name: 'idx_expenses_category', columns: {#categoryId})
@TableIndex(name: 'idx_expenses_entered_by', columns: {#enteredBy})
@TableIndex(name: 'idx_expenses_user_date', columns: {#enteredBy, #date})
@TableIndex(name: 'idx_expenses_merchant', columns: {#merchantName})
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get budgetId => text().references(Budgets, #id, onDelete: KeyAction.cascade)();
  TextColumn get semiBudgetId => text().nullable().references(SemiBudgets, #id, onDelete: KeyAction.setNull)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get enteredBy => text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  IntColumn get amount => integer()(); // in cents
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  DateTimeColumn get date => dateTime()();
  
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  
  // Merchant / Payee
  TextColumn get merchantName => text().nullable()();

  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  TextColumn get receiptUrl => text().nullable()();
  TextColumn get barcodeValue => text().nullable()();
  TextColumn get ocrText => text().nullable()();

  TextColumn get attachments => text().nullable()(); // JSON list of URLs
  TextColumn get notes => text().nullable()();
  TextColumn get locationName => text().nullable()(); // JSON lat/long - RENAMED from 'location' to match server
  TextColumn get tags => text().nullable()(); // JSON list of strings
  
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurringId => text().nullable()();
  
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()(); // JSONB
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get baseRevision => integer().nullable()(); // For conflict detection
  TextColumn get operationId => text().nullable()(); // For idempotency
  TextColumn get lastModifiedByDeviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get globalSeq => integer().nullable()(); // Sync ordering
  TextColumn get syncState => text().withDefault(const Constant('clean'))(); // clean, dirty, conflict

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// BUDGET MEMBERS (Family Sharing)
// ============================================================

class BudgetMembers extends Table {
  TextColumn get id => text()();
  TextColumn get budgetId => text().references(Budgets, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text().nullable().references(Users, #id)();
  TextColumn get memberEmail => text()();
  TextColumn get memberName => text().nullable()();
  TextColumn get role => text()(); // owner, editor, viewer
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, active, declined
  TextColumn get invitedBy => text().nullable().references(Users, #id)();
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()(); // JSONB
  DateTimeColumn get invitedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get acceptedAt => dateTime().nullable()();
  TextColumn get lastModifiedByDeviceId => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get syncState => text().withDefault(const Constant('clean'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// ACTIVITY LOG TABLE
// ============================================================

class ActivityLogs extends Table {
  TextColumn get id => text()();
  TextColumn get budgetId => text().references(Budgets, #id)();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get details => text().map(const MetadataConverter()).nullable()(); // JSONB
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// SYNC QUEUE TABLE
// ============================================================

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncTableName => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // insert, update, delete
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

// ============================================================
// RECURRING EXPENSES TABLE
// ============================================================

class RecurringExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get title => text()();
  IntColumn get amount => integer()(); // in cents
  TextColumn get frequency => text()(); // daily, weekly, monthly, yearly
  IntColumn get dayOfMonth => integer().nullable()();
  IntColumn get dayOfWeek => integer().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get paymentMethod => text().withDefault(const Constant('card'))();
  DateTimeColumn get nextDueDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()(); // JSONB
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get baseRevision => integer().nullable()(); // For conflict detection
  TextColumn get operationId => text().nullable()(); // For idempotency
  TextColumn get lastModifiedByDeviceId => text().nullable()();
  TextColumn get syncState => text().withDefault(const Constant('clean'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// SUBSCRIPTIONS TABLE
// ============================================================

class Subscriptions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get stripeCustomerId => text().nullable()();
  TextColumn get priceId => text()();
  TextColumn get status => text()(); // active, canceled, past_due, trialing
  TextColumn get tier => text()(); // free, pro, pro_plus
  DateTimeColumn get currentPeriodStart => dateTime().nullable()();
  DateTimeColumn get currentPeriodEnd => dateTime().nullable()();
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()(); // JSONB
  BoolColumn get cancelAtPeriodEnd => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get lastModifiedByDeviceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// SAVINGS GOALS TABLE
// ============================================================

class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get linkedAccountId => text().nullable().references(Accounts, #id)(); // V9 has this
  TextColumn get title => text()();
  IntColumn get currentAmount => integer().withDefault(const Constant(0))(); // in cents
  IntColumn get targetAmount => integer()(); // in cents
  TextColumn get currency => text().withDefault(const Constant('EUR'))(); // V9 has this
  TextColumn get iconName => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()(); // JSONB
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get baseRevision => integer().nullable()(); // For conflict detection
  TextColumn get operationId => text().nullable()(); // For idempotency
  TextColumn get lastModifiedByDeviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncState => text().withDefault(const Constant('clean'))();

  @override
  Set<Column> get primaryKey => {id};
}



// ============================================================
// REFERENCE CATEGORIES (Master List)
// ============================================================

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text().nullable().references(Users, #id)(); // null for system categories
  TextColumn get name => text()();
  TextColumn get nameTranslations => text().map(const MetadataConverter()).nullable()(); // {"en": "Food", "bn": "খাবার", ...}
  TextColumn get iconName => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get emoji => text().nullable()(); // V9 has this
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  TextColumn get type => text().withDefault(const Constant('expense'))(); // expense, income
  BoolColumn get isSystem => boolean().withDefault(const Constant(true))(); // true if seeded, false if user customized
  TextColumn get tags => text().nullable()(); // JSON array of tags
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get baseRevision => integer().nullable()(); // For conflict detection
  TextColumn get operationId => text().nullable()(); // For idempotency
  TextColumn get lastModifiedByDeviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// LOCATIONS & GEO TABLE
// ============================================================

class Locations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real().nullable()();
  RealColumn get altitude => real().nullable()();
  RealColumn get speed => real().nullable()();
  RealColumn get heading => real().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get context => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('gps'))(); // gps, manual
  TextColumn get deviceInfo => text().map(const MetadataConverter()).withDefault(const Constant('{}'))(); // JSONB
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class GeocodingCache extends Table {
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get format => text()(); // e.g: json, geojson
  TextColumn get languageCode => text().withDefault(const Constant('en'))();
  TextColumn get address => text()();
  TextColumn get fullAddress => text().nullable()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {latitude, longitude, format, languageCode};
}

class ExpenseLocations extends Table {
  TextColumn get expenseId => text().references(Expenses, #id)();
  TextColumn get locationId => text().references(Locations, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {expenseId, locationId};
}

class RecurringExpenseLocations extends Table {
  TextColumn get recurringExpenseId => text().references(RecurringExpenses, #id)();
  TextColumn get locationId => text().references(Locations, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {recurringExpenseId, locationId};
}

class LocationAnalytics extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable().references(Users, #id)();
  TextColumn get locationId => text().nullable().references(Locations, #id)();
  RealColumn get accuracy => real().nullable()();
  RealColumn get speed => real().nullable()();
  TextColumn get batteryImpact => text().nullable()();
  TextColumn get networkType => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Geofences extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get radius => real()(); // in meters
  TextColumn get context => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class GeofenceEvents extends Table {
  TextColumn get id => text()();
  TextColumn get geofenceId => text().references(Geofences, #id)();
  TextColumn get eventType => text()(); // enter, exit, dwell
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get durationSeconds => integer().nullable()(); // duration interval
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// CONFLICTS TABLE (for sync conflict resolution)
// ============================================================

/// Stores sync conflicts for user resolution
/// Created when local and remote versions differ
@TableIndex(name: 'idx_conflicts_status', columns: {#status})
@TableIndex(name: 'idx_conflicts_entity', columns: {#entityType, #entityId})
class Conflicts extends Table {
  /// Unique conflict ID
  TextColumn get id => text()();
  
  /// Type of entity: expense, budget, account, category, recurring
  TextColumn get entityType => text()();
  
  /// ID of the conflicting entity
  TextColumn get entityId => text()();
  
  /// When the conflict was detected
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Status: open, resolved
  TextColumn get status => text().withDefault(const Constant('open'))();
  
  /// Local version as JSON
  TextColumn get localJson => text()();
  
  /// Remote version as JSON
  TextColumn get remoteJson => text()();
  
  /// Precomputed diff as JSON (optional)
  TextColumn get diffJson => text().nullable()();
  
  /// Resolution type: pending, keepLocal, keepRemote, merge, duplicate
  TextColumn get resolutionType => text().withDefault(const Constant('pending'))();
  
  /// When the conflict was resolved
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  
  /// Device ID that detected the conflict
  TextColumn get detectedByDeviceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// AUDIT EVENTS TABLE (for tracking important operations)
// ============================================================

/// Tracks important operations for audit/history
@TableIndex(name: 'idx_audit_events_type', columns: {#eventType})
@TableIndex(name: 'idx_audit_events_date', columns: {#createdAt})
class AuditEvents extends Table {
  TextColumn get id => text()();
  
  /// Event type: currency_migration, restore, conflict_resolve, backup, delete
  TextColumn get eventType => text()();
  
  /// When the event occurred
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Device that performed the action
  TextColumn get actorDeviceId => text().nullable()();
  
  /// Brief summary
  TextColumn get summary => text()();
  
  /// Detailed JSON (before/after, counts, etc.)
  TextColumn get detailsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Custom Converter for JSONB
class MetadataConverter extends TypeConverter<Map<String, dynamic>, String> {
  const MetadataConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    try {
      return json.decode(fromDb) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  @override
  String toSql(Map<String, dynamic> value) {
    try {
      return json.encode(value);
    } catch (e) {
      return '{}';
    }
  }
}

// ============================================================
// OUTBOX EVENTS TABLE (Offline Sync Queue)
// ============================================================

/// Stores local changes when offline for later synchronization
@TableIndex(name: 'idx_outbox_status', columns: {#status})
class OutboxEvents extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  IntColumn get baseRevision => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get processedAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  
  // Phase 1 enhancements
  IntColumn get permissionEpochAtEdit => integer().nullable()();
  DateTimeColumn get lastRetryAt => dateTime().nullable()();
  IntColumn get maxRetries => integer().withDefault(const Constant(5))();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// CATEGORY LEARNING TABLE (ML - User Pattern Learning)
// ============================================================

/// Stores user's category selection patterns for personalized predictions
@TableIndex(name: 'idx_category_learning_pattern', columns: {#merchantPattern})
class CategoryLearning extends Table {
  TextColumn get id => text()();
  TextColumn get merchantPattern => text()(); // Normalized merchant name/keyword
  TextColumn get categoryName => text()(); // User's preferred category
  IntColumn get confidenceBoost => integer().withDefault(const Constant(10))(); // +confidence
  IntColumn get usageCount => integer().withDefault(const Constant(1))(); // Times used
  DateTimeColumn get lastUsedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// SYNC STATE TABLES (Atomic Persistence)
// ============================================================

/// Sync Recovery State Table - Single row table for current sync state
@DataClassName('SyncRecoveryStateData')
class SyncRecoveryState extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get currentState => text().withLength(min: 1, max: 50)();
  DateTimeColumn get syncStartedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncCompletedAt => dateTime().nullable()();
  TextColumn get syncReason => text().withLength(min: 1, max: 50).nullable()();
  TextColumn get pendingOperations => text().nullable()();
  TextColumn get lastError => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Sync Operations Log - Idempotency tracking
@DataClassName('SyncOperationLog')
class SyncOperationsLog extends Table {
  TextColumn get operationId => text().withLength(min: 36, max: 36)();
  TextColumn get entityType => text().withLength(min: 1, max: 50)();
  TextColumn get entityId => text().withLength(min: 1, max: 255)();
  TextColumn get action => text().withLength(min: 1, max: 20)();
  TextColumn get status => text().withLength(min: 1, max: 20)();
  TextColumn get deviceId => text().withLength(min: 1, max: 255).nullable()();
  DateTimeColumn get timestamp => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get metadata => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {operationId};
}

/// Sync State Transitions - Audit trail
@DataClassName('SyncStateTransition')
class SyncStateTransitions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fromState => text().withLength(min: 1, max: 50)();
  TextColumn get toState => text().withLength(min: 1, max: 50)();
  TextColumn get reason => text().withLength(min: 1, max: 255)();
  TextColumn get sessionId => text().withLength(min: 1, max: 36).nullable()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get context => text().nullable()();
}

