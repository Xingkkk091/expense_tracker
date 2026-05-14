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
}
