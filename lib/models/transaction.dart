import 'package:flutter/material.dart';

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
  final String wallet; // 帳本/錢包名稱

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
    this.wallet = kDefaultWallet,
  });

  Transaction copyWith({
    String? title,
    double? amount,
    bool? isExpense,
    String? category,
    String? note,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? date,
    String? wallet,
  }) {
    return Transaction(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      isExpense: isExpense ?? this.isExpense,
      category: category ?? this.category,
      note: note ?? this.note,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      date: date ?? this.date,
      wallet: wallet ?? this.wallet,
    );
  }

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
        'wallet': wallet,
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
        wallet: (map['wallet'] as String?) ?? kDefaultWallet,
      );
}

const String kDefaultWallet = '現金';

class CategoryInfo {
  final String label;
  final IconData icon;
  final Color color;
  const CategoryInfo(this.label, this.icon, this.color);
}

/// 內建分類
const List<CategoryInfo> kBuiltInCategories = [
  CategoryInfo('餐飲', Icons.restaurant, Color(0xFFC17B6F)),
  CategoryInfo('交通', Icons.directions_car, Color(0xFF6E8CA0)),
  CategoryInfo('購物', Icons.shopping_bag, Color(0xFF9B8AA6)),
  CategoryInfo('娛樂', Icons.sports_esports, Color(0xFFB58AA0)),
  CategoryInfo('醫療', Icons.medical_services, Color(0xFFB57C70)),
  CategoryInfo('住房', Icons.home, Color(0xFF6F9089)),
  CategoryInfo('教育', Icons.school, Color(0xFF8A86A6)),
  CategoryInfo('薪資', Icons.payments, Color(0xFF7C9070)),
  CategoryInfo('其他', Icons.more_horiz, Color(0xFF8C8678)),
];

/// 動態分類登錄表（內建 + 使用者自訂）。
/// 在 App 啟動時由 CategoryService 載入自訂分類後 setCustom。
class CategoryRegistry {
  CategoryRegistry._();
  static final CategoryRegistry instance = CategoryRegistry._();

  List<CategoryInfo> _custom = [];

  List<CategoryInfo> get all => [...kBuiltInCategories, ..._custom];
  List<CategoryInfo> get custom => List.unmodifiable(_custom);

  void setCustom(List<CategoryInfo> custom) {
    _custom = custom;
  }

  bool isBuiltIn(String label) =>
      kBuiltInCategories.any((c) => c.label == label);
}

/// 向後相容：舊程式引用的 kCategories
List<CategoryInfo> get kCategories => CategoryRegistry.instance.all;

CategoryInfo categoryOf(String label) => CategoryRegistry.instance.all.firstWhere(
      (c) => c.label == label,
      orElse: () => kBuiltInCategories.last,
    );
