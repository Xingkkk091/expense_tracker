// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '記帳本';

  @override
  String get navRecords => '記錄';

  @override
  String get navStats => '統計';

  @override
  String get navMap => '地圖';

  @override
  String get homeTitle => '我的記帳本';

  @override
  String get statsTitle => '統計分析';

  @override
  String get mapTitle => '消費地圖';

  @override
  String get search => '搜尋';

  @override
  String get searchHint => '搜尋標題、地址、備註…';

  @override
  String get filter => '篩選';

  @override
  String get settings => '設定';

  @override
  String get myCarrier => '我的載具';

  @override
  String get add => '新增';

  @override
  String get scanInvoice => '掃發票';

  @override
  String get balanceWeek => '本週結餘';

  @override
  String get balanceMonth => '本月結餘';

  @override
  String get balanceTotal => '總結餘';

  @override
  String get rangeWeek => '本週';

  @override
  String get rangeMonth => '本月';

  @override
  String get rangeAll => '全部';

  @override
  String get income => '收入';

  @override
  String get expense => '支出';

  @override
  String get balance => '結餘';

  @override
  String get monthlyBudget => '月預算';

  @override
  String get allWallets => '全部錢包';

  @override
  String get emptyRecords => '此區間沒有記錄';

  @override
  String get emptyRecordsHint => '點右下角「新增」開始記帳';

  @override
  String get addRecord => '新增記錄';

  @override
  String get editRecord => '編輯記錄';

  @override
  String get save => '儲存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get saveChanges => '儲存修改';

  @override
  String get title => '標題';

  @override
  String get dateTime => '日期時間';

  @override
  String get wallet => '錢包';

  @override
  String get note => '備註';

  @override
  String get category => '分類';

  @override
  String get recent => '最近使用';

  @override
  String get detail => '明細';

  @override
  String deleted(Object name) {
    return '已刪除「$name」';
  }

  @override
  String get undo => '復原';

  @override
  String get language => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get languageZh => '中文';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get sectionSecurity => '安全';

  @override
  String get sectionLedger => '帳本';

  @override
  String get sectionData => '資料';

  @override
  String get sectionAbout => '關於';

  @override
  String get sectionAppearance => '外觀';
}
