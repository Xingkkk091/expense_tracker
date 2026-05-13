import 'package:shared_preferences/shared_preferences.dart';

class BudgetService {
  static const _key = 'monthly_budget';

  Future<double> getMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key) ?? 0;
  }

  Future<void> setMonthlyBudget(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, value);
  }
}
