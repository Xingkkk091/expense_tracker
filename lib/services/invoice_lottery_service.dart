import 'package:shared_preferences/shared_preferences.dart';

/// 統一發票中獎號碼資料（單期）
class WinningNumbers {
  final String period;        // e.g. "113-11" (民國年-期別 11=11月12月期)
  final String special;       // 8 位 — 特別獎 1000 萬
  final String grand;         // 8 位 — 特獎 200 萬
  final List<String> first;   // 3 組 8 位 — 頭獎 20 萬

  WinningNumbers({
    required this.period,
    required this.special,
    required this.grand,
    required this.first,
  });

  Map<String, dynamic> toMap() => {
        'period': period,
        'special': special,
        'grand': grand,
        'first': first,
      };

  factory WinningNumbers.fromMap(Map<String, dynamic> m) => WinningNumbers(
        period: m['period'],
        special: m['special'],
        grand: m['grand'],
        first: List<String>.from(m['first'] as List),
      );
}

/// 比對結果
class LotteryHit {
  final String invoiceNumber;
  final int prize;           // 中獎金額（元）
  final String label;        // 獎別文字
  LotteryHit(this.invoiceNumber, this.prize, this.label);
}

class InvoiceLotteryService {
  static const _kKey = 'invoice_winning_numbers';

  /// 從備註抓出發票號碼（pattern: 「發票 XX-XXXXXXXX」或「發票 XXXXXXXXXX」）
  static final RegExp _invoicePattern =
      RegExp(r'發票\s+([A-Z]{2})[\-\s]?(\d{8})');

  static String? extractInvoiceNumber(String note) {
    final m = _invoicePattern.firstMatch(note);
    if (m == null) return null;
    return '${m.group(1)}${m.group(2)}'; // 10 碼: AA12345678
  }

  Future<WinningNumbers?> loadWinning() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kKey);
    if (s == null) return null;
    try {
      // 簡單 csv 序列化: period|special|grand|first1,first2,first3
      final parts = s.split('|');
      if (parts.length != 4) return null;
      return WinningNumbers(
        period: parts[0],
        special: parts[1],
        grand: parts[2],
        first: parts[3].split(','),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWinning(WinningNumbers w) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey,
        '${w.period}|${w.special}|${w.grand}|${w.first.join(",")}');
  }

  /// 比對單張發票（10 碼例 AA12345678 取後 8 碼）
  static LotteryHit? check(String invoiceNumber, WinningNumbers w) {
    if (invoiceNumber.length < 8) return null;
    final n = invoiceNumber.substring(invoiceNumber.length - 8);

    if (n == w.special) return LotteryHit(invoiceNumber, 10000000, '特別獎');
    if (n == w.grand) return LotteryHit(invoiceNumber, 2000000, '特獎');

    for (final first in w.first) {
      if (n == first) return LotteryHit(invoiceNumber, 200000, '頭獎');
    }
    // 末 7~3 碼比對頭獎號碼（任一組）
    for (final first in w.first) {
      if (first.length != 8) continue;
      if (n.substring(1) == first.substring(1)) {
        return LotteryHit(invoiceNumber, 40000, '二獎');
      }
      if (n.substring(2) == first.substring(2)) {
        return LotteryHit(invoiceNumber, 10000, '三獎');
      }
      if (n.substring(3) == first.substring(3)) {
        return LotteryHit(invoiceNumber, 4000, '四獎');
      }
      if (n.substring(4) == first.substring(4)) {
        return LotteryHit(invoiceNumber, 1000, '五獎');
      }
      if (n.substring(5) == first.substring(5)) {
        return LotteryHit(invoiceNumber, 200, '六獎');
      }
    }
    return null;
  }
}
