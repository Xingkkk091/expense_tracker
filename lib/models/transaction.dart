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

class CategoryInfo {
  final String label;
  final IconData icon;
  final Color color;
  const CategoryInfo(this.label, this.icon, this.color);
}

const List<CategoryInfo> kCategories = [
  CategoryInfo('餐飲', Icons.restaurant,         Color(0xFFFF7043)),
  CategoryInfo('交通', Icons.directions_car,     Color(0xFF42A5F5)),
  CategoryInfo('購物', Icons.shopping_bag,       Color(0xFFAB47BC)),
  CategoryInfo('娛樂', Icons.sports_esports,     Color(0xFFEC407A)),
  CategoryInfo('醫療', Icons.medical_services,   Color(0xFFEF5350)),
  CategoryInfo('住房', Icons.home,               Color(0xFF26A69A)),
  CategoryInfo('教育', Icons.school,             Color(0xFF7E57C2)),
  CategoryInfo('薪資', Icons.payments,           Color(0xFF66BB6A)),
  CategoryInfo('其他', Icons.more_horiz,         Color(0xFF78909C)),
];

CategoryInfo categoryOf(String label) => kCategories.firstWhere(
      (c) => c.label == label,
      orElse: () => kCategories.last,
    );
