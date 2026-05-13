/// 台灣電子發票 QR Code 解析器
/// 規格：財政部「電子發票證明聯」格式
class InvoiceItem {
  final String name;
  final int quantity;
  final double price;
  InvoiceItem({required this.name, required this.quantity, required this.price});
}

class InvoiceData {
  final String number;          // 發票號碼，e.g. "AB-12345678"
  final DateTime date;          // 發票日期
  final double total;           // 總計額（元）
  final double salesAmount;     // 銷售額（未稅）
  final String sellerTaxId;     // 賣方統一編號
  final String buyerTaxId;      // 買方統一編號（無則為空）
  final List<InvoiceItem> items;

  InvoiceData({
    required this.number,
    required this.date,
    required this.total,
    required this.salesAmount,
    required this.sellerTaxId,
    required this.buyerTaxId,
    required this.items,
  });

  String get displayNumber {
    if (number.length == 10) {
      return '${number.substring(0, 2)}-${number.substring(2)}';
    }
    return number;
  }
}

class InvoiceParser {
  /// 解析左方 QR Code 字串。失敗回傳 null。
  /// 完整左碼 ≥ 77 字元（前 77 為固定欄位）
  static InvoiceData? parseLeftQR(String raw) {
    try {
      if (raw.length < 77) return null;
      final number = raw.substring(0, 10);
      // 發票字軌格式：2 字母 + 8 數字
      if (!RegExp(r'^[A-Z]{2}\d{8}$').hasMatch(number)) return null;

      // 民國年月日 (3+2+2)
      final dateStr = raw.substring(10, 17);
      final rocYear = int.tryParse(dateStr.substring(0, 3));
      final month = int.tryParse(dateStr.substring(3, 5));
      final day = int.tryParse(dateStr.substring(5, 7));
      if (rocYear == null || month == null || day == null) return null;
      final date = DateTime(rocYear + 1911, month, day);

      // 17~21: 隨機碼 (略)
      final salesHex = raw.substring(21, 29);
      final totalHex = raw.substring(29, 37);
      final salesAmount = int.parse(salesHex, radix: 16).toDouble();
      final total = int.parse(totalHex, radix: 16).toDouble();

      final buyerTaxId = raw.substring(37, 45);
      final sellerTaxId = raw.substring(45, 53);
      // 53~77: 加密驗證碼 (略)

      // 第 78 字元起為商品明細，用 ":" 分隔
      final items = <InvoiceItem>[];
      if (raw.length > 77) {
        final tail = raw.substring(77);
        final parts = tail.split(':');
        // parts[0]=投保編號或空 parts[1]=本卡筆數 parts[2]=總筆數
        // parts[3]=編碼方式 parts[4]=幣別 parts[5..] = 品名:數量:單價
        if (parts.length >= 5) {
          for (int i = 5; i + 2 < parts.length; i += 3) {
            final name = parts[i].trim();
            final qty = int.tryParse(parts[i + 1]) ?? 1;
            final price = double.tryParse(parts[i + 2]) ?? 0;
            if (name.isNotEmpty) {
              items.add(InvoiceItem(name: name, quantity: qty, price: price));
            }
          }
        }
      }

      return InvoiceData(
        number: number,
        date: date,
        total: total > 0 ? total : salesAmount,
        salesAmount: salesAmount,
        sellerTaxId: sellerTaxId.replaceAll('0' * 8, ''),
        buyerTaxId: buyerTaxId.replaceAll('0' * 8, ''),
        items: items,
      );
    } catch (_) {
      return null;
    }
  }

  /// 試著從掃描到的字串自動辨識（左碼/右碼/其他）
  static InvoiceData? tryParse(String raw) {
    // 右方碼以 "**" 起頭，不含主資訊，這版本只處理左碼
    if (raw.startsWith('**')) return null;
    return parseLeftQR(raw);
  }
}
