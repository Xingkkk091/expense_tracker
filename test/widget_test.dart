import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/services/invoice_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transaction model', () {
    test('toMap / fromMap roundtrip', () {
      final t = Transaction(
        id: 'abc',
        title: '咖啡',
        amount: 80,
        isExpense: true,
        category: '餐飲',
        note: '早上喝的',
        address: '台北市信義區',
        latitude: 25.0,
        longitude: 121.5,
        date: DateTime(2026, 5, 14, 9, 30),
      );
      final map = t.toMap();
      final restored = Transaction.fromMap(map);
      expect(restored.id, t.id);
      expect(restored.title, t.title);
      expect(restored.amount, t.amount);
      expect(restored.isExpense, t.isExpense);
      expect(restored.latitude, t.latitude);
      expect(restored.date.toIso8601String(), t.date.toIso8601String());
    });
  });

  group('CategoryInfo lookup', () {
    test('built-in lookup', () {
      expect(categoryOf('餐飲').label, '餐飲');
      expect(categoryOf('其他').label, '其他');
    });
    test('unknown category falls back to 其他', () {
      expect(categoryOf('不存在').label, '其他');
    });
  });

  group('InvoiceParser', () {
    test('rejects empty input', () {
      expect(InvoiceParser.tryParse(''), isNull);
    });
    test('rejects right-side QR (** prefix)', () {
      expect(InvoiceParser.tryParse('**:1:1:0:TWD:test:1:50'), isNull);
    });
    test('rejects malformed left code', () {
      expect(InvoiceParser.tryParse('not-a-real-invoice'), isNull);
    });
  });
}
