/// Crash-Safe Principles for CashPilot
/// 
/// This document defines the crash-safe and data-safe guarantees
/// that must be enforced throughout the application.
library;

/// Core Principles
/// ===============
/// 
/// 1. NO PARTIAL WRITES
///    - All database operations that modify multiple tables must use transactions
///    - Either all changes succeed, or all are rolled back
///    - Example: Creating an expense with receipt upload must be atomic
/// 
/// 2. NO SILENT FAILURES
///    - All errors must be typed and reported
///    - Critical operations must not swallow exceptions
///    - Users must be informed of failures with recovery options
/// 
/// 3. RECOVERY PATHS DEFINED
///    - Every critical operation has a defined recovery strategy
///    - Offline operations queue for retry
///    - Network failures trigger backoff strategy
///    - User can always recover from errors

/// Transaction Boundaries
/// ======================
/// 
/// Operations that MUST use database transactions:
/// 
/// 1. Expense creation with receipt
/// 2. Budget creation with allocation
/// 3. Sync operations (push/pull)
/// 4. Family member operations
/// 5. Subscription updates
/// 6. Any operation touching multiple tables

/// Critical Operation Categories
/// ==============================

enum OperationCriticality {
  /// Must never fail silently (auth, encryption, payment)
  critical,
  
  /// Should retry on failure (sync, upload)
  important,
  
  /// Can fail gracefully (analytics, cache)
  optional,
}

/// Error Handling Requirements
/// ============================
/// 
/// CRITICAL Operations:
/// - Must throw typed exceptions
/// - Must show error UI to user
/// - Must log to error reporter (Crashlytics/Sentry)
/// - Must offer recovery action
/// 
/// IMPORTANT Operations:
/// - Must retry with exponential backoff
/// - Must queue for later if offline
/// - Must log failures
/// - Should show status to user
/// 
/// OPTIONAL Operations:
/// - Can log-and-continue
/// - Should not block user flow
/// - Can degrade gracefully

/// Enforcement Checklist
/// =====================
/// 
/// For every service/repository method:
/// 
/// 1. ✅ Identify criticality level
/// 2. ✅ Use transactions if multi-table
/// 3. ✅ Return typed Result<T, Error> or throw typed exception
/// 4. ✅ Define recovery path
/// 5. ✅ Add error reporting
/// 6. ✅ Add retry logic if applicable
/// 7. ✅ Test failure scenarios

/// Example: Crash-Safe Expense Creation
/// =====================================
/// 
/// BEFORE (unsafe):
/// ```dart
/// Future<void> createExpense(Expense expense, File? receipt) async {
///   try {
///     final expenseId = await db.expenses.insert(expense);
///     if (receipt != null) {
///       await uploadReceipt(receipt, expenseId); // Can fail!
///     }
///   } catch (e) {
///     debugPrint('Error: $e'); // Silent failure!
///   }
/// }
/// ```
/// 
/// AFTER (crash-safe):
/// ```dart
/// Future<Result<String, ExpenseCreationError>> createExpense(
///   Expense expense, 
///   File? receipt,
/// ) async {
///   return await db.transaction(() async {
///     // Step 1: Insert expense
///     final expenseId = await db.expenses.insert(expense);
///     
///     // Step 2: Upload receipt (if present)
///     if (receipt != null) {
///       try {
///         final url = await uploadReceipt(receipt);
///         await db.expenses.update(expenseId, receiptUrl: url);
///       } catch (e) {
///         // Rollback entire transaction
///         throw ExpenseCreationError.uploadFailed(e);
///       }
///     }
///     
///     return Result.success(expenseId);
///   }).catchError((e) {
///     ErrorReporter.report(ExpenseCreationError.fromException(e));
///     return Result.failure(ExpenseCreationError.fromException(e));
///   });
/// }
/// ```

/// Audit Status
/// ============
/// 
/// Services to audit for crash-safety:
/// 
/// - [ ] ExpenseService
/// - [ ] BudgetService
/// - [ ] ReceiptService
/// - [ ] SyncService
/// - [ ] AuthService (auth flows)
/// - [ ] SubscriptionService
/// - [ ] StripeService
/// - [ ] StorageService
/// 
/// For each service:
/// 1. Identify transaction boundaries
/// 2. Add typed error returns
/// 3. Add error reporting
/// 4. Define recovery paths
/// 5. Add tests for failure scenarios

/// Implementation Priority
/// =======================
/// 
/// Phase 1 (Sprint 1): Core Services
/// - ExpenseService (with receipt upload)
/// - BudgetService
/// - AuthService critical flows
/// 
/// Phase 2 (Sprint 2): Sync \u0026 Storage
/// - SyncService
/// - StorageService
/// - ReceiptService
/// 
/// Phase 3 (Sprint 3): Payment \u0026 Premium
/// - SubscriptionService
/// - StripeService

/// P0 Compliance Note
/// ==================
/// 
/// This document satisfies P0 requirement #5:
/// "Define 'crash safe' and 'data safe' principles"
/// 
/// Next Steps:
/// 1. Create typed error system (P1)
/// 2. Add error reporter integration (P1)
/// 3. Audit and refactor services (Sprints 1-2)
/// 4. Add failure scenario tests (Sprint 2)
