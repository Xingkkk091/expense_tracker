import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'記帳本'**
  String get appTitle;

  /// No description provided for @navRecords.
  ///
  /// In zh, this message translates to:
  /// **'記錄'**
  String get navRecords;

  /// No description provided for @navStats.
  ///
  /// In zh, this message translates to:
  /// **'統計'**
  String get navStats;

  /// No description provided for @navMap.
  ///
  /// In zh, this message translates to:
  /// **'地圖'**
  String get navMap;

  /// No description provided for @homeTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的記帳本'**
  String get homeTitle;

  /// No description provided for @statsTitle.
  ///
  /// In zh, this message translates to:
  /// **'統計分析'**
  String get statsTitle;

  /// No description provided for @mapTitle.
  ///
  /// In zh, this message translates to:
  /// **'消費地圖'**
  String get mapTitle;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜尋'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜尋標題、地址、備註…'**
  String get searchHint;

  /// No description provided for @filter.
  ///
  /// In zh, this message translates to:
  /// **'篩選'**
  String get filter;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @myCarrier.
  ///
  /// In zh, this message translates to:
  /// **'我的載具'**
  String get myCarrier;

  /// No description provided for @add.
  ///
  /// In zh, this message translates to:
  /// **'新增'**
  String get add;

  /// No description provided for @scanInvoice.
  ///
  /// In zh, this message translates to:
  /// **'掃發票'**
  String get scanInvoice;

  /// No description provided for @balanceWeek.
  ///
  /// In zh, this message translates to:
  /// **'本週結餘'**
  String get balanceWeek;

  /// No description provided for @balanceMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月結餘'**
  String get balanceMonth;

  /// No description provided for @balanceTotal.
  ///
  /// In zh, this message translates to:
  /// **'總結餘'**
  String get balanceTotal;

  /// No description provided for @rangeWeek.
  ///
  /// In zh, this message translates to:
  /// **'本週'**
  String get rangeWeek;

  /// No description provided for @rangeMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月'**
  String get rangeMonth;

  /// No description provided for @rangeAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get rangeAll;

  /// No description provided for @income.
  ///
  /// In zh, this message translates to:
  /// **'收入'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In zh, this message translates to:
  /// **'支出'**
  String get expense;

  /// No description provided for @balance.
  ///
  /// In zh, this message translates to:
  /// **'結餘'**
  String get balance;

  /// No description provided for @monthlyBudget.
  ///
  /// In zh, this message translates to:
  /// **'月預算'**
  String get monthlyBudget;

  /// No description provided for @allWallets.
  ///
  /// In zh, this message translates to:
  /// **'全部錢包'**
  String get allWallets;

  /// No description provided for @emptyRecords.
  ///
  /// In zh, this message translates to:
  /// **'此區間沒有記錄'**
  String get emptyRecords;

  /// No description provided for @emptyRecordsHint.
  ///
  /// In zh, this message translates to:
  /// **'點右下角「新增」開始記帳'**
  String get emptyRecordsHint;

  /// No description provided for @addRecord.
  ///
  /// In zh, this message translates to:
  /// **'新增記錄'**
  String get addRecord;

  /// No description provided for @editRecord.
  ///
  /// In zh, this message translates to:
  /// **'編輯記錄'**
  String get editRecord;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'儲存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'刪除'**
  String get delete;

  /// No description provided for @saveChanges.
  ///
  /// In zh, this message translates to:
  /// **'儲存修改'**
  String get saveChanges;

  /// No description provided for @title.
  ///
  /// In zh, this message translates to:
  /// **'標題'**
  String get title;

  /// No description provided for @dateTime.
  ///
  /// In zh, this message translates to:
  /// **'日期時間'**
  String get dateTime;

  /// No description provided for @wallet.
  ///
  /// In zh, this message translates to:
  /// **'錢包'**
  String get wallet;

  /// No description provided for @note.
  ///
  /// In zh, this message translates to:
  /// **'備註'**
  String get note;

  /// No description provided for @category.
  ///
  /// In zh, this message translates to:
  /// **'分類'**
  String get category;

  /// No description provided for @recent.
  ///
  /// In zh, this message translates to:
  /// **'最近使用'**
  String get recent;

  /// No description provided for @detail.
  ///
  /// In zh, this message translates to:
  /// **'明細'**
  String get detail;

  /// No description provided for @deleted.
  ///
  /// In zh, this message translates to:
  /// **'已刪除「{name}」'**
  String deleted(Object name);

  /// No description provided for @undo.
  ///
  /// In zh, this message translates to:
  /// **'復原'**
  String get undo;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'語言'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟隨系統'**
  String get languageSystem;

  /// No description provided for @languageZh.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageJa.
  ///
  /// In zh, this message translates to:
  /// **'日本語'**
  String get languageJa;

  /// No description provided for @sectionSecurity.
  ///
  /// In zh, this message translates to:
  /// **'安全'**
  String get sectionSecurity;

  /// No description provided for @sectionLedger.
  ///
  /// In zh, this message translates to:
  /// **'帳本'**
  String get sectionLedger;

  /// No description provided for @sectionData.
  ///
  /// In zh, this message translates to:
  /// **'資料'**
  String get sectionData;

  /// No description provided for @sectionAbout.
  ///
  /// In zh, this message translates to:
  /// **'關於'**
  String get sectionAbout;

  /// No description provided for @sectionAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外觀'**
  String get sectionAppearance;
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
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
