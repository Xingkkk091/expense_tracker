// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Expense Book';

  @override
  String get navRecords => 'Records';

  @override
  String get navStats => 'Stats';

  @override
  String get navMap => 'Map';

  @override
  String get homeTitle => 'My Expense Book';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get mapTitle => 'Spending Map';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search title, address, note…';

  @override
  String get filter => 'Filter';

  @override
  String get settings => 'Settings';

  @override
  String get myCarrier => 'My Carrier';

  @override
  String get add => 'Add';

  @override
  String get scanInvoice => 'Scan';

  @override
  String get balanceWeek => 'This Week';

  @override
  String get balanceMonth => 'This Month';

  @override
  String get balanceTotal => 'Total Balance';

  @override
  String get rangeWeek => 'Week';

  @override
  String get rangeMonth => 'Month';

  @override
  String get rangeAll => 'All';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get balance => 'Balance';

  @override
  String get monthlyBudget => 'Monthly Budget';

  @override
  String get allWallets => 'All Wallets';

  @override
  String get emptyRecords => 'No records in this range';

  @override
  String get emptyRecordsHint => 'Tap \"Add\" at bottom right to start';

  @override
  String get addRecord => 'Add Record';

  @override
  String get editRecord => 'Edit Record';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get title => 'Title';

  @override
  String get dateTime => 'Date & Time';

  @override
  String get wallet => 'Wallet';

  @override
  String get note => 'Note';

  @override
  String get category => 'Category';

  @override
  String get recent => 'Recent';

  @override
  String get detail => 'Details';

  @override
  String deleted(Object name) {
    return 'Deleted \"$name\"';
  }

  @override
  String get undo => 'Undo';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageZh => '中文';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get sectionSecurity => 'Security';

  @override
  String get sectionLedger => 'Ledger';

  @override
  String get sectionData => 'Data';

  @override
  String get sectionAbout => 'About';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get ok => 'OK';

  @override
  String get edit => 'Edit';

  @override
  String get notSet => 'Not set';

  @override
  String get appLock => 'App Lock (PIN)';

  @override
  String get appLockEnabled => 'Enabled';

  @override
  String get appLockDisabled => 'Disabled';

  @override
  String get biometric => 'Biometric Unlock';

  @override
  String get biometricSub => 'Fingerprint / Face';

  @override
  String get changePin => 'Change PIN';

  @override
  String get setPin => 'Set a 4-digit PIN';

  @override
  String get confirmPin => 'Re-enter PIN to confirm';

  @override
  String get menuBudgetHistory => 'Budget History';

  @override
  String get menuBudgetHistorySub => 'Monthly achievement trend';

  @override
  String get menuWallets => 'Wallets';

  @override
  String get menuWalletsSub => 'Cash, credit card, e-payment separately';

  @override
  String get menuCategories => 'Categories';

  @override
  String get menuCategoriesSub => 'Add and edit custom categories';

  @override
  String get menuRecurring => 'Recurring';

  @override
  String get menuRecurringSub => 'Rent, subscriptions and more';

  @override
  String get exportJson => 'Export JSON Backup';

  @override
  String get exportJsonSub => 'Full backup of all data';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportCsvSub => 'Open in Excel for reconciliation';

  @override
  String get importJson => 'Import JSON Backup';

  @override
  String get importJsonSub => 'Overwrites existing data';

  @override
  String get clearData => 'Clear All Data';

  @override
  String get clearDataSub => 'Cannot be undone';

  @override
  String get version => 'Version';

  @override
  String get sourceCode => 'Source Code';

  @override
  String get filterTitle => 'Filter';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterApply => 'Apply Filter';

  @override
  String get filterDateRange => 'Date Range';

  @override
  String get filterAmountRange => 'Amount Range';

  @override
  String get filterUnlimited => 'Any';

  @override
  String get filterMin => 'Min';

  @override
  String get filterMax => 'Max';

  @override
  String get statsCategoryShare => 'Expense by Category';

  @override
  String statsWeekExpense(Object days) {
    return 'Last $days Days';
  }

  @override
  String get statsHotspot => 'Top 5 Hotspots';

  @override
  String get statsNoExpense => 'No expense data yet';

  @override
  String get advancedReports => 'Advanced Reports (compare, yearly, range)';
}
