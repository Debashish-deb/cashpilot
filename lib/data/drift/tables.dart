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
  
  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

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
  
  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

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
  TextColumn get parentCategoryId => text().nullable().references(SemiBudgets, #id, onDelete: KeyAction.cascade)(); // For subcategories
  BoolColumn get isSubcategory => boolean().withDefault(const Constant(false))(); // True if this is a subcategory
  RealColumn get suggestedPercent => real().nullable()(); // Suggested allocation % (e.g., 0.25 = 25%)
  IntColumn get displayOrder => integer().withDefault(const Constant(0))(); // For sorting
  
  // Link to master Categories table
  TextColumn get masterCategoryId => text().nullable().references(Categories, #id)(); // Links to seeded master categories
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get baseRevision => integer().nullable()(); // For conflict detection
  TextColumn get operationId => text().nullable()(); // For idempotency
  TextColumn get lastModifiedByDeviceId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncState => text().withDefault(const Constant('clean'))(); // clean, dirty, conflict
  
  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

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

  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

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
  TextColumn get categoryId => text().nullable().references(Categories, #id)(); // Stability fix: nullable
  TextColumn get subCategoryId => text().nullable().references(SubCategories, #id)();
  TextColumn get semiBudgetId => text().nullable().references(SemiBudgets, #id, onDelete: KeyAction.setNull)();
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

  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

  // AI & INTELLIGENCE METADATA (V11)
  TextColumn get subCategoryRaw => text().nullable()(); // User entered raw text if no subCategory matched
  TextColumn get semanticTokens => text().nullable()(); // JSON List<String>
  
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  TextColumn get source => text().withDefault(const Constant('manual'))(); // ocr, manual, api, bank_sync
  BoolColumn get isAiAssigned => boolean().withDefault(const Constant(false))();
  BoolColumn get isVerified => boolean().withDefault(const Constant(true))(); // User confirmed category/amount

  // BEHAVIORAL CONTEXT (Phase B)
  TextColumn get mood => text().nullable()(); // stressed, happy, neutral, etc.
  TextColumn get socialContext => text().nullable()(); // alone, friends, family, work

  // BANK SYNC DEDUPLICATION (Nordigen)
  TextColumn get bankTransactionId => text().nullable().unique()();

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
  
  // Standardization
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  TextColumn get lastModifiedByDeviceId => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get syncState => text().withDefault(const Constant('clean'))();

  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

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
// AUDIT LOGS (Compliance & Enterprise Audit)
// ============================================================

class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()(); // expense, budget, account, user
  TextColumn get entityId => text()();
  TextColumn get action => text()(); // create, update, delete
  TextColumn get userId => text().references(Users, #id)();
  
  TextColumn get oldValue => text().nullable()(); // JSON string
  TextColumn get newValue => text().nullable()(); // JSON string
  
  /// Correlation ID (UUID) linked to a specific UI operation or Sync session
  TextColumn get correlationId => text().nullable()();
  TextColumn get deviceId => text().nullable()();
  
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  TextColumn get syncState => text().withDefault(const Constant('clean'))();
  IntColumn get revision => integer().withDefault(const Constant(0))();

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

  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

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

  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

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
  TextColumn get type => text().withDefault(const Constant('expense'))(); // expense, income
  BoolColumn get isSystem => boolean().withDefault(const Constant(true))();
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  TextColumn get tags => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get syncState => text().withDefault(const Constant('clean'))();

  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

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
@DataClassName('ConflictData')
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
// SUBCATEGORIES TABLE (Hierarchy Level 2)
// ============================================================

@TableIndex(name: 'idx_subcategories_category', columns: {#categoryId})
class SubCategories extends Table {
  TextColumn get id => text()();
  /// Links to the main Categories table
  TextColumn get categoryId => text().references(Categories, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get name => text()(); // Mortgage, Groceries, etc.
  TextColumn get ownerId => text().nullable().references(Users, #id)(); // null for system
  BoolColumn get isSystem => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefaultOther => boolean().withDefault(const Constant(false))();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUsedAt => dateTime().withDefault(currentDateAndTime)();
  RealColumn get confidence => real().withDefault(const Constant(1.0))(); // RESTORED
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get syncState => text().withDefault(const Constant('clean'))();

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
  
  /// P0 OBSERVABILITY: Link events across services
  TextColumn get correlationId => text().nullable()();
  
  /// Severity for telemetry filtering: info, warning, critical, security
  TextColumn get severity => text().withDefault(const Constant('info'))();

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
  IntColumn get priority => integer().withDefault(const Constant(0))(); // 0=Normal, 1=High, 2=Critical
  
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
@TableIndex(name: 'idx_learning_tokens', columns: {#semanticTokens})
class CategoryLearning extends Table {
  TextColumn get id => text()();
  
  // Input features
  TextColumn get merchantPattern => text()(); // Normalized merchant name/keyword (Legacy/Fallback)
  TextColumn get semanticTokens => text().nullable()(); // JSON List<String> (New Unified Model)
  
  // Outputs
  TextColumn get categoryName => text()(); // User's preferred category (Legacy)
  TextColumn get subCategoryId => text().nullable().references(SubCategories, #id, onDelete: KeyAction.cascade)();
  
  // Learning Metadata
  IntColumn get confidenceBoost => integer().withDefault(const Constant(10))(); // +confidence
  RealColumn get sourceWeight => real().withDefault(const Constant(1.0))(); // 1.0=Manual, 1.8=OCR, 3.0=Barcode
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


// ============================================================
// FAMILY MANAGEMENT SYSTEM TABLES
// ============================================================

/// Groups of family members (e.g., "The Smiths")
class FamilyGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get ownerId => text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get syncState => text().withDefault(const Constant('clean'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

  @override
  Set<Column> get primaryKey => {id};
}

/// Extended contact information for family intelligence
class FamilyContacts extends Table {
  TextColumn get id => text()();
  TextColumn get deviceContactId => text().nullable()(); // ID from flutter_contacts
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  
  BoolColumn get isLinkedToUser => boolean().withDefault(const Constant(false))();
  TextColumn get linkedUserId => text().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get syncState => text().withDefault(const Constant('clean'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

  @override
  Set<Column> get primaryKey => {id};
}

/// Relationship graph between contacts
@TableIndex(name: 'idx_relations_from', columns: {#fromContactId})
@TableIndex(name: 'idx_relations_to', columns: {#toContactId})
class FamilyRelations extends Table {
  TextColumn get id => text()();
  TextColumn get fromContactId => text().references(FamilyContacts, #id, onDelete: KeyAction.cascade)();
  TextColumn get toContactId => text().references(FamilyContacts, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get relationshipType => text()(); // spouse, child, parent, sibling, etc.
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  TextColumn get inferredBy => text().withDefault(const Constant('manual'))(); // manual, ai_logic
  
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get syncState => text().withDefault(const Constant('clean'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

  @override
  Set<Column> get primaryKey => {id};
}
// ============================================================
// KNOWLEDGE BASE (Articles & Tips)
// ============================================================

/// Knowledge Base Articles
@TableIndex(name: 'idx_knowledge_topic', columns: {#topic})
@DataClassName('KnowledgeArticleData')
class KnowledgeArticles extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get summary => text()();
  TextColumn get content => text()(); // Markdown/HTML content
  TextColumn get topic => text()(); // budgeting, investing, etc.
  TextColumn get tags => text().nullable()(); // JSON list
  TextColumn get imageUrl => text().nullable()();
  IntColumn get readTimeMinutes => integer().withDefault(const Constant(0))();
  TextColumn get languageCode => text().withDefault(const Constant('en'))();
  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get publishedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  // Sync fields
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get baseRevision => integer().nullable()(); // For conflict detection
  TextColumn get operationId => text().nullable()(); // For idempotency
  TextColumn get lastModifiedByDeviceId => text().nullable()();
  TextColumn get syncState => text().withDefault(const Constant('clean'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

  @override
  Set<Column> get primaryKey => {id};
}

/// Quick Financial Tips
@TableIndex(name: 'idx_tips_category', columns: {#category})
@DataClassName('FinancialTipData')
class FinancialTips extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get category => text()(); // daily, savings_alert, budget
  
  TextColumn get type => text()(); // info, warning, success
  TextColumn get actionLabel => text().nullable()(); // Button text e.g. "View Budget"
  TextColumn get actionRoute => text().nullable()(); // Route to navigate to
  
  TextColumn get languageCode => text().withDefault(const Constant('en'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  
  // Sync fields
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get baseRevision => integer().nullable()(); // For conflict detection
  TextColumn get operationId => text().nullable()(); // For idempotency
  TextColumn get lastModifiedByDeviceId => text().nullable()();
  TextColumn get syncState => text().withDefault(const Constant('clean'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  // Phase 8: Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); // JSON Map<DeviceId, Clock>

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// ASSETS TABLE (Net Worth Engine)
// ============================================================

@TableIndex(name: 'idx_assets_user', columns: {#userId})
@TableIndex(name: 'idx_assets_type', columns: {#type})
class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get type => text()(); // real_estate, vehicle, investment, cash, crypto, other
  IntColumn get currentValue => integer()(); // in cents
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  
  // Metadata for automated sync (e.g. Plaid/GoCardless later)
  BoolColumn get isAutomated => boolean().withDefault(const Constant(false))();
  TextColumn get InstitutionName => text().nullable()();
  
  DateTimeColumn get acquiredAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get metadata => text().map(const MetadataConverter()).nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  // Sync Fields
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get syncState => text().withDefault(const Constant('clean'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  // Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// LIABILITIES TABLE (Net Worth Engine)
// ============================================================

@TableIndex(name: 'idx_liabilities_user', columns: {#userId})
class Liabilities extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get type => text()(); // mortgage, loan, credit_card, other
  IntColumn get currentBalance => integer()(); // in cents (always positive value typically)
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  
  RealColumn get interestRate => real().nullable()(); // e.g. 4.5 for 4.5%
  DateTimeColumn get dueDate => dateTime().nullable()(); // Next payment due
  IntColumn get minPayment => integer().nullable()(); // in cents
  TextColumn get notes => text().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  // Sync Fields
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get syncState => text().withDefault(const Constant('clean'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  // Distributed State
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// VALUATION HISTORY TABLE (Net Worth Graphing)
// ============================================================

@TableIndex(name: 'idx_valuation_entity', columns: {#entityType, #entityId})
@TableIndex(name: 'idx_valuation_date', columns: {#date})
class ValuationHistory extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()(); // asset, liability
  TextColumn get entityId => text()(); // ID of asset or liability
  IntColumn get value => integer()(); // in cents
  DateTimeColumn get date => dateTime()(); // Snapshot date
  
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// LEDGER EVENTS TABLE (Event Sourcing - The "Black Box")
// ============================================================

@TableIndex(name: 'idx_ledger_timestamp', columns: {#timestamp})
@TableIndex(name: 'idx_ledger_entity', columns: {#entityType, #entityId})
class LedgerEvents extends Table {
  TextColumn get eventId => text()();
  TextColumn get eventType => text()(); // ASSET_CREATED, EXPENSE_UPDATED, MERGE_CONFLICT_RESOLVED
  
  TextColumn get entityType => text()(); // 'asset', 'expense', 'budget'
  TextColumn get entityId => text()();
  
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get deviceId => text().nullable()();
  
  // The Payload (Snapshot or Delta)
  TextColumn get eventData => text().map(const MetadataConverter())(); 
  
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  
  // Causal Ordering
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get versionVector => text().nullable()(); 
  
  // Cryptographic Chaining (Blockchain-lite for auditability)
  TextColumn get previousEventHash => text().nullable()();
  TextColumn get hash => text().nullable()(); 

  @override
  Set<Column> get primaryKey => {eventId};
}

// ============================================================
// BUDGET HEALTH SNAPSHOTS
// ============================================================

@TableIndex(name: 'idx_health_snapshots_user', columns: {#userId})
@TableIndex(name: 'idx_health_snapshots_date', columns: {#timestamp})
class BudgetHealthSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id, onDelete: KeyAction.cascade)();
  
  RealColumn get overallScore => real()();
  TextColumn get metricsJson => text()(); // Explanable scores JSON
  
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// CANONICAL LEDGER (Fintech System of Record)
// ============================================================

/// Canonical Ledger - Immutable financial facts derived from trusted sources.
/// This is the "Truth" derived from Banks/OCR before any UI manipulation.
class CanonicalLedger extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  
  /// Source identifier: 'nordigen', 'ocr', 'manual'
  TextColumn get source => text()();
  
  /// External reference (Bank Transaction ID, Receipt ID)
  TextColumn get sourceReference => text().nullable()();
  
  IntColumn get amount => integer()();
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  DateTimeColumn get bookingDate => dateTime()();
  TextColumn get description => text().nullable()();
  
  /// Verification status: 'verified', 'pending', 'contested'
  TextColumn get verificationStatus => text().withDefault(const Constant('pending'))();
  
  /// Reference to derived expense record
  TextColumn get derivedExpenseId => text().nullable().references(Expenses, #id)();
  
  /// Hash of raw fields for integrity verification (Tamper-evidence)
  TextColumn get payloadHash => text().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// USER CONSENTS (Compliance)
// ============================================================

/// Tracks user permissions for financial data access (GDPR/Open Banking)
class UserConsents extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  
  /// Permission scope: 'bank_read_transactions', 'ocr_storage'
  TextColumn get scope => text()();
  
  TextColumn get status => text().withDefault(const Constant('active'))(); // active, expired, revoked
  
  DateTimeColumn get grantedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  
  /// Compliance evidence (e.g., signed agreement hash)
  TextColumn get evidenceJson => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// FINANCIAL INGESTION LOGS (Layer 1)
// ============================================================

/// Tracks the lifecycle of data ingestion from external sources
class FinancialIngestionLogs extends Table {
  TextColumn get id => text()();
  TextColumn get provider => text()(); // 'nordigen', 'receipt'
  
  /// Status: 'started', 'normalizing', 'completed', 'failed'
  TextColumn get status => text()();
  
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
  
  IntColumn get recordsCount => integer().nullable()();
  TextColumn get errorMessage => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}
