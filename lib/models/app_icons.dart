import 'package:flutter/material.dart';

/// 自訂分類 / 錢包可選的圖示（全部 const，避免 icon tree-shaking 問題）。
/// 資料庫只存「索引」，不存 codePoint。
const List<IconData> kSelectableIcons = [
  Icons.restaurant,
  Icons.local_cafe,
  Icons.directions_car,
  Icons.train,
  Icons.shopping_bag,
  Icons.shopping_cart,
  Icons.sports_esports,
  Icons.movie,
  Icons.medical_services,
  Icons.fitness_center,
  Icons.home,
  Icons.lightbulb,
  Icons.school,
  Icons.menu_book,
  Icons.payments,
  Icons.savings,
  Icons.pets,
  Icons.flight,
  Icons.card_giftcard,
  Icons.checkroom,
  Icons.phone_iphone,
  Icons.local_gas_station,
  Icons.local_hospital,
  Icons.more_horiz,
];

IconData iconByIndex(int index) {
  if (index < 0 || index >= kSelectableIcons.length) {
    return Icons.more_horiz;
  }
  return kSelectableIcons[index];
}

/// 錢包可選圖示
const List<IconData> kWalletIcons = [
  Icons.account_balance_wallet,
  Icons.payments,
  Icons.credit_card,
  Icons.account_balance,
  Icons.savings,
  Icons.attach_money,
  Icons.qr_code,
  Icons.phone_iphone,
];

IconData walletIconByIndex(int index) {
  if (index < 0 || index >= kWalletIcons.length) {
    return Icons.account_balance_wallet;
  }
  return kWalletIcons[index];
}
