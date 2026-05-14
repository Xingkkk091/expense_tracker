import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/app_lock_screen.dart';
import 'screens/budget_history_screen.dart';
import 'screens/carrier_screen.dart';
import 'screens/category_manage_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/recurring_manage_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/wallet_manage_screen.dart';
import 'services/auth_service.dart';
import 'services/error_reporter.dart';
import 'services/recurring_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ErrorReporter().init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => TransactionProvider(),
      child: const ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '記帳本',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routes: {
        '/settings': (_) => const SettingsScreen(),
        '/carrier': (_) => const CarrierScreen(),
        '/categories': (_) => const CategoryManageScreen(),
        '/wallets': (_) => const WalletManageScreen(),
        '/recurring': (_) => const RecurringManageScreen(),
        '/budget-history': (_) => const BudgetHistoryScreen(),
      },
      home: const _BootGate(),
    );
  }
}

/// 啟動流程：onboarding -> app lock -> home
class _BootGate extends StatefulWidget {
  const _BootGate();

  @override
  State<_BootGate> createState() => _BootGateState();
}

enum _BootStage { loading, onboarding, locked, ready }

class _BootGateState extends State<_BootGate> {
  _BootStage _stage = _BootStage.loading;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 重複記帳：補產生待發生的交易
    try {
      await RecurringService().generateDue();
    } catch (e, st) {
      ErrorReporter().log('RecurringService.generateDue', e, st);
    }
    final seen = await OnboardingScreen.hasSeen();
    if (!seen) {
      setState(() => _stage = _BootStage.onboarding);
      return;
    }
    final lock = await AuthService().isLockEnabled();
    setState(() => _stage = lock ? _BootStage.locked : _BootStage.ready);
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _BootStage.loading:
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      case _BootStage.onboarding:
        return OnboardingScreen(
          onDone: () async {
            final lock = await AuthService().isLockEnabled();
            setState(() =>
                _stage = lock ? _BootStage.locked : _BootStage.ready);
          },
        );
      case _BootStage.locked:
        return AppLockScreen(
            onUnlocked: () => setState(() => _stage = _BootStage.ready));
      case _BootStage.ready:
        return const HomeScreen();
    }
  }
}
