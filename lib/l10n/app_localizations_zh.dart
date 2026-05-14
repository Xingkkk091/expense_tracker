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

  @override
  String get ok => '確定';

  @override
  String get edit => '編輯';

  @override
  String get notSet => '未設定';

  @override
  String get appLock => 'App 鎖（PIN）';

  @override
  String get appLockEnabled => '已啟用';

  @override
  String get appLockDisabled => '未啟用';

  @override
  String get biometric => '生物辨識解鎖';

  @override
  String get biometricSub => '指紋 / 臉部';

  @override
  String get changePin => '變更 PIN';

  @override
  String get setPin => '設定 4 位 PIN';

  @override
  String get confirmPin => '再次輸入 PIN 確認';

  @override
  String get menuBudgetHistory => '預算歷史';

  @override
  String get menuBudgetHistorySub => '每月達成率趨勢';

  @override
  String get menuWallets => '帳本 / 錢包';

  @override
  String get menuWalletsSub => '現金、信用卡、電子支付分開記';

  @override
  String get menuCategories => '分類管理';

  @override
  String get menuCategoriesSub => '新增、編輯自訂分類';

  @override
  String get menuRecurring => '重複記帳';

  @override
  String get menuRecurringSub => '房租、訂閱等定期項目';

  @override
  String get exportJson => '匯出 JSON 備份';

  @override
  String get exportJsonSub => '完整備份所有資料';

  @override
  String get exportCsv => '匯出 CSV';

  @override
  String get exportCsvSub => '可用 Excel 開啟對帳';

  @override
  String get importJson => '匯入 JSON 備份';

  @override
  String get importJsonSub => '會覆蓋現有資料';

  @override
  String get clearData => '清除所有資料';

  @override
  String get clearDataSub => '不可復原';

  @override
  String get version => '版本';

  @override
  String get sourceCode => '原始碼';

  @override
  String get filterTitle => '篩選';

  @override
  String get filterReset => '重設';

  @override
  String get filterApply => '套用篩選';

  @override
  String get filterDateRange => '日期範圍';

  @override
  String get filterAmountRange => '金額範圍';

  @override
  String get filterUnlimited => '不限';

  @override
  String get filterMin => '最小';

  @override
  String get filterMax => '最大';

  @override
  String get statsCategoryShare => '支出分類佔比';

  @override
  String statsWeekExpense(Object days) {
    return '近 $days 天支出';
  }

  @override
  String get statsHotspot => '消費熱點 Top 5';

  @override
  String get statsNoExpense => '尚無支出資料';

  @override
  String get advancedReports => '進階報表（月度比較・年度・區間分析）';
}
