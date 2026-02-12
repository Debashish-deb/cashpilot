import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('fi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'CashPilot'**
  String get appName;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @navigationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navigationHome;

  /// No description provided for @navigationBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get navigationBudgets;

  /// No description provided for @navigationReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navigationReports;

  /// No description provided for @navigationSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navigationSettings;

  /// No description provided for @homeGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGoodMorning;

  /// No description provided for @homeGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGoodAfternoon;

  /// No description provided for @homeGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGoodEvening;

  /// No description provided for @homeTotalSpentMonth.
  ///
  /// In en, this message translates to:
  /// **'Total Spent This Month'**
  String get homeTotalSpentMonth;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get homeQuickActions;

  /// No description provided for @homeScanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get homeScanReceipt;

  /// No description provided for @homeScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get homeScanBarcode;

  /// No description provided for @homeAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get homeAddExpense;

  /// No description provided for @homeActiveBudgets.
  ///
  /// In en, this message translates to:
  /// **'Active Budgets'**
  String get homeActiveBudgets;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get homeRecentActivity;

  /// No description provided for @homeNoBudgets.
  ///
  /// In en, this message translates to:
  /// **'No active budgets'**
  String get homeNoBudgets;

  /// No description provided for @homeCreateFirstBudget.
  ///
  /// In en, this message translates to:
  /// **'Create your first budget to start tracking expenses'**
  String get homeCreateFirstBudget;

  /// No description provided for @budgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgetsTitle;

  /// No description provided for @budgetsCreateBudget.
  ///
  /// In en, this message translates to:
  /// **'Create Budget'**
  String get budgetsCreateBudget;

  /// No description provided for @budgetsEditBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get budgetsEditBudget;

  /// No description provided for @budgetsNewBudget.
  ///
  /// In en, this message translates to:
  /// **'New Budget'**
  String get budgetsNewBudget;

  /// No description provided for @budgetsBudgetName.
  ///
  /// In en, this message translates to:
  /// **'Budget Name'**
  String get budgetsBudgetName;

  /// No description provided for @budgetsBudgetType.
  ///
  /// In en, this message translates to:
  /// **'Budget Type'**
  String get budgetsBudgetType;

  /// No description provided for @budgetsDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get budgetsDateRange;

  /// No description provided for @budgetsTotalLimit.
  ///
  /// In en, this message translates to:
  /// **'Total Budget Limit'**
  String get budgetsTotalLimit;

  /// No description provided for @budgetsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get budgetsNotes;

  /// No description provided for @budgetsCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get budgetsCategories;

  /// No description provided for @budgetsAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get budgetsAddCategory;

  /// No description provided for @budgetsNoBudgets.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get budgetsNoBudgets;

  /// No description provided for @budgetsCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create your first budget to start tracking your expenses'**
  String get budgetsCreateFirst;

  /// No description provided for @budgetsSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetsSpent;

  /// No description provided for @budgetsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get budgetsRemaining;

  /// No description provided for @budgetsOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get budgetsOverBudget;

  /// No description provided for @budgetsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get budgetsActive;

  /// No description provided for @budgetsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get budgetsUpcoming;

  /// No description provided for @budgetsPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get budgetsPast;

  /// No description provided for @budgetsShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get budgetsShared;

  /// No description provided for @budgetsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get budgetsAll;

  /// No description provided for @expensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTitle;

  /// No description provided for @expensesAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get expensesAddExpense;

  /// No description provided for @expensesEditExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get expensesEditExpense;

  /// No description provided for @expensesAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expensesAmount;

  /// No description provided for @expensesDescription.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get expensesDescription;

  /// No description provided for @expensesDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Coffee at Starbucks'**
  String get expensesDescriptionHint;

  /// No description provided for @expensesBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get expensesBudget;

  /// No description provided for @expensesCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expensesCategory;

  /// No description provided for @expensesDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expensesDate;

  /// No description provided for @expensesPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get expensesPaymentMethod;

  /// No description provided for @expensesNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get expensesNotes;

  /// No description provided for @expensesNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add any additional notes...'**
  String get expensesNotesHint;

  /// No description provided for @expensesSave.
  ///
  /// In en, this message translates to:
  /// **'Save Expense'**
  String get expensesSave;

  /// No description provided for @expensesNoExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded yet'**
  String get expensesNoExpenses;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get commonMerge;

  /// No description provided for @commonCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get commonCategories;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get commonSuccess;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonAnd.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get commonAnd;

  /// No description provided for @commonNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get commonNoData;

  /// No description provided for @commonReturning.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get commonReturning;

  /// No description provided for @commonGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get commonGetStarted;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsBiometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get settingsBiometric;

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get settingsAppLock;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get settingsCloudSync;

  /// No description provided for @settingsExportData.
  ///
  /// In en, this message translates to:
  /// **'PDF, CSV, Excel'**
  String get settingsExportData;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsBackup;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTerms;

  /// No description provided for @settingsRateApp.
  ///
  /// In en, this message translates to:
  /// **'❤️ Rate CashPilot'**
  String get settingsRateApp;

  /// No description provided for @budgetTypeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budgetTypeMonthly;

  /// No description provided for @budgetTypeWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get budgetTypeWeekly;

  /// No description provided for @budgetTypeAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get budgetTypeAnnual;

  /// No description provided for @budgetTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get budgetTypeCustom;

  /// No description provided for @budgetDateStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get budgetDateStart;

  /// No description provided for @budgetDateEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get budgetDateEnd;

  /// No description provided for @expensesEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get expensesEnterAmount;

  /// No description provided for @expensesInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get expensesInvalidAmount;

  /// No description provided for @expensesEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get expensesEnterDescription;

  /// No description provided for @expensesSelectBudget.
  ///
  /// In en, this message translates to:
  /// **'Please select a budget'**
  String get expensesSelectBudget;

  /// No description provided for @expensesNoBudgetsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No budgets available to add expense.'**
  String get expensesNoBudgetsAvailable;

  /// No description provided for @expensesNoCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No categories in this budget. Add one!'**
  String get expensesNoCategoriesAvailable;

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentMethodCard;

  /// No description provided for @paymentMethodTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get paymentMethodTransfer;

  /// No description provided for @paymentMethodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get paymentMethodBank;

  /// No description provided for @paymentMethodWallet.
  ///
  /// In en, this message translates to:
  /// **'Mobile Wallet'**
  String get paymentMethodWallet;

  /// No description provided for @paymentMethodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get paymentMethodOther;

  /// No description provided for @budgetsNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get budgetsNoCategories;

  /// No description provided for @budgetsAddCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Add categories to organize your expenses'**
  String get budgetsAddCategoriesHint;

  /// No description provided for @expensesRecentExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recent Expenses'**
  String get expensesRecentExpenses;

  /// No description provided for @budgetsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Budget not found or has been deleted'**
  String get budgetsNotFound;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get reportsOverview;

  /// No description provided for @reportsCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get reportsCategories;

  /// No description provided for @reportsTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get reportsTrends;

  /// No description provided for @reportsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get reportsThisMonth;

  /// No description provided for @reportsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reportsToday;

  /// No description provided for @reportsDailyAvg.
  ///
  /// In en, this message translates to:
  /// **'Daily Average'**
  String get reportsDailyAvg;

  /// No description provided for @reportsBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get reportsBudgets;

  /// No description provided for @reportsBudgetProgress.
  ///
  /// In en, this message translates to:
  /// **'Budget Progress'**
  String get reportsBudgetProgress;

  /// No description provided for @reportsNoActiveBudgets.
  ///
  /// In en, this message translates to:
  /// **'No Active Budgets'**
  String get reportsNoActiveBudgets;

  /// No description provided for @reportsErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading budgets'**
  String get reportsErrorLoading;

  /// No description provided for @reportsNoBudgetsAnalyze.
  ///
  /// In en, this message translates to:
  /// **'No budgets to analyze'**
  String get reportsNoBudgetsAnalyze;

  /// No description provided for @reportsSpendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get reportsSpendingByCategory;

  /// No description provided for @reportsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get reportsTotal;

  /// No description provided for @reportsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get reportsThisWeek;

  /// No description provided for @reportsMonthlyComparison.
  ///
  /// In en, this message translates to:
  /// **'Monthly Comparison'**
  String get reportsMonthlyComparison;

  /// No description provided for @reportsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get reportsLastMonth;

  /// No description provided for @reportsInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get reportsInsights;

  /// No description provided for @reportsGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get reportsGetStarted;

  /// No description provided for @reportsGetStartedDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your first expenses to unlock personalized insights.'**
  String get reportsGetStartedDesc;

  /// No description provided for @reportsTodayExpenses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Expenses'**
  String get reportsTodayExpenses;

  /// No description provided for @reportsNoExpensesToday.
  ///
  /// In en, this message translates to:
  /// **'No expenses today'**
  String get reportsNoExpensesToday;

  /// No description provided for @reportsVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get reportsVsLastMonth;

  /// No description provided for @reportsTopCategories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get reportsTopCategories;

  /// No description provided for @reportsSeeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'See Breakdown'**
  String get reportsSeeBreakdown;

  /// No description provided for @reportsAnomalousSpendingSpike.
  ///
  /// In en, this message translates to:
  /// **'Unusual spike compared to last 3 months'**
  String get reportsAnomalousSpendingSpike;

  /// No description provided for @reportsLeft.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get reportsLeft;

  /// No description provided for @reportsExport.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get reportsExport;

  /// No description provided for @reportsExportPDF.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get reportsExportPDF;

  /// No description provided for @reportsExportCSV.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get reportsExportCSV;

  /// No description provided for @reportsExportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export as Excel'**
  String get reportsExportExcel;

  /// No description provided for @reportsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get reportsComingSoon;

  /// No description provided for @reportsWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get reportsWeek;

  /// No description provided for @reportsLast3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 Months'**
  String get reportsLast3Months;

  /// No description provided for @reportsCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reportsCustom;

  /// No description provided for @reportsNA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get reportsNA;

  /// No description provided for @reportsNoSpendingRecorded.
  ///
  /// In en, this message translates to:
  /// **'No spending recorded'**
  String get reportsNoSpendingRecorded;

  /// No description provided for @reportsPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Reporting Period'**
  String get reportsPeriodTitle;

  /// No description provided for @reportsMetricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Key Metrics'**
  String get reportsMetricsTitle;

  /// No description provided for @reportsDistributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Distribution'**
  String get reportsDistributionTitle;

  /// No description provided for @reportsBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get reportsBreakdownTitle;

  /// No description provided for @reportsRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get reportsRecentActivity;

  /// No description provided for @homeHighlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get homeHighlightsTitle;

  /// No description provided for @homeTrendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Flow'**
  String get homeTrendsTitle;

  /// No description provided for @reportsAddCategories.
  ///
  /// In en, this message translates to:
  /// **'Add Categories'**
  String get reportsAddCategories;

  /// No description provided for @reportsAddCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Add categories to this budget to analyze spending'**
  String get reportsAddCategoriesDesc;

  /// No description provided for @reportsExportCategoryReport.
  ///
  /// In en, this message translates to:
  /// **'Export Category Report'**
  String get reportsExportCategoryReport;

  /// No description provided for @reportsSpendingDistribution.
  ///
  /// In en, this message translates to:
  /// **'Spending Distribution'**
  String get reportsSpendingDistribution;

  /// No description provided for @reportsCategoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Category} other{{count} Categories}}'**
  String reportsCategoryCount(int count);

  /// No description provided for @reportsLoading.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get reportsLoading;

  /// No description provided for @reportsNoData.
  ///
  /// In en, this message translates to:
  /// **'---'**
  String get reportsNoData;

  /// No description provided for @reportsZero.
  ///
  /// In en, this message translates to:
  /// **'0'**
  String get reportsZero;

  /// No description provided for @reportsBudgetsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} budgets'**
  String reportsBudgetsCount(int count);

  /// No description provided for @reportsExportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get reportsExportData;

  /// No description provided for @reportsRefreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh Data'**
  String get reportsRefreshData;

  /// No description provided for @reportsSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get reportsSettings;

  /// No description provided for @reportsChartInfo.
  ///
  /// In en, this message translates to:
  /// **'This chart shows your spending trends over time. Tap on points to see details.'**
  String get reportsChartInfo;

  /// No description provided for @reportsGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get reportsGotIt;

  /// No description provided for @reportsHighestDay.
  ///
  /// In en, this message translates to:
  /// **'Highest Day'**
  String get reportsHighestDay;

  /// No description provided for @reports30DayTrend.
  ///
  /// In en, this message translates to:
  /// **'30-Day Trend'**
  String get reports30DayTrend;

  /// No description provided for @reportsWeekVsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week vs Last Week'**
  String get reportsWeekVsLastWeek;

  /// No description provided for @reportsNoExpensesAnalyze.
  ///
  /// In en, this message translates to:
  /// **'No expenses to analyze'**
  String get reportsNoExpensesAnalyze;

  /// No description provided for @reportsAddExpensesCategory.
  ///
  /// In en, this message translates to:
  /// **'Add some expenses to see category breakdown'**
  String get reportsAddExpensesCategory;

  /// No description provided for @reportsAddExpensesTrends.
  ///
  /// In en, this message translates to:
  /// **'Add some expenses to see spending trends'**
  String get reportsAddExpensesTrends;

  /// No description provided for @reportsExportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export report (PDF / CSV)'**
  String get reportsExportTooltip;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to CashPilot'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your intelligent personal finance companion.\nTrack expenses, manage budgets, and achieve your financial goals.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingFeatureBudget.
  ///
  /// In en, this message translates to:
  /// **'Smart budget tracking'**
  String get onboardingFeatureBudget;

  /// No description provided for @onboardingFeatureOCR.
  ///
  /// In en, this message translates to:
  /// **'OCR receipt scanning'**
  String get onboardingFeatureOCR;

  /// No description provided for @onboardingFeatureFamily.
  ///
  /// In en, this message translates to:
  /// **'Family budget sharing'**
  String get onboardingFeatureFamily;

  /// No description provided for @onboardingNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onboardingNameTitle;

  /// No description provided for @onboardingNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use this to personalize your experience'**
  String get onboardingNameSubtitle;

  /// No description provided for @onboardingNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get onboardingNameHint;

  /// No description provided for @onboardingCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your currency'**
  String get onboardingCurrencyTitle;

  /// No description provided for @onboardingCurrencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'This will be your default currency for budgets'**
  String get onboardingCurrencySubtitle;

  /// No description provided for @onboardingThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your theme'**
  String get onboardingThemeTitle;

  /// No description provided for @onboardingThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in settings'**
  String get onboardingThemeSubtitle;

  /// No description provided for @onboardingThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get onboardingThemeLight;

  /// No description provided for @onboardingThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get onboardingThemeDark;

  /// No description provided for @onboardingThemeAmoled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED'**
  String get onboardingThemeAmoled;

  /// No description provided for @onboardingReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set, {name}!'**
  String onboardingReadyTitle(String name);

  /// No description provided for @onboardingReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start by creating your first budget and tracking your expenses.'**
  String get onboardingReadySubtitle;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored locally on your device and encrypted when synced.'**
  String get onboardingPrivacyNote;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get scanTitle;

  /// No description provided for @scanHeadline.
  ///
  /// In en, this message translates to:
  /// **'Scan Your Receipt'**
  String get scanHeadline;

  /// No description provided for @scanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or choose from gallery to automatically extract expense details'**
  String get scanSubtitle;

  /// No description provided for @scanScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanScanning;

  /// No description provided for @scanTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get scanTakePhoto;

  /// No description provided for @scanGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get scanGallery;

  /// No description provided for @scanTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips for best results'**
  String get scanTipsTitle;

  /// No description provided for @scanTipLighting.
  ///
  /// In en, this message translates to:
  /// **'Ensure good lighting'**
  String get scanTipLighting;

  /// No description provided for @scanTipSteady.
  ///
  /// In en, this message translates to:
  /// **'Hold camera steady'**
  String get scanTipSteady;

  /// No description provided for @scanTipEntire.
  ///
  /// In en, this message translates to:
  /// **'Capture entire receipt'**
  String get scanTipEntire;

  /// No description provided for @scanTipShadows.
  ///
  /// In en, this message translates to:
  /// **'Avoid shadows and glare'**
  String get scanTipShadows;

  /// No description provided for @scanConfidence.
  ///
  /// In en, this message translates to:
  /// **'Scan Confidence'**
  String get scanConfidence;

  /// No description provided for @scanTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get scanTotalAmount;

  /// No description provided for @scanMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get scanMerchant;

  /// No description provided for @scanDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get scanDate;

  /// No description provided for @scanItemsFound.
  ///
  /// In en, this message translates to:
  /// **'Items Found'**
  String get scanItemsFound;

  /// No description provided for @scanRawText.
  ///
  /// In en, this message translates to:
  /// **'Raw Text'**
  String get scanRawText;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgain;

  /// No description provided for @scanErrorNoImage.
  ///
  /// In en, this message translates to:
  /// **'No image captured'**
  String get scanErrorNoImage;

  /// No description provided for @scanErrorNoSelection.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get scanErrorNoSelection;

  /// No description provided for @scanErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to scan'**
  String get scanErrorFailed;

  /// No description provided for @commonPageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get commonPageNotFound;

  /// No description provided for @commonGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get commonGoHome;

  /// No description provided for @profileGuestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get profileGuestUser;

  /// No description provided for @profileSignInToSync.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data'**
  String get profileSignInToSync;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// No description provided for @settingsChooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get settingsChooseTheme;

  /// No description provided for @settingsChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get settingsChooseLanguage;

  /// No description provided for @settingsChooseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Choose Currency'**
  String get settingsChooseCurrency;

  /// No description provided for @settingsCreateBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get settingsCreateBackup;

  /// No description provided for @settingsExportFormats.
  ///
  /// In en, this message translates to:
  /// **'PDF, CSV, Excel'**
  String get settingsExportFormats;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeAmoled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED'**
  String get themeAmoled;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @scans.
  ///
  /// In en, this message translates to:
  /// **'Scans'**
  String get scans;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Manually'**
  String get enterManually;

  /// No description provided for @ensureGoodLighting.
  ///
  /// In en, this message translates to:
  /// **'Ensure good lighting'**
  String get ensureGoodLighting;

  /// No description provided for @goodLightingDescription.
  ///
  /// In en, this message translates to:
  /// **'Hold the barcode steady in a well-lit area for best results.'**
  String get goodLightingDescription;

  /// No description provided for @keepSteady.
  ///
  /// In en, this message translates to:
  /// **'Keep steady'**
  String get keepSteady;

  /// No description provided for @steadyDescription.
  ///
  /// In en, this message translates to:
  /// **'Avoid shaking the device while scanning.'**
  String get steadyDescription;

  /// No description provided for @alignInFrame.
  ///
  /// In en, this message translates to:
  /// **'Align in frame'**
  String get alignInFrame;

  /// No description provided for @frameAlignmentDescription.
  ///
  /// In en, this message translates to:
  /// **'Position the barcode within the scan frame.'**
  String get frameAlignmentDescription;

  /// No description provided for @batchScanning.
  ///
  /// In en, this message translates to:
  /// **'Batch scanning'**
  String get batchScanning;

  /// No description provided for @batchScanningDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan multiple items quickly by tapping \'Scan Another\'.'**
  String get batchScanningDescription;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get offlineMode;

  /// No description provided for @offlineModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Scans are saved locally when offline and synced later.'**
  String get offlineModeDescription;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @exitScanConfirmation.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved scans. Do you want to discard them?'**
  String get exitScanConfirmation;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @saveAndExit.
  ///
  /// In en, this message translates to:
  /// **'Save & Exit'**
  String get saveAndExit;

  /// No description provided for @enterBarcodeManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Barcode Manually'**
  String get enterBarcodeManually;

  /// No description provided for @barcodeExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., 1234567890123'**
  String get barcodeExample;

  /// No description provided for @settingsSubscriptionAndFeatures.
  ///
  /// In en, this message translates to:
  /// **'Subscription & Features'**
  String get settingsSubscriptionAndFeatures;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsFreePlan.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get settingsFreePlan;

  /// No description provided for @settingsProPlan.
  ///
  /// In en, this message translates to:
  /// **'PRO Plan'**
  String get settingsProPlan;

  /// No description provided for @settingsOcrScans.
  ///
  /// In en, this message translates to:
  /// **'OCR Scans'**
  String get settingsOcrScans;

  /// No description provided for @settingsOcrScansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'2 scans/month on Free plan'**
  String get settingsOcrScansSubtitle;

  /// No description provided for @settingsFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get settingsFree;

  /// No description provided for @settingsLastCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Last Cloud Sync'**
  String get settingsLastCloudSync;

  /// No description provided for @settingsLastCloudSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap Cloud Sync above to sync now'**
  String get settingsLastCloudSyncSubtitle;

  /// No description provided for @settingsManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get settingsManageSubscription;

  /// No description provided for @settingsSubscriptionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Subscription management coming soon!\n\nYou can manage your subscription from your app store account.'**
  String get settingsSubscriptionComingSoon;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonPro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get commonPro;

  /// No description provided for @commonSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get commonSort;

  /// No description provided for @commonExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get commonExport;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get commonFilter;

  /// No description provided for @commonActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActive;

  /// No description provided for @commonUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get commonUpcoming;

  /// No description provided for @commonCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get commonCompleted;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonSearchBudgets.
  ///
  /// In en, this message translates to:
  /// **'Search budgets...'**
  String get commonSearchBudgets;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get commonMoreOptions;

  /// No description provided for @reportsActiveBudgets.
  ///
  /// In en, this message translates to:
  /// **'Active Budgets'**
  String get reportsActiveBudgets;

  /// No description provided for @commonSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get commonSupport;

  /// No description provided for @settingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get settingsDangerZone;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your data'**
  String get settingsDeleteAccountSubtitle;

  /// No description provided for @catGroupHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get catGroupHousing;

  /// No description provided for @catGroupUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get catGroupUtilities;

  /// No description provided for @catGroupFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catGroupFood;

  /// No description provided for @catGroupTransportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get catGroupTransportation;

  /// No description provided for @catGroupHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catGroupHealth;

  /// No description provided for @catGroupLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get catGroupLifestyle;

  /// No description provided for @catGroupFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get catGroupFinance;

  /// No description provided for @catGroupEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get catGroupEducation;

  /// No description provided for @catGroupFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get catGroupFamily;

  /// No description provided for @catGroupTech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get catGroupTech;

  /// No description provided for @catGroupHobby.
  ///
  /// In en, this message translates to:
  /// **'Hobby'**
  String get catGroupHobby;

  /// No description provided for @catGroupUndeclared.
  ///
  /// In en, this message translates to:
  /// **'Undeclared'**
  String get catGroupUndeclared;

  /// No description provided for @catUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get catUncategorized;

  /// No description provided for @catRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get catRent;

  /// No description provided for @catMortgage.
  ///
  /// In en, this message translates to:
  /// **'Mortgage'**
  String get catMortgage;

  /// No description provided for @catPropertyTax.
  ///
  /// In en, this message translates to:
  /// **'Property Tax'**
  String get catPropertyTax;

  /// No description provided for @catHomeInsurance.
  ///
  /// In en, this message translates to:
  /// **'Home Insurance'**
  String get catHomeInsurance;

  /// No description provided for @catRepairsMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Repairs & Maintenance'**
  String get catRepairsMaintenance;

  /// No description provided for @catHardware.
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get catHardware;

  /// No description provided for @catGardening.
  ///
  /// In en, this message translates to:
  /// **'Gardening'**
  String get catGardening;

  /// No description provided for @catFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get catFurniture;

  /// No description provided for @catHouseCleaning.
  ///
  /// In en, this message translates to:
  /// **'House Cleaning'**
  String get catHouseCleaning;

  /// No description provided for @catSecuritySystem.
  ///
  /// In en, this message translates to:
  /// **'Security System'**
  String get catSecuritySystem;

  /// No description provided for @catHoaFees.
  ///
  /// In en, this message translates to:
  /// **'HOA Fees'**
  String get catHoaFees;

  /// No description provided for @catElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get catElectricity;

  /// No description provided for @catWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get catWater;

  /// No description provided for @catGas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get catGas;

  /// No description provided for @catInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get catInternet;

  /// No description provided for @catPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get catPhone;

  /// No description provided for @catTrashWaste.
  ///
  /// In en, this message translates to:
  /// **'Trash/Waste'**
  String get catTrashWaste;

  /// No description provided for @catHeatingOil.
  ///
  /// In en, this message translates to:
  /// **'Heating/Oil'**
  String get catHeatingOil;

  /// No description provided for @catGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get catGroceries;

  /// No description provided for @catDiningOut.
  ///
  /// In en, this message translates to:
  /// **'Dining Out'**
  String get catDiningOut;

  /// No description provided for @catFastFood.
  ///
  /// In en, this message translates to:
  /// **'Fast Food'**
  String get catFastFood;

  /// No description provided for @catDrinksNightlife.
  ///
  /// In en, this message translates to:
  /// **'Drinks & Nightlife'**
  String get catDrinksNightlife;

  /// No description provided for @catCoffeeCafes.
  ///
  /// In en, this message translates to:
  /// **'Coffee & Cafes'**
  String get catCoffeeCafes;

  /// No description provided for @catBakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get catBakery;

  /// No description provided for @catStreetFood.
  ///
  /// In en, this message translates to:
  /// **'Street Food'**
  String get catStreetFood;

  /// No description provided for @catTiffin.
  ///
  /// In en, this message translates to:
  /// **'Tiffin / Lunchbox'**
  String get catTiffin;

  /// No description provided for @catMealKits.
  ///
  /// In en, this message translates to:
  /// **'Meal Kits'**
  String get catMealKits;

  /// No description provided for @catCandySnacks.
  ///
  /// In en, this message translates to:
  /// **'Candy/Snacks'**
  String get catCandySnacks;

  /// No description provided for @catFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get catFuel;

  /// No description provided for @catPublicTransit.
  ///
  /// In en, this message translates to:
  /// **'Public Transit'**
  String get catPublicTransit;

  /// No description provided for @catCarInsurance.
  ///
  /// In en, this message translates to:
  /// **'Car Insurance'**
  String get catCarInsurance;

  /// No description provided for @catCarMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Car Maintenance'**
  String get catCarMaintenance;

  /// No description provided for @catParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get catParking;

  /// No description provided for @catRideShare.
  ///
  /// In en, this message translates to:
  /// **'Ride Share'**
  String get catRideShare;

  /// No description provided for @catTaxi.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get catTaxi;

  /// No description provided for @catBike.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get catBike;

  /// No description provided for @catMotorcycle.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle'**
  String get catMotorcycle;

  /// No description provided for @catRegistrationTolls.
  ///
  /// In en, this message translates to:
  /// **'Registration/Tolls'**
  String get catRegistrationTolls;

  /// No description provided for @catCarWash.
  ///
  /// In en, this message translates to:
  /// **'Car Wash'**
  String get catCarWash;

  /// No description provided for @catDoctorClinic.
  ///
  /// In en, this message translates to:
  /// **'Doctor/Clinic'**
  String get catDoctorClinic;

  /// No description provided for @catPharmacyMeds.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy/Meds'**
  String get catPharmacyMeds;

  /// No description provided for @catDentist.
  ///
  /// In en, this message translates to:
  /// **'Dentist'**
  String get catDentist;

  /// No description provided for @catFitnessGym.
  ///
  /// In en, this message translates to:
  /// **'Fitness/Gym'**
  String get catFitnessGym;

  /// No description provided for @catMedicalInsurance.
  ///
  /// In en, this message translates to:
  /// **'Medical Insurance'**
  String get catMedicalInsurance;

  /// No description provided for @catPersonalCare.
  ///
  /// In en, this message translates to:
  /// **'Personal Care'**
  String get catPersonalCare;

  /// No description provided for @catEyeCare.
  ///
  /// In en, this message translates to:
  /// **'Eye Care'**
  String get catEyeCare;

  /// No description provided for @catTherapyMentalHealth.
  ///
  /// In en, this message translates to:
  /// **'Therapy/Mental Health'**
  String get catTherapyMentalHealth;

  /// No description provided for @catVitaminsSupplements.
  ///
  /// In en, this message translates to:
  /// **'Vitamins/Supplements'**
  String get catVitaminsSupplements;

  /// No description provided for @catEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get catEntertainment;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get catTravel;

  /// No description provided for @catMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get catMovies;

  /// No description provided for @catClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get catClothing;

  /// No description provided for @catEventsParty.
  ///
  /// In en, this message translates to:
  /// **'Events/Party'**
  String get catEventsParty;

  /// No description provided for @catSpaMassage.
  ///
  /// In en, this message translates to:
  /// **'Spa/Massage'**
  String get catSpaMassage;

  /// No description provided for @catSportsEvents.
  ///
  /// In en, this message translates to:
  /// **'Sports/Events'**
  String get catSportsEvents;

  /// No description provided for @catBooksMagazines.
  ///
  /// In en, this message translates to:
  /// **'Books/Magazines'**
  String get catBooksMagazines;

  /// No description provided for @catSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get catSavings;

  /// No description provided for @catInvestments.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get catInvestments;

  /// No description provided for @catDebtRepayment.
  ///
  /// In en, this message translates to:
  /// **'Debt Repayment'**
  String get catDebtRepayment;

  /// No description provided for @catFees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get catFees;

  /// No description provided for @catTaxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get catTaxes;

  /// No description provided for @catCharity.
  ///
  /// In en, this message translates to:
  /// **'Charity / Donation'**
  String get catCharity;

  /// No description provided for @catDonation.
  ///
  /// In en, this message translates to:
  /// **'Donation'**
  String get catDonation;

  /// No description provided for @catBankFees.
  ///
  /// In en, this message translates to:
  /// **'Bank Fees'**
  String get catBankFees;

  /// No description provided for @catInterestPayment.
  ///
  /// In en, this message translates to:
  /// **'Interest Payment'**
  String get catInterestPayment;

  /// No description provided for @catLifeInsurance.
  ///
  /// In en, this message translates to:
  /// **'Life Insurance'**
  String get catLifeInsurance;

  /// No description provided for @catTuition.
  ///
  /// In en, this message translates to:
  /// **'Tuition'**
  String get catTuition;

  /// No description provided for @catBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get catBooks;

  /// No description provided for @catOnlineCourses.
  ///
  /// In en, this message translates to:
  /// **'Online Courses'**
  String get catOnlineCourses;

  /// No description provided for @catCertifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get catCertifications;

  /// No description provided for @catSupplies.
  ///
  /// In en, this message translates to:
  /// **'Supplies'**
  String get catSupplies;

  /// No description provided for @catExtracurriculars.
  ///
  /// In en, this message translates to:
  /// **'Extracurriculars'**
  String get catExtracurriculars;

  /// No description provided for @catWorkshops.
  ///
  /// In en, this message translates to:
  /// **'Workshops'**
  String get catWorkshops;

  /// No description provided for @catKidsChildcare.
  ///
  /// In en, this message translates to:
  /// **'Kids/Childcare'**
  String get catKidsChildcare;

  /// No description provided for @catSchoolFees.
  ///
  /// In en, this message translates to:
  /// **'School Fees'**
  String get catSchoolFees;

  /// No description provided for @catPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get catPets;

  /// No description provided for @catGifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get catGifts;

  /// No description provided for @catHomeSupplies.
  ///
  /// In en, this message translates to:
  /// **'Home Supplies'**
  String get catHomeSupplies;

  /// No description provided for @catEldercare.
  ///
  /// In en, this message translates to:
  /// **'Eldercare'**
  String get catEldercare;

  /// No description provided for @catBabySupplies.
  ///
  /// In en, this message translates to:
  /// **'Baby Supplies'**
  String get catBabySupplies;

  /// No description provided for @catToys.
  ///
  /// In en, this message translates to:
  /// **'Toys'**
  String get catToys;

  /// No description provided for @catGadgets.
  ///
  /// In en, this message translates to:
  /// **'Gadgets'**
  String get catGadgets;

  /// No description provided for @catSoftwareSubs.
  ///
  /// In en, this message translates to:
  /// **'Software/Subs'**
  String get catSoftwareSubs;

  /// No description provided for @catGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get catGames;

  /// No description provided for @catCloudServices.
  ///
  /// In en, this message translates to:
  /// **'Cloud Services'**
  String get catCloudServices;

  /// No description provided for @catElectronicsRepair.
  ///
  /// In en, this message translates to:
  /// **'Electronics Repair'**
  String get catElectronicsRepair;

  /// No description provided for @catHostingDomains.
  ///
  /// In en, this message translates to:
  /// **'Hosting/Domains'**
  String get catHostingDomains;

  /// No description provided for @catStreamingServices.
  ///
  /// In en, this message translates to:
  /// **'Streaming Services'**
  String get catStreamingServices;

  /// No description provided for @catArtsAndCrafts.
  ///
  /// In en, this message translates to:
  /// **'Arts & Crafts'**
  String get catArtsAndCrafts;

  /// No description provided for @catPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get catPhotography;

  /// No description provided for @catGaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get catGaming;

  /// No description provided for @catMusicInstruments.
  ///
  /// In en, this message translates to:
  /// **'Music/Instruments'**
  String get catMusicInstruments;

  /// No description provided for @catSportsEquipment.
  ///
  /// In en, this message translates to:
  /// **'Sports Equipment'**
  String get catSportsEquipment;

  /// No description provided for @catCampingHiking.
  ///
  /// In en, this message translates to:
  /// **'Camping/Hiking'**
  String get catCampingHiking;

  /// No description provided for @catCollecting.
  ///
  /// In en, this message translates to:
  /// **'Collecting'**
  String get catCollecting;

  /// No description provided for @fxAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fxAmount;

  /// No description provided for @fxUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get fxUpdated;

  /// No description provided for @fxOfflineRates.
  ///
  /// In en, this message translates to:
  /// **'Using offline rates'**
  String get fxOfflineRates;

  /// No description provided for @fxConvertFrom.
  ///
  /// In en, this message translates to:
  /// **'Convert from'**
  String get fxConvertFrom;

  /// No description provided for @fxConvertTo.
  ///
  /// In en, this message translates to:
  /// **'Convert to'**
  String get fxConvertTo;

  /// No description provided for @fxExchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate'**
  String get fxExchangeRate;

  /// No description provided for @fxFee.
  ///
  /// In en, this message translates to:
  /// **'FX fee'**
  String get fxFee;

  /// No description provided for @fxSpread.
  ///
  /// In en, this message translates to:
  /// **'Spread'**
  String get fxSpread;

  /// No description provided for @fxNetAmount.
  ///
  /// In en, this message translates to:
  /// **'Net amount'**
  String get fxNetAmount;

  /// No description provided for @fxRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing rates...'**
  String get fxRefreshing;

  /// No description provided for @expensesViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get expensesViewAll;

  /// No description provided for @expensesDeleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get expensesDeleteExpense;

  /// No description provided for @expensesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this expense?'**
  String get expensesDeleteConfirm;

  /// No description provided for @expensesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get expensesDeleted;

  /// No description provided for @expensesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load expense'**
  String get expensesLoadError;

  /// No description provided for @expensesSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving expense'**
  String get expensesSaveError;

  /// No description provided for @expensesDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting expense'**
  String get expensesDeleteError;

  /// No description provided for @expensesProductLookup.
  ///
  /// In en, this message translates to:
  /// **'Looking up product...'**
  String get expensesProductLookup;

  /// No description provided for @expensesProductFound.
  ///
  /// In en, this message translates to:
  /// **'Product found'**
  String get expensesProductFound;

  /// No description provided for @expensesProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product details not found, but barcode scanned.'**
  String get expensesProductNotFound;

  /// No description provided for @expensesScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed'**
  String get expensesScanFailed;

  /// No description provided for @expensesErrorLoadingBudgets.
  ///
  /// In en, this message translates to:
  /// **'Error loading budgets'**
  String get expensesErrorLoadingBudgets;

  /// No description provided for @expensesErrorLoadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Error loading categories'**
  String get expensesErrorLoadingCategories;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get commonLastWeek;

  /// No description provided for @commonEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get commonEarlier;

  /// No description provided for @expensesEmptyCreate.
  ///
  /// In en, this message translates to:
  /// **'Add your first expense to get started'**
  String get expensesEmptyCreate;

  /// No description provided for @commonJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get commonJustNow;

  /// No description provided for @commonMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String commonMinutesAgo(int minutes);

  /// No description provided for @commonHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String commonHoursAgo(int hours);

  /// No description provided for @commonDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String commonDaysAgo(int days);

  /// No description provided for @homeNetWorthDesc.
  ///
  /// In en, this message translates to:
  /// **'Your net worth is what you own minus what you owe.'**
  String get homeNetWorthDesc;

  /// No description provided for @homeSmartAdd.
  ///
  /// In en, this message translates to:
  /// **'Smart Add'**
  String get homeSmartAdd;

  /// No description provided for @homeTrackSpendingDesc.
  ///
  /// In en, this message translates to:
  /// **'Track your spending to see insights here.'**
  String get homeTrackSpendingDesc;

  /// No description provided for @homeTrackSpendingBtn.
  ///
  /// In en, this message translates to:
  /// **'Track Spending'**
  String get homeTrackSpendingBtn;

  /// No description provided for @homeSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'Your financial data is stored securely on your device.'**
  String get homeSecurityNote;

  /// No description provided for @budgetsEmptyActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a budget to start tracking your spending.'**
  String get budgetsEmptyActiveDesc;

  /// No description provided for @budgetsEmptyUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming budgets'**
  String get budgetsEmptyUpcomingTitle;

  /// No description provided for @budgetsEmptyUpcomingDesc.
  ///
  /// In en, this message translates to:
  /// **'Plan ahead by scheduling your next budget.'**
  String get budgetsEmptyUpcomingDesc;

  /// No description provided for @budgetsScheduleBtn.
  ///
  /// In en, this message translates to:
  /// **'Schedule Budget'**
  String get budgetsScheduleBtn;

  /// No description provided for @budgetsEmptyPastTitle.
  ///
  /// In en, this message translates to:
  /// **'No past budgets'**
  String get budgetsEmptyPastTitle;

  /// No description provided for @budgetsEmptyPastDesc.
  ///
  /// In en, this message translates to:
  /// **'Budgets that have ended will appear here for your review.'**
  String get budgetsEmptyPastDesc;

  /// No description provided for @budgetsEmptyFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'No family budgets'**
  String get budgetsEmptyFamilyTitle;

  /// No description provided for @budgetsEmptyFamilyDesc.
  ///
  /// In en, this message translates to:
  /// **'Budgets shared with your family group show up here.'**
  String get budgetsEmptyFamilyDesc;

  /// No description provided for @budgetsCreateSharedBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Shared Budget'**
  String get budgetsCreateSharedBtn;

  /// No description provided for @budgetsStatisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Statistics'**
  String get budgetsStatisticsTitle;

  /// No description provided for @budgetsSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort Budgets'**
  String get budgetsSortTitle;

  /// No description provided for @sortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get sortNewestFirst;

  /// No description provided for @sortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get sortOldestFirst;

  /// No description provided for @sortNameAZ.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get sortNameAZ;

  /// No description provided for @sortNameZA.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get sortNameZA;

  /// No description provided for @sortAmountHighLow.
  ///
  /// In en, this message translates to:
  /// **'Amount (High to Low)'**
  String get sortAmountHighLow;

  /// No description provided for @sortAmountLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Amount (Low to High)'**
  String get sortAmountLowHigh;

  /// No description provided for @budgetsStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Budgeted'**
  String get budgetsStatTotal;

  /// No description provided for @budgetsStatCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get budgetsStatCompleted;

  /// No description provided for @reportsPeriod.
  ///
  /// In en, this message translates to:
  /// **'Reporting Period'**
  String get reportsPeriod;

  /// No description provided for @reportsLockedCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Category Analytics'**
  String get reportsLockedCategoryTitle;

  /// No description provided for @reportsLockedCategoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock detailed category breakdowns, spending patterns, and pie charts.'**
  String get reportsLockedCategoryDesc;

  /// No description provided for @reportsLockedTrendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending Trends'**
  String get reportsLockedTrendsTitle;

  /// No description provided for @reportsLockedTrendsDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock spending trends, comparison charts, and predictive insights.'**
  String get reportsLockedTrendsDesc;

  /// No description provided for @commonUpgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get commonUpgradeToPro;

  /// No description provided for @reportsQuickInsights.
  ///
  /// In en, this message translates to:
  /// **'Quick Insights'**
  String get reportsQuickInsights;

  /// No description provided for @insightTopCategory.
  ///
  /// In en, this message translates to:
  /// **'Top Category'**
  String get insightTopCategory;

  /// No description provided for @insightPeakDay.
  ///
  /// In en, this message translates to:
  /// **'Peak Day'**
  String get insightPeakDay;

  /// No description provided for @insightOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over Budget'**
  String get insightOverBudget;

  /// No description provided for @insightPotentialSavings.
  ///
  /// In en, this message translates to:
  /// **'Potential Savings'**
  String get insightPotentialSavings;

  /// No description provided for @reportsRecentSpending.
  ///
  /// In en, this message translates to:
  /// **'Recent Spending'**
  String get reportsRecentSpending;

  /// No description provided for @reportsVsPrevious.
  ///
  /// In en, this message translates to:
  /// **'vs previous period'**
  String get reportsVsPrevious;

  /// No description provided for @reportsDailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily average: {amount}'**
  String reportsDailyAverage(String amount);

  /// No description provided for @reportsSpendingOnTrack.
  ///
  /// In en, this message translates to:
  /// **'Spending is on track this month'**
  String get reportsSpendingOnTrack;

  /// No description provided for @reportsSpendingOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget by {amount}'**
  String reportsSpendingOverBudget(String amount);

  /// No description provided for @reportsNoDataPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get reportsNoDataPeriod;

  /// No description provided for @reportsCreateBudgetPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create a budget to start analyzing spending by category'**
  String get reportsCreateBudgetPrompt;

  /// No description provided for @expensesAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get expensesAmountHint;

  /// No description provided for @expensesTitleExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., Coffee at Starbucks'**
  String get expensesTitleExample;

  /// No description provided for @expensesGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get expensesGroupToday;

  /// No description provided for @expensesGroupYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get expensesGroupYesterday;

  /// No description provided for @expensesGroupThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get expensesGroupThisWeek;

  /// No description provided for @expensesGroupLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get expensesGroupLastWeek;

  /// No description provided for @expensesGroupEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get expensesGroupEarlier;

  /// No description provided for @categorySelectorLabel.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get categorySelectorLabel;

  /// No description provided for @categoryUsagePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String categoryUsagePercent(int percent);

  /// No description provided for @categoryAutoLabeled.
  ///
  /// In en, this message translates to:
  /// **'Auto-categorized'**
  String get categoryAutoLabeled;

  /// No description provided for @categorySuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get categorySuggested;

  /// No description provided for @categoryDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get categoryDismiss;

  /// No description provided for @categoryApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get categoryApply;

  /// No description provided for @categoryUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get categoryUndo;

  /// No description provided for @settingsMLAdmin.
  ///
  /// In en, this message translates to:
  /// **'ML Administration'**
  String get settingsMLAdmin;

  /// No description provided for @settingsMLDashboard.
  ///
  /// In en, this message translates to:
  /// **'ML Dashboard'**
  String get settingsMLDashboard;

  /// No description provided for @settingsMLDashboardDesc.
  ///
  /// In en, this message translates to:
  /// **'Monitor model performance and metrics'**
  String get settingsMLDashboardDesc;

  /// No description provided for @settingsABTesting.
  ///
  /// In en, this message translates to:
  /// **'A/B Testing'**
  String get settingsABTesting;

  /// No description provided for @settingsABTestingDesc.
  ///
  /// In en, this message translates to:
  /// **'Compare and manage model versions'**
  String get settingsABTestingDesc;

  /// No description provided for @settingsTabGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsTabGeneral;

  /// No description provided for @settingsTabAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsTabAdvanced;

  /// No description provided for @settingsCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage expense categories'**
  String get settingsCategoriesDesc;

  /// No description provided for @settingsAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get settingsAccentColor;

  /// No description provided for @settingsSyncManagement.
  ///
  /// In en, this message translates to:
  /// **'SYNC MANAGEMENT'**
  String get settingsSyncManagement;

  /// No description provided for @settingsDataManagement.
  ///
  /// In en, this message translates to:
  /// **'DATA MANAGEMENT'**
  String get settingsDataManagement;

  /// No description provided for @settingsForceFullSync.
  ///
  /// In en, this message translates to:
  /// **'Force Full Sync'**
  String get settingsForceFullSync;

  /// No description provided for @settingsForceFullSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear cache & re-download all data'**
  String get settingsForceFullSyncDesc;

  /// No description provided for @settingsRealtimeSync.
  ///
  /// In en, this message translates to:
  /// **'Realtime Sync'**
  String get settingsRealtimeSync;

  /// No description provided for @settingsConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settingsConnected;

  /// No description provided for @settingsSyncConflicts.
  ///
  /// In en, this message translates to:
  /// **'Sync Conflicts'**
  String get settingsSyncConflicts;

  /// No description provided for @settingsNoConflicts.
  ///
  /// In en, this message translates to:
  /// **'No conflicts'**
  String get settingsNoConflicts;

  /// No description provided for @settingsSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get settingsSyncing;

  /// No description provided for @settingsSyncError.
  ///
  /// In en, this message translates to:
  /// **'Sync error: {error}'**
  String settingsSyncError(String error);

  /// No description provided for @settingsSyncedItems.
  ///
  /// In en, this message translates to:
  /// **'✅ Synced {count} items'**
  String settingsSyncedItems(int count);

  /// No description provided for @settingsSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ {message}'**
  String settingsSyncFailed(String message);

  /// No description provided for @settingsSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get settingsSyncNow;

  /// No description provided for @settingsSyncingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Syncing enabled. Data will be encrypted.'**
  String get settingsSyncingEnabled;

  /// No description provided for @settingsForceSync.
  ///
  /// In en, this message translates to:
  /// **'Force Sync'**
  String get settingsForceSync;

  /// No description provided for @settingsForceSyncing.
  ///
  /// In en, this message translates to:
  /// **'Force syncing to cloud...'**
  String get settingsForceSyncing;

  /// No description provided for @settingsClearingCache.
  ///
  /// In en, this message translates to:
  /// **'Clearing cache...'**
  String get settingsClearingCache;

  /// No description provided for @settingsFullSyncComplete.
  ///
  /// In en, this message translates to:
  /// **'✅ Full sync completed'**
  String get settingsFullSyncComplete;

  /// No description provided for @settingsCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settingsCategories;

  /// No description provided for @settingsRecurringExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recurring Expenses'**
  String get settingsRecurringExpenses;

  /// No description provided for @settingsRecurringExpensesDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage subscriptions'**
  String get settingsRecurringExpensesDesc;

  /// No description provided for @settingsEncryption.
  ///
  /// In en, this message translates to:
  /// **'End-to-End Encryption'**
  String get settingsEncryption;

  /// No description provided for @settingsEncryptionDesc.
  ///
  /// In en, this message translates to:
  /// **'AES-256-GCM • Keychain'**
  String get settingsEncryptionDesc;

  /// No description provided for @settingsCreateBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Save all data to a file'**
  String get settingsCreateBackupDesc;

  /// No description provided for @settingsRestoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get settingsRestoreBackup;

  /// No description provided for @settingsRestoreBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Import data from a backup file'**
  String get settingsRestoreBackupDesc;

  /// No description provided for @settingsBiometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication not available on this device'**
  String get settingsBiometricNotAvailable;

  /// No description provided for @settingsBiometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication enabled. Activate \"App Lock\" to protect your app.'**
  String get settingsBiometricEnabled;

  /// No description provided for @settingsBiometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication and app lock disabled'**
  String get settingsBiometricDisabled;

  /// No description provided for @settingsAppLockEnabled.
  ///
  /// In en, this message translates to:
  /// **'App lock enabled - app is now locked. Authenticate to continue.'**
  String get settingsAppLockEnabled;

  /// No description provided for @settingsAppLockDisabled.
  ///
  /// In en, this message translates to:
  /// **'App lock disabled'**
  String get settingsAppLockDisabled;

  /// No description provided for @settingsAutoLockTimeout.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock Timeout'**
  String get settingsAutoLockTimeout;

  /// No description provided for @settingsAutoLockSet.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock set to {duration}'**
  String settingsAutoLockSet(String duration);

  /// No description provided for @settingsSubscriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Subscription Details'**
  String get settingsSubscriptionDetails;

  /// No description provided for @settingsExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String settingsExpires(String date);

  /// No description provided for @settingsViewPlans.
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get settingsViewPlans;

  /// No description provided for @settingsForceRefresh.
  ///
  /// In en, this message translates to:
  /// **'Force Refresh'**
  String get settingsForceRefresh;

  /// No description provided for @settingsSyncingTier.
  ///
  /// In en, this message translates to:
  /// **'Syncing tier from database...'**
  String get settingsSyncingTier;

  /// No description provided for @settingsTierSynced.
  ///
  /// In en, this message translates to:
  /// **'✅ Tier synced! Restart if needed.'**
  String get settingsTierSynced;

  /// No description provided for @settingsCustomThemes.
  ///
  /// In en, this message translates to:
  /// **'Custom Themes'**
  String get settingsCustomThemes;

  /// No description provided for @settingsUpgradeToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro to unlock:'**
  String get settingsUpgradeToUnlock;

  /// No description provided for @settingsMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get settingsMaybeLater;

  /// No description provided for @settingsUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get settingsUpgrade;

  /// No description provided for @settingsPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get settingsPro;

  /// No description provided for @settingsChangeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Change Currency & Migrate Data?'**
  String get settingsChangeCurrency;

  /// No description provided for @settingsJustChange.
  ///
  /// In en, this message translates to:
  /// **'Just Change'**
  String get settingsJustChange;

  /// No description provided for @settingsConvertData.
  ///
  /// In en, this message translates to:
  /// **'Convert Data'**
  String get settingsConvertData;

  /// No description provided for @settingsUpdatingCurrency.
  ///
  /// In en, this message translates to:
  /// **'Updating currency...'**
  String get settingsUpdatingCurrency;

  /// No description provided for @settingsCurrencyUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update currency: {error}'**
  String settingsCurrencyUpdateFailed(String error);

  /// No description provided for @settingsConvertingData.
  ///
  /// In en, this message translates to:
  /// **'Converting data...'**
  String get settingsConvertingData;

  /// No description provided for @settingsConversionComplete.
  ///
  /// In en, this message translates to:
  /// **'Conversion Complete!'**
  String get settingsConversionComplete;

  /// No description provided for @settingsConversionSummary.
  ///
  /// In en, this message translates to:
  /// **'Successfully converted your data from {fromCurrency} to {toCurrency}'**
  String settingsConversionSummary(String fromCurrency, String toCurrency);

  /// No description provided for @settingsBudgetsConverted.
  ///
  /// In en, this message translates to:
  /// **'  • {count} budget{plural}'**
  String settingsBudgetsConverted(int count, String plural);

  /// No description provided for @settingsExpensesConverted.
  ///
  /// In en, this message translates to:
  /// **'  • {count} expense{plural}'**
  String settingsExpensesConverted(int count, String plural);

  /// No description provided for @settingsAccountsConverted.
  ///
  /// In en, this message translates to:
  /// **'  • {count} account{plural}'**
  String settingsAccountsConverted(int count, String plural);

  /// No description provided for @settingsCategoriesConverted.
  ///
  /// In en, this message translates to:
  /// **'  • {count} categor{plural}'**
  String settingsCategoriesConverted(int count, String plural);

  /// No description provided for @settingsRecurringConverted.
  ///
  /// In en, this message translates to:
  /// **'  • {count} recurring expense{plural}'**
  String settingsRecurringConverted(int count, String plural);

  /// No description provided for @settingsGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get settingsGotIt;

  /// No description provided for @settingsConversionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to convert currency. Please try again.'**
  String get settingsConversionFailedMessage;

  /// No description provided for @settingsConversionSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversion Summary:'**
  String get settingsConversionSummaryTitle;

  /// No description provided for @settingsConversionSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'All values have been updated using real-time exchange rates. Your data has been synced to the cloud.'**
  String get settingsConversionSuccessMessage;

  /// No description provided for @settingsExchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate: 1 {fromCurrency} = {rate} {toCurrency}'**
  String settingsExchangeRate(
    Object fromCurrency,
    Object rate,
    Object toCurrency,
  );

  /// No description provided for @settingsTotalItemsConverted.
  ///
  /// In en, this message translates to:
  /// **'Total: {count} items converted'**
  String settingsTotalItemsConverted(Object count);

  /// No description provided for @settingsConvertedBudgets.
  ///
  /// In en, this message translates to:
  /// **'  • {count} budget{count, plural, =1{} other{s}}'**
  String settingsConvertedBudgets(num count);

  /// No description provided for @settingsConvertedExpenses.
  ///
  /// In en, this message translates to:
  /// **'  • {count} expense{count, plural, =1{} other{s}}'**
  String settingsConvertedExpenses(num count);

  /// No description provided for @settingsConvertedAccounts.
  ///
  /// In en, this message translates to:
  /// **'  • {count} account{count, plural, =1{} other{s}}'**
  String settingsConvertedAccounts(num count);

  /// No description provided for @settingsConvertedCategories.
  ///
  /// In en, this message translates to:
  /// **'  • {count} categor{count, plural, =1{y} other{ies}}'**
  String settingsConvertedCategories(num count);

  /// No description provided for @settingsConvertedRecurringExpenses.
  ///
  /// In en, this message translates to:
  /// **'  • {count} recurring expense{count, plural, =1{} other{s}}'**
  String settingsConvertedRecurringExpenses(num count);

  /// No description provided for @reportsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get reportsViewAll;

  /// No description provided for @reportsNoRecentExpenses.
  ///
  /// In en, this message translates to:
  /// **'No Recent Expenses'**
  String get reportsNoRecentExpenses;

  /// No description provided for @reportsNoRecentExpensesDesc.
  ///
  /// In en, this message translates to:
  /// **'Your recent expenses will appear here'**
  String get reportsNoRecentExpensesDesc;

  /// No description provided for @reportsFailedToLoadBudgets.
  ///
  /// In en, this message translates to:
  /// **'Failed to load budgets'**
  String get reportsFailedToLoadBudgets;

  /// No description provided for @reportsFailedToLoadExpenses.
  ///
  /// In en, this message translates to:
  /// **'Failed to load expenses'**
  String get reportsFailedToLoadExpenses;

  /// No description provided for @reportsMoreBudgets.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more budgets'**
  String reportsMoreBudgets(Object count);

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyPolicyDesc.
  ///
  /// In en, this message translates to:
  /// **'GDPR compliant data handling'**
  String get settingsPrivacyPolicyDesc;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsTermsOfServiceDesc.
  ///
  /// In en, this message translates to:
  /// **'Terms & conditions'**
  String get settingsTermsOfServiceDesc;

  /// No description provided for @commonGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// No description provided for @commonMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get commonMaybeLater;

  /// No description provided for @commonUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get commonUpgrade;

  /// No description provided for @settingsAccentColorDesc.
  ///
  /// In en, this message translates to:
  /// **'Default theme • Upgrade for more themes'**
  String get settingsAccentColorDesc;

  /// No description provided for @settingsThemeUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Themes'**
  String get settingsThemeUpgradeTitle;

  /// No description provided for @settingsThemeUpgradeDesc.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro to unlock:'**
  String get settingsThemeUpgradeDesc;

  /// No description provided for @settingsProPlus.
  ///
  /// In en, this message translates to:
  /// **'Pro+'**
  String get settingsProPlus;

  /// No description provided for @settingsProPlusPlan.
  ///
  /// In en, this message translates to:
  /// **'Pro Plus Plan'**
  String get settingsProPlusPlan;

  /// No description provided for @settingsManageSubDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your subscription or check upgrade options.'**
  String get settingsManageSubDesc;

  /// No description provided for @settingsTierIssue.
  ///
  /// In en, this message translates to:
  /// **'Tier Not Recognized?'**
  String get settingsTierIssue;

  /// No description provided for @settingsTierIssueDesc.
  ///
  /// In en, this message translates to:
  /// **'If you have a paid subscription but see \"Free\" tier, check docs/FIX_PRO_PLUS_TIER.md for SQL fix.'**
  String get settingsTierIssueDesc;

  /// No description provided for @settingsExperienceMode.
  ///
  /// In en, this message translates to:
  /// **'Experience Mode'**
  String get settingsExperienceMode;

  /// No description provided for @settingsProMode.
  ///
  /// In en, this message translates to:
  /// **'Pro Mode • Full features'**
  String get settingsProMode;

  /// No description provided for @settingsLiteMode.
  ///
  /// In en, this message translates to:
  /// **'Lite Mode • Simplified view'**
  String get settingsLiteMode;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get profileDisplayName;

  /// No description provided for @profileEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get profileEnterName;

  /// No description provided for @profileSharingNote.
  ///
  /// In en, this message translates to:
  /// **'Shown when sharing budgets'**
  String get profileSharingNote;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get profileUpdateError;

  /// No description provided for @profileSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'All data synced'**
  String get profileSyncStatus;

  /// No description provided for @welcomeMessage_1.
  ///
  /// In en, this message translates to:
  /// **'Ready to take control of your finances?'**
  String get welcomeMessage_1;

  /// No description provided for @welcomeMessage_2.
  ///
  /// In en, this message translates to:
  /// **'Small savings add up to big dreams.'**
  String get welcomeMessage_2;

  /// No description provided for @welcomeMessage_3.
  ///
  /// In en, this message translates to:
  /// **'Track every penny, own every dollar.'**
  String get welcomeMessage_3;

  /// No description provided for @welcomeMessage_4.
  ///
  /// In en, this message translates to:
  /// **'Financial freedom starts today.'**
  String get welcomeMessage_4;

  /// No description provided for @welcomeMessage_5.
  ///
  /// In en, this message translates to:
  /// **'You’re doing great with your budget!'**
  String get welcomeMessage_5;

  /// No description provided for @welcomeMessage_6.
  ///
  /// In en, this message translates to:
  /// **'Every expense tracked is a step forward.'**
  String get welcomeMessage_6;

  /// No description provided for @welcomeMessage_7.
  ///
  /// In en, this message translates to:
  /// **'Consistency is key to wealth.'**
  String get welcomeMessage_7;

  /// No description provided for @welcomeMessage_8.
  ///
  /// In en, this message translates to:
  /// **'Your future self will thank you.'**
  String get welcomeMessage_8;

  /// No description provided for @welcomeMessage_9.
  ///
  /// In en, this message translates to:
  /// **'Smart spending leads to better living.'**
  String get welcomeMessage_9;

  /// No description provided for @welcomeMessage_10.
  ///
  /// In en, this message translates to:
  /// **'Let’s make your money work for you.'**
  String get welcomeMessage_10;

  /// No description provided for @welcomeMessage_11.
  ///
  /// In en, this message translates to:
  /// **'Reviewing your goals today?'**
  String get welcomeMessage_11;

  /// No description provided for @welcomeMessage_12.
  ///
  /// In en, this message translates to:
  /// **'Keep up the momentum!'**
  String get welcomeMessage_12;

  /// No description provided for @welcomeMessage_13.
  ///
  /// In en, this message translates to:
  /// **'A budget is telling your money where to go.'**
  String get welcomeMessage_13;

  /// No description provided for @welcomeMessage_14.
  ///
  /// In en, this message translates to:
  /// **'Stay focused on your financial goals.'**
  String get welcomeMessage_14;

  /// No description provided for @welcomeMessage_15.
  ///
  /// In en, this message translates to:
  /// **'Investing in yourself pays the best interest.'**
  String get welcomeMessage_15;

  /// No description provided for @welcomeMessage_16.
  ///
  /// In en, this message translates to:
  /// **'Building wealth takes time and patience.'**
  String get welcomeMessage_16;

  /// No description provided for @welcomeMessage_17.
  ///
  /// In en, this message translates to:
  /// **'Don’t just save what is left, spend what is left after saving.'**
  String get welcomeMessage_17;

  /// No description provided for @welcomeMessage_18.
  ///
  /// In en, this message translates to:
  /// **'Money is a tool. Use it wisely.'**
  String get welcomeMessage_18;

  /// No description provided for @welcomeMessage_19.
  ///
  /// In en, this message translates to:
  /// **'Plan your work, work your plan.'**
  String get welcomeMessage_19;

  /// No description provided for @welcomeMessage_20.
  ///
  /// In en, this message translates to:
  /// **'Success is the sum of small efforts.'**
  String get welcomeMessage_20;

  /// No description provided for @closeAppDoubleTap.
  ///
  /// In en, this message translates to:
  /// **'Tap back again to exit'**
  String get closeAppDoubleTap;

  /// No description provided for @accentColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Accent Color'**
  String get accentColorTitle;

  /// No description provided for @accentColorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personalize your app with your favorite color'**
  String get accentColorSubtitle;

  /// No description provided for @accentColorTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get accentColorTheme;

  /// No description provided for @accentColorCurrently.
  ///
  /// In en, this message translates to:
  /// **'Currently: {name}'**
  String accentColorCurrently(String name);

  /// No description provided for @settingsDataSync.
  ///
  /// In en, this message translates to:
  /// **'Data & Sync'**
  String get settingsDataSync;

  /// No description provided for @settingsCloudSyncFreeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro to enable cloud sync'**
  String get settingsCloudSyncFreeSubtitle;

  /// No description provided for @settingsCloudSyncEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Syncing with secure cloud'**
  String get settingsCloudSyncEnabledSubtitle;

  /// No description provided for @settingsCloudSyncLocalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local only'**
  String get settingsCloudSyncLocalSubtitle;

  /// No description provided for @settingsBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get settingsBackupRestore;

  /// No description provided for @settingsBackupRestoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Create or restore from backup'**
  String get settingsBackupRestoreDesc;

  /// No description provided for @settingsRealtimeSyncProFeature.
  ///
  /// In en, this message translates to:
  /// **'Pro Feature'**
  String get settingsRealtimeSyncProFeature;

  /// No description provided for @settingsConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get settingsConnecting;

  /// No description provided for @settingsDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get settingsDisconnected;

  /// No description provided for @settingsConflictsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} conflicts found'**
  String settingsConflictsFound(int count);

  /// No description provided for @settingsEncryptionChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get settingsEncryptionChecking;

  /// No description provided for @settingsEncryptionEnabled.
  ///
  /// In en, this message translates to:
  /// **'AES-256-GCM • Keychain'**
  String get settingsEncryptionEnabled;

  /// No description provided for @settingsEncryptionNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Not initialized'**
  String get settingsEncryptionNotInitialized;

  /// No description provided for @settingsBiometricEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{type} enabled'**
  String settingsBiometricEnabledSubtitle(String type);

  /// No description provided for @settingsBiometricDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protect app with {type}'**
  String settingsBiometricDisabledSubtitle(String type);

  /// No description provided for @settingsAppLockEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require authentication on app start'**
  String get settingsAppLockEnabledSubtitle;

  /// No description provided for @settingsAppLockDisabledSubtitleBiometric.
  ///
  /// In en, this message translates to:
  /// **'Lock app when reopened'**
  String get settingsAppLockDisabledSubtitleBiometric;

  /// No description provided for @settingsAppLockDisabledSubtitleNoBiometric.
  ///
  /// In en, this message translates to:
  /// **'Enable biometric first'**
  String get settingsAppLockDisabledSubtitleNoBiometric;

  /// No description provided for @settingsAutoLockImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get settingsAutoLockImmediately;

  /// No description provided for @settingsBiometricAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to enable biometric lock'**
  String get settingsBiometricAuthReason;

  /// No description provided for @settingsChangeCurrencyMigrateTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Currency & Migrate Data?'**
  String get settingsChangeCurrencyMigrateTitle;

  /// No description provided for @settingsChangeCurrencyMigrateContent.
  ///
  /// In en, this message translates to:
  /// **'You are changing from {oldCurrency} to {newCurrency}.\\n\\nDo you want to convert all your existing budgets, expenses, and accounts to {newCurrency} using live exchange rates?\\n\\nCalculated values might slightly differ due to rounding.'**
  String settingsChangeCurrencyMigrateContent(
    String oldCurrency,
    String newCurrency,
  );

  /// No description provided for @settingsChangeCurrencyJustChange.
  ///
  /// In en, this message translates to:
  /// **'Just Change'**
  String get settingsChangeCurrencyJustChange;

  /// No description provided for @settingsChangeCurrencyConvertData.
  ///
  /// In en, this message translates to:
  /// **'Convert Data'**
  String get settingsChangeCurrencyConvertData;

  /// No description provided for @settingsCurrencyChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Currency changed to {currency} ({count} budgets updated)'**
  String settingsCurrencyChangedSuccess(String currency, int count);

  /// No description provided for @settingsCurrencyChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Currency change failed: {message}'**
  String settingsCurrencyChangeFailed(String message);

  /// No description provided for @settingsCurrencyUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update currency: {error}'**
  String settingsCurrencyUpdateError(String error);

  /// No description provided for @settingsCloudSyncConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will sync your local data with Supabase cloud.\\n\\nMake sure you\'re signed in to use cloud sync.'**
  String get settingsCloudSyncConfirm;

  /// No description provided for @settingsSyncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sync completed!'**
  String get settingsSyncCompleted;

  /// No description provided for @settingsSyncFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get settingsSyncFailedGeneric;

  /// No description provided for @settingsEncryptionProtectedBy.
  ///
  /// In en, this message translates to:
  /// **'Your data is protected by:'**
  String get settingsEncryptionProtectedBy;

  /// No description provided for @settingsEncryptionAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'✅ Algorithm: {algorithm}'**
  String settingsEncryptionAlgorithm(String algorithm);

  /// No description provided for @settingsEncryptionKeysStored.
  ///
  /// In en, this message translates to:
  /// **'✅ Keys stored in device Keychain/Keystore'**
  String get settingsEncryptionKeysStored;

  /// No description provided for @settingsEncryptionEncryptedBeforeSync.
  ///
  /// In en, this message translates to:
  /// **'✅ Encrypted before cloud sync'**
  String get settingsEncryptionEncryptedBeforeSync;

  /// No description provided for @settingsEncryptionOnlyYouAccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Only you have access to your keys'**
  String get settingsEncryptionOnlyYouAccess;

  /// No description provided for @settingsEncryptionKeyFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Key fingerprint: {fingerprint}'**
  String settingsEncryptionKeyFingerprint(String fingerprint);

  /// No description provided for @settingsEncryptionKeysCreated.
  ///
  /// In en, this message translates to:
  /// **'Keys created: {date}'**
  String settingsEncryptionKeysCreated(String date);

  /// No description provided for @settingsEncryptionKeysNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Encryption keys not initialized.'**
  String get settingsEncryptionKeysNotInitialized;

  /// No description provided for @settingsEncryptionKeysGeneratedOnFirstSync.
  ///
  /// In en, this message translates to:
  /// **'Keys will be generated on first sync.'**
  String get settingsEncryptionKeysGeneratedOnFirstSync;

  /// No description provided for @settingsChooseExportFormat.
  ///
  /// In en, this message translates to:
  /// **'Choose export format'**
  String get settingsChooseExportFormat;

  /// No description provided for @legalUserAgreementTitle.
  ///
  /// In en, this message translates to:
  /// **'User Agreement'**
  String get legalUserAgreementTitle;

  /// No description provided for @legalTermsOfServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legalTermsOfServiceTitle;

  /// No description provided for @legalPrivacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacyPolicyTitle;

  /// No description provided for @legalReadToBottom.
  ///
  /// In en, this message translates to:
  /// **'Please read to the end to enable acceptance.'**
  String get legalReadToBottom;

  /// No description provided for @legalReviewTerms.
  ///
  /// In en, this message translates to:
  /// **'Please review the terms below.'**
  String get legalReviewTerms;

  /// No description provided for @legalIHaveRead.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Terms of Service & Privacy Policy.'**
  String get legalIHaveRead;

  /// No description provided for @legalScrollToEnable.
  ///
  /// In en, this message translates to:
  /// **'Scroll to the end to enable acceptance.'**
  String get legalScrollToEnable;

  /// No description provided for @legalByContinuing.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you acknowledge and accept these terms.'**
  String get legalByContinuing;

  /// No description provided for @legalAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get legalAccept;

  /// No description provided for @legalDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get legalDecline;

  /// No description provided for @legalReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get legalReadMore;

  /// No description provided for @legalTOSContent.
  ///
  /// In en, this message translates to:
  /// **'# Terms of Service\n\n**Last Updated: December 2025**\n\nWelcome to **CashPilot**. These Terms of Service (\"Terms\") govern your use of the CashPilot mobile application.\n\n### 1. Acceptance of Terms\nBy accessing or using CashPilot, you agree to be bound by these Terms. If you do not agree, you may not use the app.\n\n### 2. User Responsibilities\nYou are responsible for maintaining the confidentiality of your account and for all activities that occur under your account.\n\n### 3. Prohibited Activities\nYou agree not to misuse the app or help anyone else do so.\n\n### 4. Financial Disclaimer\nCashPilot is a financial tracking tool and does not provide financial, tax, or investment advice.\n\n### 5. Limitation of Liability\nCashPilot is provided \"as is\" without any warranties.\n\n### 6. Changes to Terms\nWe may modify these terms at any time. Continued use of the app signifies acceptance of the updated terms.'**
  String get legalTOSContent;

  /// No description provided for @legalPrivacyContent.
  ///
  /// In en, this message translates to:
  /// **'# Privacy Policy\n\n**Last Updated: February 2026**\n\nAt **CashPilot**, we take your privacy seriously. This policy explains how we handle your data.\n\n### 1. Data Collection\nWe collect minimal data necessary to provide our services. Most data is stored locally on your device.\n\n### 2. Encryption\nYour sensitive financial data is encrypted using AES-256 before being stored or synced.\n\n### 3. Data Ownership\nYou own your data. We do not sell your personal information to third parties.\n\n### 4. Cloud Sync\nCloud sync is optional. If enabled, your data is encrypted on your device before being uploaded to our secure servers.\n\n### 5. Open Banking (Nordigen)\nIf you enable Bank Connectivity, you consent to sharing transaction data via Nordigen. This is used solely for budgeting. You can revoke this at any time.\n\n### 6. Your Rights\nYou have the right to access, correct, or delete your data at any time through the app settings.'**
  String get legalPrivacyContent;

  /// No description provided for @settingsExportAsCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get settingsExportAsCsv;

  /// No description provided for @settingsExportCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet compatible format'**
  String get settingsExportCsvSubtitle;

  /// No description provided for @settingsExportAsJson.
  ///
  /// In en, this message translates to:
  /// **'Export as JSON'**
  String get settingsExportAsJson;

  /// No description provided for @settingsExportJsonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For backup and development'**
  String get settingsExportJsonSubtitle;

  /// No description provided for @settingsFreeTierExportLimit.
  ///
  /// In en, this message translates to:
  /// **'Free tier: Last 3 months only'**
  String get settingsFreeTierExportLimit;

  /// No description provided for @settingsUpgradeForUnlimitedExport.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro for unlimited export history'**
  String get settingsUpgradeForUnlimitedExport;

  /// No description provided for @settingsGeneratingExport.
  ///
  /// In en, this message translates to:
  /// **'Generating {format} export...'**
  String settingsGeneratingExport(String format);

  /// No description provided for @settingsExportShareText.
  ///
  /// In en, this message translates to:
  /// **'My CashPilot Data Export'**
  String get settingsExportShareText;

  /// No description provided for @settingsExportShareSubject.
  ///
  /// In en, this message translates to:
  /// **'CashPilot Data Export'**
  String get settingsExportShareSubject;

  /// No description provided for @settingsExportSharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Export shared successfully!'**
  String get settingsExportSharedSuccessfully;

  /// No description provided for @settingsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String settingsExportFailed(String error);

  /// No description provided for @settingsBankConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Bank Connectivity'**
  String get settingsBankConnectivity;

  /// No description provided for @settingsBankConnectivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect your bank accounts to automatically sync transactions.'**
  String get settingsBankConnectivityDesc;

  /// No description provided for @settingsManageConnections.
  ///
  /// In en, this message translates to:
  /// **'Manage Connections'**
  String get settingsManageConnections;

  /// No description provided for @legalPrivacyBankingTitle.
  ///
  /// In en, this message translates to:
  /// **'11. Open Banking & Financial Data Consent'**
  String get legalPrivacyBankingTitle;

  /// No description provided for @legalPrivacyBankingBody.
  ///
  /// In en, this message translates to:
  /// **'When you enable Bank Connectivity, you explicitly consent to CashPilot accessing your transaction history via our regulated partner, Nordigen (a GoCardless company). Your credentials are never stored by us. Data is accessed for the sole purpose of expense tracking and budgeting. You can revoke this consent at any time by disabling the feature or deleting your connections. Access must be re-authorized every 90 days as per PSD2/SCA regulations.'**
  String get legalPrivacyBankingBody;

  /// No description provided for @settingsNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settingsNotConnected;

  /// No description provided for @settingsCloudBackupSignInMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in to enable cloud backup and sync across devices.'**
  String get settingsCloudBackupSignInMessage;

  /// No description provided for @settingsActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Active ✓'**
  String get settingsActiveStatus;

  /// No description provided for @settingsCloudBackupProMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data is automatically syncing to the cloud. All devices stay up-to-date.'**
  String get settingsCloudBackupProMessage;

  /// No description provided for @settingsCloudBackupFreeMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data is saved locally. Upgrade to Pro or Pro+ for automatic cloud backup and multi-device sync.'**
  String get settingsCloudBackupFreeMessage;

  /// No description provided for @settingsBackupStatus.
  ///
  /// In en, this message translates to:
  /// **'Backup Status'**
  String get settingsBackupStatus;

  /// No description provided for @settingsLocalDatabase.
  ///
  /// In en, this message translates to:
  /// **'Local Database'**
  String get settingsLocalDatabase;

  /// No description provided for @settingsForceSyncingToCloud.
  ///
  /// In en, this message translates to:
  /// **'Force syncing to cloud...'**
  String get settingsForceSyncingToCloud;

  /// No description provided for @settingsSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get settingsSignIn;

  /// No description provided for @settingsRestoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get settingsRestoreFromBackup;

  /// No description provided for @settingsRestoreFromBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Import data from a backup file'**
  String get settingsRestoreFromBackupDesc;

  /// No description provided for @settingsRateAppTitle.
  ///
  /// In en, this message translates to:
  /// **'❤️ Rate CashPilot'**
  String get settingsRateAppTitle;

  /// No description provided for @settingsRateAppContent.
  ///
  /// In en, this message translates to:
  /// **'Thank you for using CashPilot!\\n\\nStore link coming soon.\\n\\nYour feedback helps us improve!'**
  String get settingsRateAppContent;

  /// No description provided for @settingsRateAppThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you! ❤️'**
  String get settingsRateAppThanks;

  /// No description provided for @settingsRateNow.
  ///
  /// In en, this message translates to:
  /// **'Rate Now'**
  String get settingsRateNow;

  /// No description provided for @settingsSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get settingsSignOutConfirm;

  /// No description provided for @privacyDataCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Data Collection'**
  String get privacyDataCollectionTitle;

  /// No description provided for @privacyDataCollectionBody.
  ///
  /// In en, this message translates to:
  /// **'We only collect data you provide directly (budgets, expenses, categories). We do not track your location or personal habits.'**
  String get privacyDataCollectionBody;

  /// No description provided for @privacyDataStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Data Storage'**
  String get privacyDataStorageTitle;

  /// No description provided for @privacyDataStorageBody.
  ///
  /// In en, this message translates to:
  /// **'Data is stored locally on your device. If you sign in, data is encrypted and synced to our secure cloud (Supabase).'**
  String get privacyDataStorageBody;

  /// No description provided for @privacySecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Security'**
  String get privacySecurityTitle;

  /// No description provided for @privacySecurityBody.
  ///
  /// In en, this message translates to:
  /// **'All cloud data is encrypted using AES-256 standard. Only you can access your data.'**
  String get privacySecurityBody;

  /// No description provided for @privacyYourRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Your Rights'**
  String get privacyYourRightsTitle;

  /// No description provided for @privacyYourRightsBody.
  ///
  /// In en, this message translates to:
  /// **'You have the right to access, export, and permanently delete your data at any time via Settings.'**
  String get privacyYourRightsBody;

  /// No description provided for @termsAcceptanceTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance'**
  String get termsAcceptanceTitle;

  /// No description provided for @termsAcceptanceBody.
  ///
  /// In en, this message translates to:
  /// **'By using CashPilot, you agree to these terms.'**
  String get termsAcceptanceBody;

  /// No description provided for @themeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Themes'**
  String get themeCustom;

  /// No description provided for @themeUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro to unlock:'**
  String get themeUpgradeTitle;

  /// No description provided for @themeFeatureAccent.
  ///
  /// In en, this message translates to:
  /// **'12+ accent color options'**
  String get themeFeatureAccent;

  /// No description provided for @themeFeaturePrimary.
  ///
  /// In en, this message translates to:
  /// **'Custom primary colors'**
  String get themeFeaturePrimary;

  /// No description provided for @themeFeatureDarkLight.
  ///
  /// In en, this message translates to:
  /// **'Dark & light mode variants'**
  String get themeFeatureDarkLight;

  /// No description provided for @themeFeatureGradient.
  ///
  /// In en, this message translates to:
  /// **'Premium gradient themes'**
  String get themeFeatureGradient;

  /// No description provided for @subProPlus.
  ///
  /// In en, this message translates to:
  /// **'Pro Plus Plan'**
  String get subProPlus;

  /// No description provided for @subProPlusTag.
  ///
  /// In en, this message translates to:
  /// **'Pro+'**
  String get subProPlusTag;

  /// No description provided for @subDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Details'**
  String get subDetailsTitle;

  /// No description provided for @subCurrentTier.
  ///
  /// In en, this message translates to:
  /// **'Current Tier: {tier}'**
  String subCurrentTier(String tier);

  /// No description provided for @subExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String subExpires(String date);

  /// No description provided for @subManageDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your subscription or check upgrade options.'**
  String get subManageDesc;

  /// No description provided for @subViewPlans.
  ///
  /// In en, this message translates to:
  /// **'View Plans & Upgrades'**
  String get subViewPlans;

  /// No description provided for @subTierIssue.
  ///
  /// In en, this message translates to:
  /// **'Tier Not Recognized?'**
  String get subTierIssue;

  /// No description provided for @subTierIssueDesc.
  ///
  /// In en, this message translates to:
  /// **'If you have a paid subscription but see \"Free\" tier, check docs/FIX_PRO_PLUS_TIER.md for SQL fix.'**
  String get subTierIssueDesc;

  /// No description provided for @subProLimit.
  ///
  /// In en, this message translates to:
  /// **'Pro Limit'**
  String get subProLimit;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get authWelcome;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authTaglineLogin.
  ///
  /// In en, this message translates to:
  /// **'Securely manage your finances'**
  String get authTaglineLogin;

  /// No description provided for @authTaglineSignup.
  ///
  /// In en, this message translates to:
  /// **'Start your smart money journey'**
  String get authTaglineSignup;

  /// No description provided for @authFeatures.
  ///
  /// In en, this message translates to:
  /// **'Secure • Offline-first • Private'**
  String get authFeatures;

  /// No description provided for @authDataEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted and never shared.'**
  String get authDataEncrypted;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordLength;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account? '**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Have an account? '**
  String get authHaveAccount;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// No description provided for @authAgree.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get authAgree;

  /// No description provided for @authPolicy.
  ///
  /// In en, this message translates to:
  /// **'User Agreement & Privacy Policy'**
  String get authPolicy;

  /// No description provided for @authBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to access CashPilot'**
  String get authBiometricReason;

  /// No description provided for @conflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Conflicts'**
  String get conflictTitle;

  /// No description provided for @conflictRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get conflictRefresh;

  /// No description provided for @conflictNone.
  ///
  /// In en, this message translates to:
  /// **'No Conflicts'**
  String get conflictNone;

  /// No description provided for @conflictAllGood.
  ///
  /// In en, this message translates to:
  /// **'All your data is in sync'**
  String get conflictAllGood;

  /// No description provided for @conflictCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 conflict needs resolution} other{{count} conflicts need resolution}}'**
  String conflictCount(int count);

  /// No description provided for @conflictKeepLocal.
  ///
  /// In en, this message translates to:
  /// **'Keep Local'**
  String get conflictKeepLocal;

  /// No description provided for @conflictKeepCloud.
  ///
  /// In en, this message translates to:
  /// **'Keep Cloud'**
  String get conflictKeepCloud;

  /// No description provided for @conflictKeepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep Both'**
  String get conflictKeepBoth;

  /// No description provided for @conflictExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get conflictExpense;

  /// No description provided for @conflictBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get conflictBudget;

  /// No description provided for @conflictAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get conflictAccount;

  /// No description provided for @restoreSelectFileDesc.
  ///
  /// In en, this message translates to:
  /// **'Select a CashPilot backup file (.json)'**
  String get restoreSelectFileDesc;

  /// No description provided for @restoreChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get restoreChooseFile;

  /// No description provided for @restoreLabelCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get restoreLabelCreated;

  /// No description provided for @restoreLabelAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get restoreLabelAppVersion;

  /// No description provided for @restoreLabelSchema.
  ///
  /// In en, this message translates to:
  /// **'Schema Version'**
  String get restoreLabelSchema;

  /// No description provided for @restoreModeMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get restoreModeMerge;

  /// No description provided for @restoreModeMergeDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep existing data, add/update from backup'**
  String get restoreModeMergeDesc;

  /// No description provided for @restoreModeReplaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Wipe current data and restore from backup'**
  String get restoreModeReplaceDesc;

  /// No description provided for @restoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreAction;

  /// No description provided for @restoreActionProgress.
  ///
  /// In en, this message translates to:
  /// **'Restoring...'**
  String get restoreActionProgress;

  /// No description provided for @restoreAccountsCount.
  ///
  /// In en, this message translates to:
  /// **'• {count} accounts'**
  String restoreAccountsCount(int count);

  /// No description provided for @restoreExpensesCount.
  ///
  /// In en, this message translates to:
  /// **'• {count} expenses'**
  String restoreExpensesCount(int count);

  /// No description provided for @restoreWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings:'**
  String get restoreWarnings;

  /// No description provided for @budgetsFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get budgetsFamily;

  /// No description provided for @budgetsNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active budgets'**
  String get budgetsNoActive;

  /// No description provided for @budgetsNoActiveMsg.
  ///
  /// In en, this message translates to:
  /// **'Create a budget to start tracking your spending.'**
  String get budgetsNoActiveMsg;

  /// No description provided for @budgetsNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming budgets'**
  String get budgetsNoUpcoming;

  /// No description provided for @budgetsNoUpcomingMsg.
  ///
  /// In en, this message translates to:
  /// **'Plan ahead by scheduling your next budget.'**
  String get budgetsNoUpcomingMsg;

  /// No description provided for @budgetsNoPast.
  ///
  /// In en, this message translates to:
  /// **'No past budgets'**
  String get budgetsNoPast;

  /// No description provided for @budgetsNoPastMsg.
  ///
  /// In en, this message translates to:
  /// **'Budgets that have ended will appear here for your review.'**
  String get budgetsNoPastMsg;

  /// No description provided for @budgetsNoFamily.
  ///
  /// In en, this message translates to:
  /// **'No family budgets'**
  String get budgetsNoFamily;

  /// No description provided for @budgetsNoFamilyMsg.
  ///
  /// In en, this message translates to:
  /// **'Budgets shared with your family group show up here.'**
  String get budgetsNoFamilyMsg;

  /// No description provided for @budgetsSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule Budget'**
  String get budgetsSchedule;

  /// No description provided for @budgetsCreateShared.
  ///
  /// In en, this message translates to:
  /// **'Create Shared Budget'**
  String get budgetsCreateShared;

  /// No description provided for @budgetsTotalBudget.
  ///
  /// In en, this message translates to:
  /// **'Total Budget'**
  String get budgetsTotalBudget;

  /// No description provided for @budgetsPerDay.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get budgetsPerDay;

  /// No description provided for @budgetsTrackSpending.
  ///
  /// In en, this message translates to:
  /// **'Track your spending in this budget.'**
  String get budgetsTrackSpending;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @dateThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get dateThisWeek;

  /// No description provided for @dateEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get dateEarlier;

  /// No description provided for @categoryNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get categoryNoCategories;

  /// No description provided for @categoryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get categoryAdd;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Category?'**
  String get categoryDeleteTitle;

  /// No description provided for @categoryDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all its sub-categories?'**
  String categoryDeleteMsg(String name);

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" deleted'**
  String categoryDeleted(String name);

  /// No description provided for @categorySubCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sub-categories'**
  String categorySubCount(int count);

  /// No description provided for @categorySpentMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} spent this month'**
  String categorySpentMonth(String amount);

  /// No description provided for @categoryAddSub.
  ///
  /// In en, this message translates to:
  /// **'Add Sub-category'**
  String get categoryAddSub;

  /// No description provided for @categoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get categoryEdit;

  /// No description provided for @categoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryNameLabel;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Groceries'**
  String get categoryNameHint;

  /// No description provided for @categoryIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoryIconLabel;

  /// No description provided for @categoryColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoryColorLabel;

  /// No description provided for @categoryPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get categoryPriorityLabel;

  /// No description provided for @categoryLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget Limit'**
  String get categoryLimitLabel;

  /// No description provided for @categorySaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get categorySaveChanges;

  /// No description provided for @categorySuggestedIcon.
  ///
  /// In en, this message translates to:
  /// **'Suggested icon: {icon}'**
  String categorySuggestedIcon(Object icon);

  /// No description provided for @categoryQuickSelect.
  ///
  /// In en, this message translates to:
  /// **'Quick Select'**
  String get categoryQuickSelect;

  /// No description provided for @categoryPreview.
  ///
  /// In en, this message translates to:
  /// **'Category Preview'**
  String get categoryPreview;

  /// No description provided for @categoryMergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge \"{category}\"'**
  String categoryMergeTitle(Object category);

  /// No description provided for @categoryMergeIntoLabel.
  ///
  /// In en, this message translates to:
  /// **'Merge into'**
  String get categoryMergeIntoLabel;

  /// No description provided for @categoryMergeMsg.
  ///
  /// In en, this message translates to:
  /// **'Select a category to merge into. All expenses will be moved to the new category, and this one will be deleted.'**
  String get categoryMergeMsg;

  /// No description provided for @categoryNoMergeTargets.
  ///
  /// In en, this message translates to:
  /// **'No other categories to merge into'**
  String get categoryNoMergeTargets;

  /// No description provided for @categoryMerging.
  ///
  /// In en, this message translates to:
  /// **'Merging categories...'**
  String get categoryMerging;

  /// No description provided for @categoryMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged into \"{target}\"'**
  String categoryMerged(Object target);

  /// No description provided for @categoryMergeFailed.
  ///
  /// In en, this message translates to:
  /// **'Merge failed: {error}'**
  String categoryMergeFailed(Object error);

  /// No description provided for @categorySelect.
  ///
  /// In en, this message translates to:
  /// **'Select Categories'**
  String get categorySelect;

  /// No description provided for @categoryModify.
  ///
  /// In en, this message translates to:
  /// **'Modify Selection'**
  String get categoryModify;

  /// No description provided for @categoryNoteExisting.
  ///
  /// In en, this message translates to:
  /// **'Note: Existing categories are managed separately.'**
  String get categoryNoteExisting;

  /// No description provided for @formTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Budget Name'**
  String get formTitleHint;

  /// No description provided for @formAmountHint.
  ///
  /// In en, this message translates to:
  /// **'2000'**
  String get formAmountHint;

  /// No description provided for @formRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get formRequired;

  /// No description provided for @formNotes.
  ///
  /// In en, this message translates to:
  /// **'Optional notes...'**
  String get formNotes;

  /// No description provided for @expensesRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring Expenses'**
  String get expensesRecurring;

  /// No description provided for @formTypeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get formTypeMonth;

  /// No description provided for @formTypeWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get formTypeWeek;

  /// No description provided for @formTypeYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get formTypeYear;

  /// No description provided for @formTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get formTypeCustom;

  /// No description provided for @formSectionCategories.
  ///
  /// In en, this message translates to:
  /// **'CATEGORIES'**
  String get formSectionCategories;

  /// No description provided for @formSectionAdvanced.
  ///
  /// In en, this message translates to:
  /// **'ADVANCED'**
  String get formSectionAdvanced;

  /// No description provided for @authSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again'**
  String get authSessionExpired;

  /// No description provided for @authBiometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Please login first to enable biometric authentication'**
  String get authBiometricLogin;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authSignInBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Biometrics'**
  String get authSignInBiometrics;

  /// No description provided for @authGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get authGoogle;

  /// No description provided for @authApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get authApple;

  /// No description provided for @authGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get authGuest;

  /// No description provided for @familySharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Sharing'**
  String get familySharingTitle;

  /// No description provided for @familyUpgradePrompt.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro Plus'**
  String get familyUpgradePrompt;

  /// No description provided for @familyHintBudget.
  ///
  /// In en, this message translates to:
  /// **'Choose a budget'**
  String get familyHintBudget;

  /// No description provided for @familyHintName.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get familyHintName;

  /// No description provided for @familyHintEmail.
  ///
  /// In en, this message translates to:
  /// **'family@example.com'**
  String get familyHintEmail;

  /// No description provided for @familyLabelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get familyLabelEmail;

  /// No description provided for @familyLabelAccess.
  ///
  /// In en, this message translates to:
  /// **'Access Level'**
  String get familyLabelAccess;

  /// No description provided for @familyTooltipInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite member'**
  String get familyTooltipInvite;

  /// No description provided for @familyPendingInvites.
  ///
  /// In en, this message translates to:
  /// **'Pending Invites'**
  String get familyPendingInvites;

  /// No description provided for @familyErrorLoadingInvites.
  ///
  /// In en, this message translates to:
  /// **'Error loading invites'**
  String get familyErrorLoadingInvites;

  /// No description provided for @familyInviteAccepted.
  ///
  /// In en, this message translates to:
  /// **'Invite accepted! You can now access this budget.'**
  String get familyInviteAccepted;

  /// No description provided for @familyInviteError.
  ///
  /// In en, this message translates to:
  /// **'Error accepting invite: {error}'**
  String familyInviteError(String error);

  /// No description provided for @familyDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline Invite?'**
  String get familyDeclineTitle;

  /// No description provided for @familyDeclineBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to decline this invitation? This cannot be undone.'**
  String get familyDeclineBody;

  /// No description provided for @familyDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get familyDecline;

  /// No description provided for @familyAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get familyAccept;

  /// No description provided for @budgetHintName.
  ///
  /// In en, this message translates to:
  /// **'Budget Name'**
  String get budgetHintName;

  /// No description provided for @budgetHintAmount.
  ///
  /// In en, this message translates to:
  /// **'2000'**
  String get budgetHintAmount;

  /// No description provided for @budgetHintNotes.
  ///
  /// In en, this message translates to:
  /// **'Optional notes...'**
  String get budgetHintNotes;

  /// No description provided for @budgetLabelMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get budgetLabelMonth;

  /// No description provided for @budgetLabelWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get budgetLabelWeek;

  /// No description provided for @budgetLabelYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get budgetLabelYear;

  /// No description provided for @budgetLabelCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get budgetLabelCustom;

  /// No description provided for @budgetTooltipOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get budgetTooltipOptions;

  /// No description provided for @budgetTooltipClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get budgetTooltipClear;

  /// No description provided for @budgetTooltipBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get budgetTooltipBack;

  /// No description provided for @budgetExportMessage.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} budgets from CashPilot'**
  String budgetExportMessage(int count);

  /// No description provided for @catHintExamples.
  ///
  /// In en, this message translates to:
  /// **'e.g., Groceries, Coffee, Transport'**
  String get catHintExamples;

  /// No description provided for @catLabelName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get catLabelName;

  /// No description provided for @catLabelMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge into'**
  String get catLabelMerge;

  /// No description provided for @catMergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge \"{name}\"'**
  String catMergeTitle(String name);

  /// No description provided for @savingsGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get savingsGoalsTitle;

  /// No description provided for @savingsMigrationMessage.
  ///
  /// In en, this message translates to:
  /// **'Feature temporarily disabled during schema migration'**
  String get savingsMigrationMessage;

  /// No description provided for @syncConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'{type} Conflict'**
  String syncConflictTitle(String type);

  /// No description provided for @syncConflictSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detected {time}'**
  String syncConflictSubtitle(String time);

  /// No description provided for @syncChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes:'**
  String get syncChanges;

  /// No description provided for @syncResolution.
  ///
  /// In en, this message translates to:
  /// **'Choose resolution:'**
  String get syncResolution;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreTitle;

  /// No description provided for @restoreStepSelect.
  ///
  /// In en, this message translates to:
  /// **'1. Select Backup File'**
  String get restoreStepSelect;

  /// No description provided for @restoreStepPreview.
  ///
  /// In en, this message translates to:
  /// **'2. Backup Preview'**
  String get restoreStepPreview;

  /// No description provided for @restoreDataSummary.
  ///
  /// In en, this message translates to:
  /// **'Data Summary:'**
  String get restoreDataSummary;

  /// No description provided for @restoreIntegrity.
  ///
  /// In en, this message translates to:
  /// **'Checksum verified - file integrity confirmed'**
  String get restoreIntegrity;

  /// No description provided for @restoreStepMode.
  ///
  /// In en, this message translates to:
  /// **'3. Restore Mode'**
  String get restoreStepMode;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace All Data?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to replace all current data with this backup?'**
  String get restoreConfirmBody;

  /// No description provided for @restoreReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace All'**
  String get restoreReplaceAll;

  /// No description provided for @restoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restore Complete'**
  String get restoreComplete;

  /// No description provided for @restoreSuccessDetail.
  ///
  /// In en, this message translates to:
  /// **'Successfully restored:'**
  String get restoreSuccessDetail;

  /// No description provided for @restoreBudgetsCount.
  ///
  /// In en, this message translates to:
  /// **'• {count} budgets'**
  String restoreBudgetsCount(int count);

  /// No description provided for @chartSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get chartSpent;

  /// No description provided for @chartMetricTooltip.
  ///
  /// In en, this message translates to:
  /// **'What do these metrics mean?'**
  String get chartMetricTooltip;

  /// No description provided for @chartExportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export report (PDF / CSV)'**
  String get chartExportTooltip;

  /// No description provided for @chartDismissTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss insight'**
  String get chartDismissTooltip;

  /// No description provided for @chartThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get chartThisWeek;

  /// No description provided for @chartProjection.
  ///
  /// In en, this message translates to:
  /// **'Projection'**
  String get chartProjection;

  /// No description provided for @chartMonthEnd.
  ///
  /// In en, this message translates to:
  /// **'Month End'**
  String get chartMonthEnd;

  /// No description provided for @chartLittleWin.
  ///
  /// In en, this message translates to:
  /// **'Little Win'**
  String get chartLittleWin;

  /// No description provided for @chartSubtextRecent.
  ///
  /// In en, this message translates to:
  /// **'Total spent recently.'**
  String get chartSubtextRecent;

  /// No description provided for @chartSubtextProjected.
  ///
  /// In en, this message translates to:
  /// **'Estimated total if you keep this up.'**
  String get chartSubtextProjected;

  /// No description provided for @chartSubtextWin.
  ///
  /// In en, this message translates to:
  /// **'Skipping one treat today keeps you green.'**
  String get chartSubtextWin;

  /// No description provided for @analyticsHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Budget Health Score'**
  String get analyticsHealthScore;

  /// No description provided for @analyticsVelocity.
  ///
  /// In en, this message translates to:
  /// **'Spending velocity tracking'**
  String get analyticsVelocity;

  /// No description provided for @analyticsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category breakdown & trends'**
  String get analyticsBreakdown;

  /// No description provided for @analyticsInsights.
  ///
  /// In en, this message translates to:
  /// **'Personalized smart insights'**
  String get analyticsInsights;

  /// No description provided for @analyticsComparisons.
  ///
  /// In en, this message translates to:
  /// **'Period comparisons'**
  String get analyticsComparisons;

  /// No description provided for @analyticsSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscription detection'**
  String get analyticsSubscriptions;

  /// No description provided for @analyticsUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Advanced Analytics'**
  String get analyticsUnlockTitle;

  /// No description provided for @analyticsUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get analyticsUpgrade;

  /// No description provided for @analyticsPricing.
  ///
  /// In en, this message translates to:
  /// **'Starting at €1.99/month'**
  String get analyticsPricing;

  /// No description provided for @analyticsSectionInsights.
  ///
  /// In en, this message translates to:
  /// **'Smart Insights'**
  String get analyticsSectionInsights;

  /// No description provided for @analyticsSectionPatterns.
  ///
  /// In en, this message translates to:
  /// **'Spending Patterns'**
  String get analyticsSectionPatterns;

  /// No description provided for @analyticsSectionPatternsSub.
  ///
  /// In en, this message translates to:
  /// **'When you spend most'**
  String get analyticsSectionPatternsSub;

  /// No description provided for @analyticsSectionBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Spending Breakdown'**
  String get analyticsSectionBreakdown;

  /// No description provided for @analyticsSectionBreakdownSub.
  ///
  /// In en, this message translates to:
  /// **'Where your money goes'**
  String get analyticsSectionBreakdownSub;

  /// No description provided for @analyticsBurnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track to stay under budget'**
  String get analyticsBurnTrack;

  /// No description provided for @analyticsBurnWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: Projected to exceed budget'**
  String get analyticsBurnWarning;

  /// No description provided for @analyticsBurnFinishUnder.
  ///
  /// In en, this message translates to:
  /// **'You’re likely to finish {amount} under budget'**
  String analyticsBurnFinishUnder(String amount);

  /// No description provided for @analyticsBurnExceed.
  ///
  /// In en, this message translates to:
  /// **'At current pace, you’ll exceed budget by {amount}'**
  String analyticsBurnExceed(String amount);

  /// No description provided for @notifChannelBill.
  ///
  /// In en, this message translates to:
  /// **'Bill Reminders'**
  String get notifChannelBill;

  /// No description provided for @notifChannelBillDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications for upcoming bills and payments'**
  String get notifChannelBillDesc;

  /// No description provided for @notifChannelAlerts.
  ///
  /// In en, this message translates to:
  /// **'General Alerts'**
  String get notifChannelAlerts;

  /// No description provided for @notifChannelAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Important updates and alerts'**
  String get notifChannelAlertsDesc;

  /// No description provided for @notifDueSoon.
  ///
  /// In en, this message translates to:
  /// **'{title} Due Soon'**
  String notifDueSoon(String title);

  /// No description provided for @notifDateToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get notifDateToday;

  /// No description provided for @notifDateTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get notifDateTomorrow;

  /// No description provided for @notifDateFuture.
  ///
  /// In en, this message translates to:
  /// **'in {days} days'**
  String notifDateFuture(int days);

  /// No description provided for @errBankFetch.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch institutions'**
  String get errBankFetch;

  /// No description provided for @errBankPro.
  ///
  /// In en, this message translates to:
  /// **'Bank connectivity requires Pro Plus subscription'**
  String get errBankPro;

  /// No description provided for @errBankInit.
  ///
  /// In en, this message translates to:
  /// **'Failed to initiate connection: {error}'**
  String errBankInit(String error);

  /// No description provided for @errBankSync.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync accounts: {error}'**
  String errBankSync(String error);

  /// No description provided for @errReceiptAuth.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get errReceiptAuth;

  /// No description provided for @errReceiptNotFound.
  ///
  /// In en, this message translates to:
  /// **'Receipt file not found'**
  String get errReceiptNotFound;

  /// No description provided for @errReceiptEmpty.
  ///
  /// In en, this message translates to:
  /// **'Receipt file is empty'**
  String get errReceiptEmpty;

  /// No description provided for @errReceiptTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Receipt file is too large (max 10 MB)'**
  String get errReceiptTooLarge;

  /// No description provided for @errReceiptUrl.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate public URL'**
  String get errReceiptUrl;

  /// No description provided for @errReceiptUpload.
  ///
  /// In en, this message translates to:
  /// **'Receipt upload failed (storage error)'**
  String get errReceiptUpload;

  /// No description provided for @catPizza.
  ///
  /// In en, this message translates to:
  /// **'Pizza'**
  String get catPizza;

  /// No description provided for @catBurger.
  ///
  /// In en, this message translates to:
  /// **'Burger'**
  String get catBurger;

  /// No description provided for @catIcecream.
  ///
  /// In en, this message translates to:
  /// **'Ice Cream'**
  String get catIcecream;

  /// No description provided for @catShipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get catShipping;

  /// No description provided for @catArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get catArt;

  /// No description provided for @catParty.
  ///
  /// In en, this message translates to:
  /// **'Party'**
  String get catParty;

  /// No description provided for @catHaircut.
  ///
  /// In en, this message translates to:
  /// **'Haircut'**
  String get catHaircut;

  /// No description provided for @catSwimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get catSwimming;

  /// No description provided for @catCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud Services'**
  String get catCloud;

  /// No description provided for @catPrinting.
  ///
  /// In en, this message translates to:
  /// **'Printing'**
  String get catPrinting;

  /// No description provided for @catReligious.
  ///
  /// In en, this message translates to:
  /// **'Religious / Zakat'**
  String get catReligious;

  /// No description provided for @catFestivals.
  ///
  /// In en, this message translates to:
  /// **'Festivals & Events'**
  String get catFestivals;

  /// No description provided for @catPublicServices.
  ///
  /// In en, this message translates to:
  /// **'Public Services'**
  String get catPublicServices;

  /// No description provided for @catParkingFees.
  ///
  /// In en, this message translates to:
  /// **'Parking Fees'**
  String get catParkingFees;

  /// No description provided for @catBridgeTolls.
  ///
  /// In en, this message translates to:
  /// **'Bridge Tolls'**
  String get catBridgeTolls;

  /// No description provided for @statusUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get statusUpToDate;

  /// No description provided for @labelUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get labelUse;

  /// No description provided for @labelTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get labelTotal;

  /// No description provided for @labelAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get labelAccepted;

  /// No description provided for @labelEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get labelEdited;

  /// No description provided for @labelRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get labelRejected;

  /// No description provided for @termsLicenseTitle.
  ///
  /// In en, this message translates to:
  /// **'2. License'**
  String get termsLicenseTitle;

  /// No description provided for @termsLicenseBody.
  ///
  /// In en, this message translates to:
  /// **'CashPilot is licensed for personal, non-commercial use.'**
  String get termsLicenseBody;

  /// No description provided for @termsAccuracyTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Accuracy'**
  String get termsAccuracyTitle;

  /// No description provided for @termsAccuracyBody.
  ///
  /// In en, this message translates to:
  /// **'You are responsible for the accuracy of financial data you enter.'**
  String get termsAccuracyBody;

  /// No description provided for @termsDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Disclaimer'**
  String get termsDisclaimerTitle;

  /// No description provided for @termsDisclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'The app is provided \"as is\". We are not responsible for financial decisions made based on this app.'**
  String get termsDisclaimerBody;

  /// No description provided for @settingsConversionFailed.
  ///
  /// In en, this message translates to:
  /// **'Conversion Failed'**
  String get settingsConversionFailed;

  /// No description provided for @reportsSpendingIncreased.
  ///
  /// In en, this message translates to:
  /// **'Spending increased this month'**
  String get reportsSpendingIncreased;

  /// No description provided for @reportsSpendingDecreased.
  ///
  /// In en, this message translates to:
  /// **'Spending decreased this month'**
  String get reportsSpendingDecreased;

  /// No description provided for @reportsSpendingPattern.
  ///
  /// In en, this message translates to:
  /// **'Spending Pattern'**
  String get reportsSpendingPattern;

  /// No description provided for @reportsSpendingPatternDesc.
  ///
  /// In en, this message translates to:
  /// **'Your spending peaks on Fridays'**
  String get reportsSpendingPatternDesc;

  /// No description provided for @reportsSavingsOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Savings Opportunity'**
  String get reportsSavingsOpportunity;

  /// No description provided for @reportsSavingsOpportunityDesc.
  ///
  /// In en, this message translates to:
  /// **'Could save €150/month on dining'**
  String get reportsSavingsOpportunityDesc;

  /// No description provided for @reportsAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get reportsAlert;

  /// No description provided for @reportsAlertDesc.
  ///
  /// In en, this message translates to:
  /// **'2 budgets nearing limits'**
  String get reportsAlertDesc;

  /// No description provided for @reportsExportFullReport.
  ///
  /// In en, this message translates to:
  /// **'Export Full Report'**
  String get reportsExportFullReport;

  /// No description provided for @reportsExportPDFDesc.
  ///
  /// In en, this message translates to:
  /// **'High-quality report with charts'**
  String get reportsExportPDFDesc;

  /// No description provided for @reportsExportCSVDesc.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet-friendly data'**
  String get reportsExportCSVDesc;

  /// No description provided for @reportsExportExcelDesc.
  ///
  /// In en, this message translates to:
  /// **'Advanced Excel format'**
  String get reportsExportExcelDesc;

  /// No description provided for @reportsFreeTierExportLimit.
  ///
  /// In en, this message translates to:
  /// **'Free tier: Last 3 months only'**
  String get reportsFreeTierExportLimit;

  /// No description provided for @reportsUnlimitedExport.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro for unlimited export history'**
  String get reportsUnlimitedExport;

  /// No description provided for @reportsMonthlyTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly Trend'**
  String get reportsMonthlyTrend;

  /// No description provided for @reportsWeeklySpendingAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Weekly Spending Analysis'**
  String get reportsWeeklySpendingAnalysis;

  /// No description provided for @reportsMonthlyTrendAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Monthly Trend Analysis'**
  String get reportsMonthlyTrendAnalysis;

  /// No description provided for @insightHighestSpendDay.
  ///
  /// In en, this message translates to:
  /// **'Highest Spend Day'**
  String get insightHighestSpendDay;

  /// No description provided for @insightMostVisited.
  ///
  /// In en, this message translates to:
  /// **'Most Visited'**
  String get insightMostVisited;

  /// No description provided for @insightMostVisitedValue.
  ///
  /// In en, this message translates to:
  /// **'{merchant} ({count} times)'**
  String insightMostVisitedValue(Object count, Object merchant);

  /// No description provided for @insightOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get insightOnTrack;

  /// No description provided for @insightWatchSpending.
  ///
  /// In en, this message translates to:
  /// **'Watch Spending'**
  String get insightWatchSpending;

  /// No description provided for @insightSpendingStatus.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used • {days} days left'**
  String insightSpendingStatus(Object days, Object percent);

  /// No description provided for @insightExceededBy.
  ///
  /// In en, this message translates to:
  /// **'Exceeded by {amount}'**
  String insightExceededBy(Object amount);

  /// No description provided for @insightDailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily Average'**
  String get insightDailyAverage;

  /// No description provided for @commonIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get commonIncrease;

  /// No description provided for @commonDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get commonDecrease;

  /// No description provided for @reportsErrorLoadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Error loading progress'**
  String get reportsErrorLoadingProgress;

  /// No description provided for @reportsSpendingTrend.
  ///
  /// In en, this message translates to:
  /// **'Spending Trend'**
  String get reportsSpendingTrend;

  /// No description provided for @reportsAverageSpending.
  ///
  /// In en, this message translates to:
  /// **'Average spending per day: {amount}'**
  String reportsAverageSpending(Object amount);

  /// No description provided for @reportsProjectedTotal.
  ///
  /// In en, this message translates to:
  /// **'Projected monthly total: {amount}'**
  String reportsProjectedTotal(Object amount);

  /// No description provided for @reportsSpendingHabitsDesc.
  ///
  /// In en, this message translates to:
  /// **'Based on your spending habits this month.'**
  String get reportsSpendingHabitsDesc;

  /// No description provided for @insightHighestSpendDayValue.
  ///
  /// In en, this message translates to:
  /// **'{day} ({amount})'**
  String insightHighestSpendDayValue(Object amount, Object day);

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get commonNotNow;

  /// No description provided for @commonOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get commonOpenSettings;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get commonTryAgain;

  /// No description provided for @profileEncrypted.
  ///
  /// In en, this message translates to:
  /// **'End-to-End Encrypted'**
  String get profileEncrypted;

  /// No description provided for @profileRealtimeSync.
  ///
  /// In en, this message translates to:
  /// **'Realtime Sync'**
  String get profileRealtimeSync;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'What do these metrics mean?'**
  String get analyticsHelpTooltip;

  /// No description provided for @analyticsErrorHealth.
  ///
  /// In en, this message translates to:
  /// **'Failed to load health score: {error}'**
  String analyticsErrorHealth(Object error);

  /// No description provided for @analyticsErrorStats.
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics: {error}'**
  String analyticsErrorStats(Object error);

  /// No description provided for @analyticsErrorCategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories: {error}'**
  String analyticsErrorCategories(Object error);

  /// No description provided for @analyticsNoExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get analyticsNoExpenses;

  /// No description provided for @analyticsBudgetHealth.
  ///
  /// In en, this message translates to:
  /// **'Budget Health'**
  String get analyticsBudgetHealth;

  /// No description provided for @analyticsFromLastMonth.
  ///
  /// In en, this message translates to:
  /// **'from last month'**
  String get analyticsFromLastMonth;

  /// No description provided for @analyticsScoreBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Score Breakdown'**
  String get analyticsScoreBreakdown;

  /// No description provided for @analyticsUsage.
  ///
  /// In en, this message translates to:
  /// **'Budget Usage'**
  String get analyticsUsage;

  /// No description provided for @analyticsConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get analyticsConsistency;

  /// No description provided for @analyticsBalance.
  ///
  /// In en, this message translates to:
  /// **'Category Balance'**
  String get analyticsBalance;

  /// No description provided for @analyticsRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring Ratio'**
  String get analyticsRecurring;

  /// No description provided for @analyticsSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get analyticsSpent;

  /// No description provided for @analyticsOfBudget.
  ///
  /// In en, this message translates to:
  /// **'of budget'**
  String get analyticsOfBudget;

  /// No description provided for @analyticsDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Days Left'**
  String get analyticsDaysLeft;

  /// No description provided for @analyticsDayAvg.
  ///
  /// In en, this message translates to:
  /// **'/day avg'**
  String get analyticsDayAvg;

  /// No description provided for @analyticsHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Understanding Your Analytics'**
  String get analyticsHelpTitle;

  /// No description provided for @analyticsHelpHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Score'**
  String get analyticsHelpHealthTitle;

  /// No description provided for @analyticsHelpHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'A 0–100 score reflecting overall budget management. Higher is better.'**
  String get analyticsHelpHealthDesc;

  /// No description provided for @analyticsHelpBurnTitle.
  ///
  /// In en, this message translates to:
  /// **'Burn Rate'**
  String get analyticsHelpBurnTitle;

  /// No description provided for @analyticsHelpBurnDesc.
  ///
  /// In en, this message translates to:
  /// **'How quickly you\'re spending. Used to project if you\'ll stay under budget.'**
  String get analyticsHelpBurnDesc;

  /// No description provided for @analyticsHelpPressureTitle.
  ///
  /// In en, this message translates to:
  /// **'Category Pressure'**
  String get analyticsHelpPressureTitle;

  /// No description provided for @analyticsHelpPressureDesc.
  ///
  /// In en, this message translates to:
  /// **'Shows which categories are close to their limits.'**
  String get analyticsHelpPressureDesc;

  /// No description provided for @notifInvitationDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined'**
  String get notifInvitationDeclined;

  /// No description provided for @notifWelcomeToBudget.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the budget!'**
  String get notifWelcomeToBudget;

  /// No description provided for @notifAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get notifAccept;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get errInvalidEmail;

  /// No description provided for @errEmailAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Email already added'**
  String get errEmailAlreadyAdded;

  /// No description provided for @syncKeepMyChanges.
  ///
  /// In en, this message translates to:
  /// **'Keep My Changes'**
  String get syncKeepMyChanges;

  /// No description provided for @syncUseServerVersion.
  ///
  /// In en, this message translates to:
  /// **'Use Server Version'**
  String get syncUseServerVersion;

  /// No description provided for @commonContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get commonContactSupport;

  /// No description provided for @savingsAddMoney.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get savingsAddMoney;

  /// No description provided for @paywallTrialStarted.
  ///
  /// In en, this message translates to:
  /// **'Free trial started!'**
  String get paywallTrialStarted;

  /// No description provided for @paywallTrialUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Trial unavailable'**
  String get paywallTrialUnavailable;

  /// No description provided for @recurringRecurringExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recurring Expenses'**
  String get recurringRecurringExpenses;

  /// No description provided for @recurringAddRecurring.
  ///
  /// In en, this message translates to:
  /// **'Add Recurring'**
  String get recurringAddRecurring;

  /// No description provided for @errFillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get errFillRequiredFields;

  /// No description provided for @recurringAdded.
  ///
  /// In en, this message translates to:
  /// **'Recurring expense added!'**
  String get recurringAdded;

  /// No description provided for @categoryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get categoryDelete;

  /// No description provided for @settingsDeleteAccountPending.
  ///
  /// In en, this message translates to:
  /// **'Account deletion request sent.'**
  String get settingsDeleteAccountPending;

  /// No description provided for @settingsResetApp.
  ///
  /// In en, this message translates to:
  /// **'Reset Application'**
  String get settingsResetApp;

  /// No description provided for @settingsResetAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear local data and cache'**
  String get settingsResetAppSubtitle;

  /// No description provided for @settingsResetAppPending.
  ///
  /// In en, this message translates to:
  /// **'App reset request sent.'**
  String get settingsResetAppPending;

  /// No description provided for @settingsBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import, export, and manage data'**
  String get settingsBackupSubtitle;

  /// No description provided for @settingsBackupMigrated.
  ///
  /// In en, this message translates to:
  /// **'Backup Restore functionality migrated to Advanced Tab'**
  String get settingsBackupMigrated;

  /// No description provided for @settingsAccentColorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize app colors'**
  String get settingsAccentColorSubtitle;

  /// No description provided for @settingsExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get settingsExpert;

  /// No description provided for @settingsSimplified.
  ///
  /// In en, this message translates to:
  /// **'Simplified'**
  String get settingsSimplified;

  /// No description provided for @settingsUnlockThemes.
  ///
  /// In en, this message translates to:
  /// **'Unlock Custom Themes'**
  String get settingsUnlockThemes;

  /// No description provided for @settingsUpgradeProThemes.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro to check out these features:'**
  String get settingsUpgradeProThemes;

  /// No description provided for @settingsFeatureAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent Color Customization'**
  String get settingsFeatureAccent;

  /// No description provided for @settingsFeaturePrimary.
  ///
  /// In en, this message translates to:
  /// **'Premium Primary Colors'**
  String get settingsFeaturePrimary;

  /// No description provided for @settingsFeatureDarkSync.
  ///
  /// In en, this message translates to:
  /// **'Dark/Light Mode Sync'**
  String get settingsFeatureDarkSync;

  /// No description provided for @settingsFeatureGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient UI Elements'**
  String get settingsFeatureGradient;

  /// No description provided for @commonOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get commonOn;

  /// No description provided for @commonOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get commonOff;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get commonInvite;

  /// No description provided for @commonSendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get commonSendInvite;

  /// No description provided for @commonInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {email}'**
  String commonInviteSent(Object email);

  /// No description provided for @commonInviteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to invite: {error}'**
  String commonInviteFailed(Object error);

  /// No description provided for @commonErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commonErrorMessage(Object error);

  /// No description provided for @familyRoleEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor - Can add expenses'**
  String get familyRoleEditor;

  /// No description provided for @familyRoleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer - Read only'**
  String get familyRoleViewer;

  /// No description provided for @familyChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get familyChangeRole;

  /// No description provided for @familyChangeRoleFor.
  ///
  /// In en, this message translates to:
  /// **'Change role for {name}'**
  String familyChangeRoleFor(Object name);

  /// No description provided for @familyInviteFirst.
  ///
  /// In en, this message translates to:
  /// **'Invite First Member'**
  String get familyInviteFirst;

  /// No description provided for @familyAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Family Sharing'**
  String get familyAboutTitle;

  /// No description provided for @familyAboutDesc.
  ///
  /// In en, this message translates to:
  /// **'Family sharing allows you to:'**
  String get familyAboutDesc;

  /// No description provided for @familyRolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Roles:'**
  String get familyRolesTitle;

  /// No description provided for @notifPendingInvites.
  ///
  /// In en, this message translates to:
  /// **'Pending Invites'**
  String get notifPendingInvites;

  /// No description provided for @notifInviteAcceptedMsg.
  ///
  /// In en, this message translates to:
  /// **'Invite accepted! You can now access this budget.'**
  String get notifInviteAcceptedMsg;

  /// No description provided for @notifDeclineInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline Invite?'**
  String get notifDeclineInviteTitle;

  /// No description provided for @notifDeclineInviteDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to decline this invitation? This cannot be undone.'**
  String get notifDeclineInviteDesc;

  /// No description provided for @syncNoDifferences.
  ///
  /// In en, this message translates to:
  /// **'No differences found'**
  String get syncNoDifferences;

  /// No description provided for @syncKeepLocal.
  ///
  /// In en, this message translates to:
  /// **'Keep Local'**
  String get syncKeepLocal;

  /// No description provided for @syncKeepRemote.
  ///
  /// In en, this message translates to:
  /// **'Keep Remote'**
  String get syncKeepRemote;

  /// No description provided for @syncKeepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep Both (Duplicate)'**
  String get syncKeepBoth;

  /// No description provided for @syncConfirmResolution.
  ///
  /// In en, this message translates to:
  /// **'Confirm Resolution'**
  String get syncConfirmResolution;

  /// No description provided for @commonDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get commonDecline;

  /// No description provided for @notifDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get notifDecline;

  /// No description provided for @reportsFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reports: {error}'**
  String reportsFailedLoad(Object error);

  /// No description provided for @reportsTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get reportsTransactions;

  /// No description provided for @savingsGoalBy.
  ///
  /// In en, this message translates to:
  /// **'Goal by {date}'**
  String savingsGoalBy(Object date);

  /// No description provided for @savingsNoDeadline.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get savingsNoDeadline;

  /// No description provided for @savingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savingsSaved;

  /// No description provided for @savingsTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get savingsTarget;

  /// No description provided for @savingsLeftToGo.
  ///
  /// In en, this message translates to:
  /// **'{amount} left to go'**
  String savingsLeftToGo(Object amount);

  /// No description provided for @savingsGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal Reached! 🎉'**
  String get savingsGoalReached;

  /// No description provided for @savingsNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Total Net Worth'**
  String get savingsNetWorth;

  /// No description provided for @savingsAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get savingsAssets;

  /// No description provided for @savingsLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get savingsLiabilities;

  /// No description provided for @bankingTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get bankingTitle;

  /// No description provided for @bankingConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Your Bank'**
  String get bankingConnectTitle;

  /// No description provided for @bankingConnectButton.
  ///
  /// In en, this message translates to:
  /// **'Connect Bank'**
  String get bankingConnectButton;

  /// No description provided for @bankingAuthorizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Authorize Bank Access'**
  String get bankingAuthorizeTitle;

  /// No description provided for @syncConflictsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Conflicts'**
  String get syncConflictsTitle;

  /// No description provided for @syncAboutConflicts.
  ///
  /// In en, this message translates to:
  /// **'About Sync Conflicts'**
  String get syncAboutConflicts;

  /// No description provided for @syncResolvedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Conflict resolved successfully'**
  String get syncResolvedSuccess;

  /// No description provided for @syncErrorResolving.
  ///
  /// In en, this message translates to:
  /// **'Error resolving conflict: {error}'**
  String syncErrorResolving(Object error);

  /// No description provided for @budgetNotFound.
  ///
  /// In en, this message translates to:
  /// **'Budget not found or has been deleted'**
  String get budgetNotFound;

  /// No description provided for @budgetLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Limit Reached'**
  String get budgetLimitReached;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get commonCopied;

  /// No description provided for @commonArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get commonArchive;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get commonDuplicate;

  /// No description provided for @commonResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get commonResolve;

  /// No description provided for @commonLookUp.
  ///
  /// In en, this message translates to:
  /// **'Look Up'**
  String get commonLookUp;

  /// No description provided for @budgetShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Budget'**
  String get budgetShareTitle;

  /// No description provided for @budgetArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Budget'**
  String get budgetArchiveTitle;

  /// No description provided for @budgetDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Budget'**
  String get budgetDuplicateTitle;

  /// No description provided for @expenseAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get expenseAdd;

  /// No description provided for @expenseScanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get expenseScanAgain;

  /// No description provided for @expenseCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense created successfully!'**
  String get expenseCreatedSuccess;

  /// No description provided for @expenseSelectBudget.
  ///
  /// In en, this message translates to:
  /// **'Please select a budget'**
  String get expenseSelectBudget;

  /// No description provided for @subTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subTitle;

  /// No description provided for @subRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored'**
  String get subRestoreSuccess;

  /// No description provided for @subCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription?'**
  String get subCancelTitle;

  /// No description provided for @subCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get subCancelConfirm;

  /// No description provided for @subCancelKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep Subscription'**
  String get subCancelKeep;

  /// No description provided for @subCancelledMsg.
  ///
  /// In en, this message translates to:
  /// **'Subscription cancelled'**
  String get subCancelledMsg;

  /// No description provided for @subErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading subscription'**
  String get subErrorLoading;

  /// No description provided for @adminMLDashboard.
  ///
  /// In en, this message translates to:
  /// **'ML Performance Dashboard'**
  String get adminMLDashboard;

  /// No description provided for @adminABDashboard.
  ///
  /// In en, this message translates to:
  /// **'A/B Testing Dashboard'**
  String get adminABDashboard;

  /// No description provided for @adminNewTest.
  ///
  /// In en, this message translates to:
  /// **'New Test'**
  String get adminNewTest;

  /// No description provided for @adminEndTest.
  ///
  /// In en, this message translates to:
  /// **'End Test'**
  String get adminEndTest;

  /// No description provided for @adminEndTestTitle.
  ///
  /// In en, this message translates to:
  /// **'End A/B Test?'**
  String get adminEndTestTitle;

  /// No description provided for @adminTestEndedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Test ended successfully'**
  String get adminTestEndedSuccess;

  /// No description provided for @recurringAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Recurring Expense'**
  String get recurringAddTitle;

  /// No description provided for @recurringTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get recurringTitleLabel;

  /// No description provided for @recurringAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get recurringAmountLabel;

  /// No description provided for @recurringFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get recurringFrequencyLabel;

  /// No description provided for @recurringCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get recurringCategoryLabel;

  /// No description provided for @recurringDayOfMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Day of Month'**
  String get recurringDayOfMonthLabel;

  /// No description provided for @budgetShareShort.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get budgetShareShort;

  /// No description provided for @budgetDeleteShort.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get budgetDeleteShort;

  /// No description provided for @budgetInviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Invite family members to join \"{budgetTitle}\"'**
  String budgetInviteMessage(Object budgetTitle);

  /// No description provided for @budgetRoleEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get budgetRoleEditor;

  /// No description provided for @budgetRoleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get budgetRoleViewer;

  /// No description provided for @budgetInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {email}'**
  String budgetInviteSent(Object email);

  /// No description provided for @budgetInviteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to invite: {error}'**
  String budgetInviteFailed(Object error);

  /// No description provided for @budgetDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Budget'**
  String get budgetDeleteConfirmTitle;

  /// No description provided for @budgetDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete budget: {error}'**
  String budgetDeleteFailed(Object error);

  /// No description provided for @expenseDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get expenseDeleteConfirmTitle;

  /// No description provided for @expenseDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String expenseDeleteConfirmMessage(Object title);

  /// No description provided for @categoryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{categoryName}\"?'**
  String categoryDeleteConfirm(Object categoryName);

  /// No description provided for @categoryExistsError.
  ///
  /// In en, this message translates to:
  /// **'Category \"{name}\" already exists'**
  String categoryExistsError(Object name);

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifEmpty.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get notifEmpty;

  /// No description provided for @abActiveTests.
  ///
  /// In en, this message translates to:
  /// **'Active Tests'**
  String get abActiveTests;

  /// No description provided for @abCompletedTests.
  ///
  /// In en, this message translates to:
  /// **'Completed Tests'**
  String get abCompletedTests;

  /// No description provided for @abNoActiveTests.
  ///
  /// In en, this message translates to:
  /// **'No active tests'**
  String get abNoActiveTests;

  /// No description provided for @abNoCompletedTests.
  ///
  /// In en, this message translates to:
  /// **'No completed tests yet'**
  String get abNoCompletedTests;

  /// No description provided for @abStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get abStatusActive;

  /// No description provided for @abStartedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Started: {date}'**
  String abStartedPrefix(Object date);

  /// No description provided for @abEndedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Ended: {date}'**
  String abEndedPrefix(Object date);

  /// No description provided for @abViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get abViewDetails;

  /// No description provided for @abAcceptanceRate.
  ///
  /// In en, this message translates to:
  /// **'{rate}% accept'**
  String abAcceptanceRate(Object rate);

  /// No description provided for @abTotalScans.
  ///
  /// In en, this message translates to:
  /// **'{count} scans'**
  String abTotalScans(Object count);

  /// No description provided for @abEndConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to end \"{testName}\"?'**
  String abEndConfirmMessage(Object testName);

  /// No description provided for @abEndFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to end test: {error}'**
  String abEndFail(Object error);

  /// No description provided for @profileNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get profileNetWorth;

  /// No description provided for @profileSpentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent This Month'**
  String get profileSpentThisMonth;

  /// No description provided for @profileIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get profileIncome;

  /// No description provided for @profileSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get profileSavings;

  /// No description provided for @profileWaitSync.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your first sync'**
  String get profileWaitSync;

  /// No description provided for @profileNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded yet'**
  String get profileNoActivity;

  /// No description provided for @profileDetectIncome.
  ///
  /// In en, this message translates to:
  /// **'We’ll detect income automatically'**
  String get profileDetectIncome;

  /// No description provided for @profileSavingsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your savings will appear here'**
  String get profileSavingsWillAppear;

  /// No description provided for @profileSyncHelper.
  ///
  /// In en, this message translates to:
  /// **'Once you connect a bank and sync transactions, CashPilot will automatically organize your finances.'**
  String get profileSyncHelper;

  /// No description provided for @profileSpentPerDay.
  ///
  /// In en, this message translates to:
  /// **'{amount} per day on average'**
  String profileSpentPerDay(String amount);

  /// No description provided for @profileLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get profileLast30Days;

  /// No description provided for @profileSavedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Saved this month'**
  String get profileSavedThisMonth;

  /// No description provided for @profileBankNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Bank not connected yet'**
  String get profileBankNotConnected;

  /// No description provided for @profileConnectBankCTA.
  ///
  /// In en, this message translates to:
  /// **'Connect your bank to start tracking →'**
  String get profileConnectBankCTA;

  /// No description provided for @profileLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String profileLastSynced(String time);

  /// No description provided for @profileDataStale.
  ///
  /// In en, this message translates to:
  /// **'Data hasn’t updated in a few days'**
  String get profileDataStale;

  /// No description provided for @profileSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now →'**
  String get profileSyncNow;

  /// No description provided for @profileFinancialConsistency.
  ///
  /// In en, this message translates to:
  /// **'Financial Consistency'**
  String get profileFinancialConsistency;

  /// No description provided for @profileConsistencyBuilding.
  ///
  /// In en, this message translates to:
  /// **'You\'re building a habit — keep going.'**
  String get profileConsistencyBuilding;

  /// No description provided for @profileConsistencyBetter.
  ///
  /// In en, this message translates to:
  /// **'↑ More consistent than last week'**
  String get profileConsistencyBetter;

  /// No description provided for @profileStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak: {weeks} weeks'**
  String profileStreak(int weeks);

  /// No description provided for @profileActiveDays.
  ///
  /// In en, this message translates to:
  /// **'{count} active days this week'**
  String profileActiveDays(int count);

  /// No description provided for @profileEngagementEmpty.
  ///
  /// In en, this message translates to:
  /// **'Once your transactions sync, we\'ll track your progress here.'**
  String get profileEngagementEmpty;

  /// No description provided for @profileInsightEmpty.
  ///
  /// In en, this message translates to:
  /// **'We’ll generate personalized insights once your transactions are synced.\nNo manual tracking required.'**
  String get profileInsightEmpty;

  /// No description provided for @profileConnectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get profileConnectedAccounts;

  /// No description provided for @profileNoBankConnected.
  ///
  /// In en, this message translates to:
  /// **'No bank accounts connected'**
  String get profileNoBankConnected;

  /// No description provided for @profileConnectBankAction.
  ///
  /// In en, this message translates to:
  /// **'Connect a bank account →'**
  String get profileConnectBankAction;

  /// No description provided for @profileAccountsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 account connected} other{{count} accounts connected}}'**
  String profileAccountsCount(int count);

  /// No description provided for @profileManageAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage connected accounts →'**
  String get profileManageAccounts;

  /// No description provided for @profileDisplayNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Shown when sharing budgets or insights'**
  String get profileDisplayNameDesc;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit →'**
  String get profileEdit;

  /// No description provided for @profileMotivationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Everyone starts somewhere.\nConnect your bank to see your full financial picture.'**
  String get profileMotivationEmpty;

  /// No description provided for @profileMotivationActive.
  ///
  /// In en, this message translates to:
  /// **'Small improvements add up.\nCashPilot helps you stay on course.'**
  String get profileMotivationActive;

  /// No description provided for @profileTrackingSince.
  ///
  /// In en, this message translates to:
  /// **'Tracking your finances since {date}'**
  String profileTrackingSince(String date);

  /// No description provided for @profileFinancialInsight.
  ///
  /// In en, this message translates to:
  /// **'Financial Insight'**
  String get profileFinancialInsight;

  /// No description provided for @mlPredictiveInsights.
  ///
  /// In en, this message translates to:
  /// **'Predictive Insights'**
  String get mlPredictiveInsights;

  /// No description provided for @mlForecastNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next Month Forecast'**
  String get mlForecastNextMonth;

  /// No description provided for @mlAnomalyDetected.
  ///
  /// In en, this message translates to:
  /// **'Potential Anomaly'**
  String get mlAnomalyDetected;

  /// No description provided for @mlAnomalyDescription.
  ///
  /// In en, this message translates to:
  /// **'This expense is significantly higher than your typical {category} spending.'**
  String mlAnomalyDescription(Object category);

  /// No description provided for @mlAnomalyConfidence.
  ///
  /// In en, this message translates to:
  /// **'Anomaly Confidence: {percent}%'**
  String mlAnomalyConfidence(Object percent);

  /// No description provided for @mlEstimatedBalance.
  ///
  /// In en, this message translates to:
  /// **'Est. End-of-Month Balance'**
  String get mlEstimatedBalance;

  /// No description provided for @mlLowBalanceAlert.
  ///
  /// In en, this message translates to:
  /// **'Potential Cash Flow Shortage'**
  String get mlLowBalanceAlert;

  /// No description provided for @mlLowBalanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Predicted spending may exceed your current balance.'**
  String get mlLowBalanceDescription;

  /// No description provided for @knowledgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Knowledge'**
  String get knowledgeTitle;

  /// No description provided for @knowledgeDailyTip.
  ///
  /// In en, this message translates to:
  /// **'Daily Tip'**
  String get knowledgeDailyTip;

  /// No description provided for @knowledgeTopicForYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get knowledgeTopicForYou;

  /// No description provided for @knowledgeTopicAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get knowledgeTopicAll;

  /// No description provided for @knowledgeTopicBudgeting.
  ///
  /// In en, this message translates to:
  /// **'Budgeting'**
  String get knowledgeTopicBudgeting;

  /// No description provided for @knowledgeTopicInvesting.
  ///
  /// In en, this message translates to:
  /// **'Investing'**
  String get knowledgeTopicInvesting;

  /// No description provided for @knowledgeTopicSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get knowledgeTopicSavings;

  /// No description provided for @knowledgeTopicDebt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get knowledgeTopicDebt;

  /// No description provided for @knowledgeReadTime.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min read'**
  String knowledgeReadTime(int minutes);

  /// No description provided for @knowledgeNoArticles.
  ///
  /// In en, this message translates to:
  /// **'No articles found for {topic}'**
  String knowledgeNoArticles(String topic);

  /// No description provided for @settingsSystemControl.
  ///
  /// In en, this message translates to:
  /// **'System Control'**
  String get settingsSystemControl;

  /// No description provided for @settingsAutoLock.
  ///
  /// In en, this message translates to:
  /// **'Auto-Lock'**
  String get settingsAutoLock;

  /// No description provided for @settingsHighPerformanceMode.
  ///
  /// In en, this message translates to:
  /// **'High Performance Mode'**
  String get settingsHighPerformanceMode;

  /// No description provided for @settingsTabDataSync.
  ///
  /// In en, this message translates to:
  /// **'Data & Sync'**
  String get settingsTabDataSync;

  /// No description provided for @settingsKnowledgeBase.
  ///
  /// In en, this message translates to:
  /// **'Knowledge Base'**
  String get settingsKnowledgeBase;

  /// No description provided for @settingsManageSubscriptionNote.
  ///
  /// In en, this message translates to:
  /// **'You can manage your subscription from your app store settings.'**
  String get settingsManageSubscriptionNote;

  /// No description provided for @settingsCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get settingsCurrentPlan;

  /// No description provided for @commonUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get commonUnlimited;

  /// No description provided for @homeAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get homeAvailableBalance;

  /// No description provided for @homeAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get homeAddTransaction;

  /// No description provided for @reportsSpendings.
  ///
  /// In en, this message translates to:
  /// **'Spendings'**
  String get reportsSpendings;

  /// No description provided for @reportsSpendingCategories.
  ///
  /// In en, this message translates to:
  /// **'Spending Categories'**
  String get reportsSpendingCategories;

  /// No description provided for @reportsIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get reportsIncome;

  /// No description provided for @reportsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get reportsExpenses;

  /// No description provided for @savingsAssetsOverview.
  ///
  /// In en, this message translates to:
  /// **'Assets Overview'**
  String get savingsAssetsOverview;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en', 'fi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'fi':
      return AppLocalizationsFi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
