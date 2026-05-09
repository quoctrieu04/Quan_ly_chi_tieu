import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get appTitle;

  /// No description provided for @tabBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get tabBudgets;

  /// No description provided for @tabAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get tabAccounts;

  /// No description provided for @tabAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get tabAnalytics;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @userNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get userNamePlaceholder;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

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

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Light / Dark'**
  String get brightness;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Theme color'**
  String get color;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @fontSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontSmall;

  /// No description provided for @fontNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get fontNormal;

  /// No description provided for @fontLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontLarge;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @policy.
  ///
  /// In en, this message translates to:
  /// **'Policy & Security'**
  String get policy;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get logoutSuccess;

  /// No description provided for @budgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get budgetsTitle;

  /// No description provided for @budgetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage limits and spending categories.'**
  String get budgetsDescription;

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @accountsDescription.
  ///
  /// In en, this message translates to:
  /// **'Link bank accounts, e-wallets and view current balances.'**
  String get accountsDescription;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsDescription.
  ///
  /// In en, this message translates to:
  /// **'View your spending and budget analysis'**
  String get analyticsDescription;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSubmit;

  /// No description provided for @totalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total assets'**
  String get totalAssets;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @tracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tracking;

  /// No description provided for @createWallet.
  ///
  /// In en, this message translates to:
  /// **'Create wallet'**
  String get createWallet;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get transactionHistory;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @startAddingMoneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start adding money to your wallets!'**
  String get startAddingMoneyTitle;

  /// No description provided for @startAddingMoneyHint.
  ///
  /// In en, this message translates to:
  /// **'The more accurate your input, the more accurate the analytics will be!'**
  String get startAddingMoneyHint;

  /// No description provided for @readyMoneyShort.
  ///
  /// In en, this message translates to:
  /// **'Ready money...'**
  String get readyMoneyShort;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalance;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @monthlyClosed.
  ///
  /// In en, this message translates to:
  /// **'Monthly (closed)'**
  String get monthlyClosed;

  /// No description provided for @travelDeleted.
  ///
  /// In en, this message translates to:
  /// **'Travel (deleted)'**
  String get travelDeleted;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @accountsStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start adding money to your wallet!'**
  String get accountsStartTitle;

  /// No description provided for @accountsStartHint.
  ///
  /// In en, this message translates to:
  /// **'The more accurate your input is, the better the app can calculate and analyze your data!'**
  String get accountsStartHint;

  /// No description provided for @noTransactionsHint.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet. Start recording your first expense!'**
  String get noTransactionsHint;

  /// No description provided for @monthBadge.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthBadge;

  /// No description provided for @noteAddDescription.
  ///
  /// In en, this message translates to:
  /// **'Add description...'**
  String get noteAddDescription;

  /// No description provided for @moneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get moneyOut;

  /// No description provided for @moneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get moneyIn;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @walletName.
  ///
  /// In en, this message translates to:
  /// **'Wallet name'**
  String get walletName;

  /// No description provided for @initialAmount.
  ///
  /// In en, this message translates to:
  /// **'Initial amount'**
  String get initialAmount;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @walletCreated.
  ///
  /// In en, this message translates to:
  /// **'Wallet created'**
  String get walletCreated;

  /// No description provided for @needLogin.
  ///
  /// In en, this message translates to:
  /// **'Need login'**
  String get needLogin;

  /// No description provided for @needLoginContent.
  ///
  /// In en, this message translates to:
  /// **'You need to log in to create a wallet.'**
  String get needLoginContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please try again'**
  String get somethingWrong;

  /// No description provided for @createBudgetCta.
  ///
  /// In en, this message translates to:
  /// **'Create budget'**
  String get createBudgetCta;

  /// No description provided for @moneyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get moneyAssigned;

  /// No description provided for @moneyUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get moneyUnassigned;

  /// No description provided for @assignMoneyCta.
  ///
  /// In en, this message translates to:
  /// **'Assign money'**
  String get assignMoneyCta;

  /// No description provided for @trialReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your trial plan'**
  String get trialReminderTitle;

  /// No description provided for @trialReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your trial plan before {date} to avoid service interruption!'**
  String trialReminderSubtitle(String date);

  /// No description provided for @viewPackagesCta.
  ///
  /// In en, this message translates to:
  /// **'View packages'**
  String get viewPackagesCta;

  /// No description provided for @createCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get createCategoryTitle;

  /// No description provided for @createCategoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Group your spending by category to easily track where your money goes.'**
  String get createCategoryDescription;

  /// No description provided for @createFromSuggested.
  ///
  /// In en, this message translates to:
  /// **'Create from suggested list'**
  String get createFromSuggested;

  /// No description provided for @createMyOwn.
  ///
  /// In en, this message translates to:
  /// **'Create my own category'**
  String get createMyOwn;

  /// No description provided for @budgetSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget settings'**
  String get budgetSettingsTitle;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @numberFormat.
  ///
  /// In en, this message translates to:
  /// **'Number format'**
  String get numberFormat;

  /// No description provided for @currencySymbolPosition.
  ///
  /// In en, this message translates to:
  /// **'Currency symbol position'**
  String get currencySymbolPosition;

  /// No description provided for @symbolBefore.
  ///
  /// In en, this message translates to:
  /// **'Before amount'**
  String get symbolBefore;

  /// No description provided for @symbolAfter.
  ///
  /// In en, this message translates to:
  /// **'After amount'**
  String get symbolAfter;

  /// No description provided for @monthYearTitle.
  ///
  /// In en, this message translates to:
  /// **'{monthName} {year}'**
  String monthYearTitle(Object monthName, Object year);

  /// No description provided for @monthGridLabel.
  ///
  /// In en, this message translates to:
  /// **'Month {month}'**
  String monthGridLabel(Object month);

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @editAllocationCta.
  ///
  /// In en, this message translates to:
  /// **'Edit allocation'**
  String get editAllocationCta;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a goal'**
  String get goalTitle;

  /// No description provided for @goalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reach your financial dreams by setting a savings goal.'**
  String get goalSubtitle;

  /// No description provided for @createGoalCta.
  ///
  /// In en, this message translates to:
  /// **'Create a goal'**
  String get createGoalCta;

  /// No description provided for @txHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get txHistoryTitle;

  /// No description provided for @txSpentTotal.
  ///
  /// In en, this message translates to:
  /// **'Total spent: {amount}'**
  String txSpentTotal(Object amount);

  /// No description provided for @monthlyBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget'**
  String get monthlyBudgetTitle;

  /// No description provided for @trialBannerText.
  ///
  /// In en, this message translates to:
  /// **'Your free trial ends on {deadline}'**
  String trialBannerText(Object deadline);

  /// No description provided for @viewPlansCta.
  ///
  /// In en, this message translates to:
  /// **'View plans'**
  String get viewPlansCta;

  /// No description provided for @groupRequiredCosts.
  ///
  /// In en, this message translates to:
  /// **'Required costs'**
  String get groupRequiredCosts;

  /// No description provided for @categoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get categoryRent;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @ofTotal.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofTotal;

  /// No description provided for @addCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategoryTooltip;

  /// No description provided for @addCategoryFab.
  ///
  /// In en, this message translates to:
  /// **''**
  String get addCategoryFab;

  /// No description provided for @createCategoryTitleForm.
  ///
  /// In en, this message translates to:
  /// **'Create a new category'**
  String get createCategoryTitleForm;

  /// No description provided for @selectIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Select an icon'**
  String get selectIconLabel;

  /// No description provided for @categoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryNameLabel;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter name (e.g. Rent, Food...)'**
  String get categoryNameHint;

  /// No description provided for @categoryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Category name cannot be empty'**
  String get categoryNameRequired;

  /// No description provided for @saveCta.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveCta;

  /// No description provided for @cancelCta.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelCta;

  /// No description provided for @noCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Tap + to create your first one.'**
  String get noCategoryHint;

  /// No description provided for @editBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get editBudgetTitle;

  /// No description provided for @createCategoryGroupCta.
  ///
  /// In en, this message translates to:
  /// **'CREATE CATEGORY GROUP'**
  String get createCategoryGroupCta;

  /// No description provided for @reorderDeleteCategoriesCta.
  ///
  /// In en, this message translates to:
  /// **'REORDER/DELETE CATEGORIES'**
  String get reorderDeleteCategoriesCta;

  /// No description provided for @renameCta.
  ///
  /// In en, this message translates to:
  /// **'RENAME'**
  String get renameCta;

  /// No description provided for @loginRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue'**
  String get loginRequiredMessage;

  /// No description provided for @editCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategoryTitle;

  /// No description provided for @updateCta.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateCta;

  /// No description provided for @needLoginBudgets.
  ///
  /// In en, this message translates to:
  /// **'You need to log in.'**
  String get needLoginBudgets;

  /// No description provided for @allocateTitle.
  ///
  /// In en, this message translates to:
  /// **'Allocate Money to Budgets'**
  String get allocateTitle;

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableNow;

  /// No description provided for @allocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated'**
  String get allocated;

  /// No description provided for @saveAllAllocations.
  ///
  /// In en, this message translates to:
  /// **'SAVE ALL ALLOCATIONS'**
  String get saveAllAllocations;

  /// No description provided for @remainingToAllocate.
  ///
  /// In en, this message translates to:
  /// **'Remaining to allocate'**
  String get remainingToAllocate;

  /// No description provided for @inputAllocateTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount to allocate'**
  String get inputAllocateTitle;

  /// No description provided for @moneyInputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500000'**
  String get moneyInputHint;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @genericFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get genericFailedMessage;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @spentLabel.
  ///
  /// In en, this message translates to:
  /// **'Spent:'**
  String get spentLabel;

  /// No description provided for @enterAmountTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter amount to allocate'**
  String get enterAmountTitle;

  /// No description provided for @hintAmountExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., 30,000'**
  String get hintAmountExample;

  /// No description provided for @remainingUnallocated.
  ///
  /// In en, this message translates to:
  /// **'Remaining unallocated:'**
  String get remainingUnallocated;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @categoryDetails.
  ///
  /// In en, this message translates to:
  /// **'Category details'**
  String get categoryDetails;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @assignedMoney.
  ///
  /// In en, this message translates to:
  /// **'Assigned amount'**
  String get assignedMoney;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @areYouSureDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get areYouSureDelete;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @numberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get numberInvalid;

  /// No description provided for @mustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Must be a non-negative number'**
  String get mustBePositive;

  /// No description provided for @tooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long'**
  String get tooLong;

  /// No description provided for @analyticsBudgetSplit.
  ///
  /// In en, this message translates to:
  /// **'Budget allocation by category'**
  String get analyticsBudgetSplit;

  /// No description provided for @topCategories.
  ///
  /// In en, this message translates to:
  /// **'Top categories'**
  String get topCategories;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @noDataThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No data for this month'**
  String get noDataThisMonth;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select month'**
  String get selectMonth;

  /// No description provided for @totalAssigned.
  ///
  /// In en, this message translates to:
  /// **'Total assigned'**
  String get totalAssigned;

  /// No description provided for @confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete category {name}?'**
  String confirmDeleteMessage(Object name);

  /// No description provided for @deleteCta.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteCta;

  /// No description provided for @editCategories.
  ///
  /// In en, this message translates to:
  /// **'Edit categories'**
  String get editCategories;

  /// No description provided for @plannedUpperCase.
  ///
  /// In en, this message translates to:
  /// **'PLANNED'**
  String get plannedUpperCase;

  /// No description provided for @remainingUpperCase.
  ///
  /// In en, this message translates to:
  /// **'REMAINING'**
  String get remainingUpperCase;

  /// No description provided for @safeToSave.
  ///
  /// In en, this message translates to:
  /// **'Safe to reserve'**
  String get safeToSave;

  /// No description provided for @deficit.
  ///
  /// In en, this message translates to:
  /// **'Deficit!'**
  String get deficit;

  /// No description provided for @fundingSource.
  ///
  /// In en, this message translates to:
  /// **'Funding source'**
  String get fundingSource;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// No description provided for @investment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get investment;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @incomeExpenseFluctuation.
  ///
  /// In en, this message translates to:
  /// **'Income/Expense Fluctuation'**
  String get incomeExpenseFluctuation;

  /// No description provided for @incomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeLabel;

  /// No description provided for @expenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseLabel;

  /// No description provided for @interfaceSettings.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get interfaceSettings;

  /// No description provided for @moneyFormat.
  ///
  /// In en, this message translates to:
  /// **'Money format'**
  String get moneyFormat;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSettings;

  /// No description provided for @loggedIn.
  ///
  /// In en, this message translates to:
  /// **'Logged in'**
  String get loggedIn;

  /// No description provided for @predictionAndWarning.
  ///
  /// In en, this message translates to:
  /// **'Prediction & Warning'**
  String get predictionAndWarning;

  /// No description provided for @notEnoughDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for prediction'**
  String get notEnoughDataTitle;

  /// No description provided for @notEnoughDataDesc.
  ///
  /// In en, this message translates to:
  /// **'The app does not have enough data to predict your spending yet. Keep recording your transactions normally; predictions and warnings will activate automatically once there is enough data for the AI model.'**
  String get notEnoughDataDesc;

  /// No description provided for @totalSpentPieChart.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get totalSpentPieChart;

  /// No description provided for @incomeCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get incomeCollected;

  /// No description provided for @planLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planLabel;

  /// No description provided for @overLabel.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get overLabel;

  /// No description provided for @notSetLabel.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSetLabel;

  /// No description provided for @guideReview.
  ///
  /// In en, this message translates to:
  /// **'Review User Guide'**
  String get guideReview;

  /// No description provided for @notAssignedBudget.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get notAssignedBudget;

  /// No description provided for @approachingPlan.
  ///
  /// In en, this message translates to:
  /// **'Approaching plan'**
  String get approachingPlan;

  /// No description provided for @overPlan.
  ///
  /// In en, this message translates to:
  /// **'Over plan'**
  String get overPlan;

  /// No description provided for @overspentWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'💸 Oops! Overspending warning!'**
  String get overspentWarningTitle;

  /// No description provided for @overspentWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'You have overspent the budget for category \"{category}\". Tighten your belt for the rest of the month!'**
  String overspentWarningMessage(Object category);

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get gotIt;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'vi': return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
