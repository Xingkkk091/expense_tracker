class Transaction {
  final String id;
  final String title;
  final double amount;
  final bool isExpense;
  final String category;
  final String note;
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime date;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.category,
    required this.note,
    required this.address,
    this.latitude,
    this.longitude,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'isExpense': isExpense ? 1 : 0,
        'category': category,
        'note': note,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'date': date.toIso8601String(),
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'],
        title: map['title'],
        amount: map['amount'],
        isExpense: map['isExpense'] == 1,
        category: map['category'],
        note: map['note'],
        address: map['address'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        date: DateTime.parse(map['date']),
      );
}

const List<Map<String, dynamic>> kCategories = [
  {'label': '餐飲', 'icon': '🍜'},
  {'label': '交通', 'icon': '🚗'},
  {'label': '購物', 'icon': '🛍️'},
  {'label': '娛樂', 'icon': '🎮'},
  {'label': '醫療', 'icon': '💊'},
  {'label': '住房', 'icon': '🏠'},
  {'label': '教育', 'icon': '📚'},
  {'label': '薪資', 'icon': '💰'},
  {'label': '其他', 'icon': '📋'},
];
