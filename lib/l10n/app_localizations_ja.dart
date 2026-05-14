// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '家計簿';

  @override
  String get navRecords => '記録';

  @override
  String get navStats => '統計';

  @override
  String get navMap => 'マップ';

  @override
  String get homeTitle => 'マイ家計簿';

  @override
  String get statsTitle => '統計分析';

  @override
  String get mapTitle => '消費マップ';

  @override
  String get search => '検索';

  @override
  String get searchHint => 'タイトル・住所・メモを検索…';

  @override
  String get filter => '絞り込み';

  @override
  String get settings => '設定';

  @override
  String get myCarrier => 'マイキャリア';

  @override
  String get add => '追加';

  @override
  String get scanInvoice => 'スキャン';

  @override
  String get balanceWeek => '今週の収支';

  @override
  String get balanceMonth => '今月の収支';

  @override
  String get balanceTotal => '合計収支';

  @override
  String get rangeWeek => '今週';

  @override
  String get rangeMonth => '今月';

  @override
  String get rangeAll => '全て';

  @override
  String get income => '収入';

  @override
  String get expense => '支出';

  @override
  String get balance => '収支';

  @override
  String get monthlyBudget => '月予算';

  @override
  String get allWallets => '全ての財布';

  @override
  String get emptyRecords => 'この期間に記録はありません';

  @override
  String get emptyRecordsHint => '右下の「追加」から記録を始めましょう';

  @override
  String get addRecord => '記録を追加';

  @override
  String get editRecord => '記録を編集';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get saveChanges => '変更を保存';

  @override
  String get title => 'タイトル';

  @override
  String get dateTime => '日時';

  @override
  String get wallet => '財布';

  @override
  String get note => 'メモ';

  @override
  String get category => 'カテゴリ';

  @override
  String get recent => '最近使用';

  @override
  String get detail => '明細';

  @override
  String deleted(Object name) {
    return '「$name」を削除しました';
  }

  @override
  String get undo => '元に戻す';

  @override
  String get language => '言語';

  @override
  String get languageSystem => 'システムに従う';

  @override
  String get languageZh => '中文';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get sectionSecurity => 'セキュリティ';

  @override
  String get sectionLedger => '家計簿';

  @override
  String get sectionData => 'データ';

  @override
  String get sectionAbout => 'アプリについて';

  @override
  String get sectionAppearance => '外観';

  @override
  String get ok => 'OK';

  @override
  String get edit => '編集';

  @override
  String get notSet => '未設定';

  @override
  String get appLock => 'アプリロック（PIN）';

  @override
  String get appLockEnabled => '有効';

  @override
  String get appLockDisabled => '無効';

  @override
  String get biometric => '生体認証ロック解除';

  @override
  String get biometricSub => '指紋 / 顔';

  @override
  String get changePin => 'PINを変更';

  @override
  String get setPin => '4桁のPINを設定';

  @override
  String get confirmPin => '確認のためPINを再入力';

  @override
  String get menuBudgetHistory => '予算履歴';

  @override
  String get menuBudgetHistorySub => '毎月の達成率の推移';

  @override
  String get menuWallets => '財布';

  @override
  String get menuWalletsSub => '現金・クレカ・電子決済を分けて記録';

  @override
  String get menuCategories => 'カテゴリ管理';

  @override
  String get menuCategoriesSub => 'カスタムカテゴリの追加・編集';

  @override
  String get menuRecurring => '繰り返し記帳';

  @override
  String get menuRecurringSub => '家賃・サブスクなどの定期項目';

  @override
  String get exportJson => 'JSONバックアップを書き出し';

  @override
  String get exportJsonSub => '全データの完全バックアップ';

  @override
  String get exportCsv => 'CSVを書き出し';

  @override
  String get exportCsvSub => 'Excelで開いて照合できます';

  @override
  String get importJson => 'JSONバックアップを取り込み';

  @override
  String get importJsonSub => '既存データを上書きします';

  @override
  String get clearData => '全データを消去';

  @override
  String get clearDataSub => '元に戻せません';

  @override
  String get version => 'バージョン';

  @override
  String get sourceCode => 'ソースコード';

  @override
  String get filterTitle => '絞り込み';

  @override
  String get filterReset => 'リセット';

  @override
  String get filterApply => '絞り込みを適用';

  @override
  String get filterDateRange => '日付範囲';

  @override
  String get filterAmountRange => '金額範囲';

  @override
  String get filterUnlimited => '指定なし';

  @override
  String get filterMin => '最小';

  @override
  String get filterMax => '最大';

  @override
  String get statsCategoryShare => 'カテゴリ別支出';

  @override
  String statsWeekExpense(Object days) {
    return '直近$days日の支出';
  }

  @override
  String get statsHotspot => '消費ホットスポット Top 5';

  @override
  String get statsNoExpense => '支出データがありません';

  @override
  String get advancedReports => '詳細レポート（月比較・年間・範囲分析）';
}
