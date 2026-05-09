// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Spending';

  @override
  String get tabBudgets => 'Budgets';

  @override
  String get tabAccounts => 'Accounts';

  @override
  String get tabAnalytics => 'Analytics';

  @override
  String get tabSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get userNamePlaceholder => 'Guest';

  @override
  String get language => 'Language';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get brightness => 'Light / Dark';

  @override
  String get color => 'Theme color';

  @override
  String get fontSize => 'Font size';

  @override
  String get fontSmall => 'Small';

  @override
  String get fontNormal => 'Normal';

  @override
  String get fontLarge => 'Large';

  @override
  String get changePassword => 'Change password';

  @override
  String get policy => 'Policy & Security';

  @override
  String get view => 'View';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get logoutSuccess => 'Signed out';

  @override
  String get budgetsTitle => 'Monthly budget';

  @override
  String get budgetsDescription => 'Manage limits and spending categories.';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountsDescription => 'Link bank accounts, e-wallets and view current balances.';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get analyticsDescription => 'View your spending and budget analysis';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get totalAssets => 'Total assets';

  @override
  String get payment => 'Payment';

  @override
  String get tracking => 'Tracking';

  @override
  String get createWallet => 'Create wallet';

  @override
  String get transactionHistory => 'Transaction history';

  @override
  String get viewAll => 'View all';

  @override
  String get startAddingMoneyTitle => 'Start adding money to your wallets!';

  @override
  String get startAddingMoneyHint => 'The more accurate your input, the more accurate the analytics will be!';

  @override
  String get readyMoneyShort => 'Ready money...';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get monthly => 'Monthly';

  @override
  String get monthlyClosed => 'Monthly (closed)';

  @override
  String get travelDeleted => 'Travel (deleted)';

  @override
  String get noDescription => 'No description';

  @override
  String get cash => 'Cash';

  @override
  String get accountsStartTitle => 'Start adding money to your wallet!';

  @override
  String get accountsStartHint => 'The more accurate your input is, the better the app can calculate and analyze your data!';

  @override
  String get noTransactionsHint => 'No transactions yet. Start recording your first expense!';

  @override
  String get monthBadge => 'Monthly';

  @override
  String get noteAddDescription => 'Add description...';

  @override
  String get moneyOut => 'Money out';

  @override
  String get moneyIn => 'Money in';

  @override
  String get category => 'Category';

  @override
  String get walletName => 'Wallet name';

  @override
  String get initialAmount => 'Initial amount';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get save => 'Save';

  @override
  String get walletCreated => 'Wallet created';

  @override
  String get needLogin => 'Need login';

  @override
  String get needLoginContent => 'You need to log in to create a wallet.';

  @override
  String get cancel => 'Cancel';

  @override
  String get noData => 'No data available';

  @override
  String get somethingWrong => 'Something went wrong, please try again';

  @override
  String get createBudgetCta => 'Create budget';

  @override
  String get moneyAssigned => 'Assigned';

  @override
  String get moneyUnassigned => 'Unassigned';

  @override
  String get assignMoneyCta => 'Assign money';

  @override
  String get trialReminderTitle => 'Choose your trial plan';

  @override
  String trialReminderSubtitle(String date) {
    return 'Choose your trial plan before $date to avoid service interruption!';
  }

  @override
  String get viewPackagesCta => 'View packages';

  @override
  String get createCategoryTitle => 'Catalog';

  @override
  String get createCategoryDescription => 'Group your spending by category to easily track where your money goes.';

  @override
  String get createFromSuggested => 'Create from suggested list';

  @override
  String get createMyOwn => 'Create my own category';

  @override
  String get budgetSettingsTitle => 'Budget settings';

  @override
  String get currency => 'Currency';

  @override
  String get numberFormat => 'Number format';

  @override
  String get currencySymbolPosition => 'Currency symbol position';

  @override
  String get symbolBefore => 'Before amount';

  @override
  String get symbolAfter => 'After amount';

  @override
  String monthYearTitle(Object monthName, Object year) {
    return '$monthName $year';
  }

  @override
  String monthGridLabel(Object month) {
    return 'Month $month';
  }

  @override
  String get remaining => 'Remaining';

  @override
  String get editAllocationCta => 'Edit allocation';

  @override
  String get goalTitle => 'Set a goal';

  @override
  String get goalSubtitle => 'Reach your financial dreams by setting a savings goal.';

  @override
  String get createGoalCta => 'Create a goal';

  @override
  String get txHistoryTitle => 'Transaction history';

  @override
  String txSpentTotal(Object amount) {
    return 'Total spent: $amount';
  }

  @override
  String get monthlyBudgetTitle => 'Monthly Budget';

  @override
  String trialBannerText(Object deadline) {
    return 'Your free trial ends on $deadline';
  }

  @override
  String get viewPlansCta => 'View plans';

  @override
  String get groupRequiredCosts => 'Required costs';

  @override
  String get categoryRent => 'Rent';

  @override
  String get spent => 'Spent';

  @override
  String get ofTotal => 'of';

  @override
  String get addCategoryTooltip => 'Add category';

  @override
  String get addCategoryFab => '';

  @override
  String get createCategoryTitleForm => 'Create a new category';

  @override
  String get selectIconLabel => 'Select an icon';

  @override
  String get categoryNameLabel => 'Category name';

  @override
  String get categoryNameHint => 'Enter name (e.g. Rent, Food...)';

  @override
  String get categoryNameRequired => 'Category name cannot be empty';

  @override
  String get saveCta => 'Save';

  @override
  String get cancelCta => 'Cancel';

  @override
  String get noCategoryHint => 'No categories yet. Tap + to create your first one.';

  @override
  String get editBudgetTitle => 'Edit budget';

  @override
  String get createCategoryGroupCta => 'CREATE CATEGORY GROUP';

  @override
  String get reorderDeleteCategoriesCta => 'REORDER/DELETE CATEGORIES';

  @override
  String get renameCta => 'RENAME';

  @override
  String get loginRequiredMessage => 'Please log in to continue';

  @override
  String get editCategoryTitle => 'Edit category';

  @override
  String get updateCta => 'Update';

  @override
  String get needLoginBudgets => 'You need to log in.';

  @override
  String get allocateTitle => 'Allocate Money to Budgets';

  @override
  String get availableNow => 'Available';

  @override
  String get allocated => 'Allocated';

  @override
  String get saveAllAllocations => 'SAVE ALL ALLOCATIONS';

  @override
  String get remainingToAllocate => 'Remaining to allocate';

  @override
  String get inputAllocateTitle => 'Enter the amount to allocate';

  @override
  String get moneyInputHint => 'e.g. 500000';

  @override
  String get ok => 'OK';

  @override
  String get genericFailedMessage => 'Action failed';

  @override
  String get available => 'Available';

  @override
  String get spentLabel => 'Spent:';

  @override
  String get enterAmountTitle => 'Enter amount to allocate';

  @override
  String get hintAmountExample => 'e.g., 30,000';

  @override
  String get remainingUnallocated => 'Remaining unallocated:';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get categoryDetails => 'Category details';

  @override
  String get categoryName => 'Category name';

  @override
  String get assignedMoney => 'Assigned amount';

  @override
  String get saved => 'Saved';

  @override
  String get delete => 'Delete';

  @override
  String get areYouSureDelete => 'Are you sure you want to delete this category?';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get numberInvalid => 'Invalid number';

  @override
  String get mustBePositive => 'Must be a non-negative number';

  @override
  String get tooLong => 'Too long';

  @override
  String get analyticsBudgetSplit => 'Budget allocation by category';

  @override
  String get topCategories => 'Top categories';

  @override
  String get summary => 'Summary';

  @override
  String get noDataThisMonth => 'No data for this month';

  @override
  String get selectMonth => 'Select month';

  @override
  String get totalAssigned => 'Total assigned';

  @override
  String get confirmTitle => 'Confirmation';

  @override
  String confirmDeleteMessage(Object name) {
    return 'Are you sure you want to delete category $name?';
  }

  @override
  String get deleteCta => 'Delete';

  @override
  String get editCategories => 'Edit categories';

  @override
  String get plannedUpperCase => 'PLANNED';

  @override
  String get remainingUpperCase => 'REMAINING';

  @override
  String get safeToSave => 'Safe to reserve';

  @override
  String get deficit => 'Deficit!';

  @override
  String get fundingSource => 'Funding source';

  @override
  String get savings => 'Savings';

  @override
  String get investment => 'Investment';

  @override
  String get overview => 'Overview';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get incomeExpenseFluctuation => 'Income/Expense Fluctuation';

  @override
  String get incomeLabel => 'Income';

  @override
  String get expenseLabel => 'Expense';

  @override
  String get interfaceSettings => 'Interface';

  @override
  String get moneyFormat => 'Money format';

  @override
  String get accountSettings => 'Account';

  @override
  String get loggedIn => 'Logged in';

  @override
  String get predictionAndWarning => 'Prediction & Warning';

  @override
  String get notEnoughDataTitle => 'Not enough data for prediction';

  @override
  String get notEnoughDataDesc => 'The app does not have enough data to predict your spending yet. Keep recording your transactions normally; predictions and warnings will activate automatically once there is enough data for the AI model.';

  @override
  String get totalSpentPieChart => 'Total spent';

  @override
  String get incomeCollected => 'Collected';

  @override
  String get planLabel => 'Plan';

  @override
  String get overLabel => 'Over';

  @override
  String get notSetLabel => 'Not set';

  @override
  String get guideReview => 'Review User Guide';

  @override
  String get notAssignedBudget => 'Not assigned';

  @override
  String get approachingPlan => 'Approaching plan';

  @override
  String get overPlan => 'Over plan';

  @override
  String get overspentWarningTitle => '💸 Oops! Overspending warning!';

  @override
  String overspentWarningMessage(Object category) {
    return 'You have overspent the budget for category \"$category\". Tighten your belt for the rest of the month!';
  }

  @override
  String get gotIt => 'Got it!';
}
