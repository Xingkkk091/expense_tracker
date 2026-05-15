import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/transaction_provider.dart';
import 'services/locale_controller.dart';
import 'screens/app_lock_screen.dart';
import 'screens/budget_history_screen.dart';
import 'screens/carrier_screen.dart';
import 'screens/category_manage_screen.dart';
import 'screens/home_screen.dart';
import 'screens/food_picker_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/recurring_manage_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/wallet_manage_screen.dart';
import 'services/auth_service.dart';
import 'services/error_reporter.dart';
import 'services/recurring_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ErrorReporter().init();
  final localeController = LocaleController();
  await localeController.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider.value(value: localeController),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>().locale;
    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleController.supported,
      routes: {
        '/settings': (_) => const SettingsScreen(),
        '/carrier': (_) => const CarrierScreen(),
        '/categories': (_) => const CategoryManageScreen(),
        '/wallets': (_) => const WalletManageScreen(),
        '/recurring': (_) => const RecurringManageScreen(),
        '/budget-history': (_) => const BudgetHistoryScreen(),
        '/reports': (_) => const ReportsScreen(),
        '/food-picker': (_) => const FoodPickerScreen(),
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
    // 啟動關鍵路徑只查 onboarding/lock，盡快顯示畫面
    final seen = await OnboardingScreen.hasSeen();
    if (!mounted) return;
    if (!seen) {
      setState(() => _stage = _BootStage.onboarding);
    } else {
      final lock = await AuthService().isLockEnabled();
      if (!mounted) return;
      setState(() => _stage = lock ? _BootStage.locked : _BootStage.ready);
    }
    // 重複記帳補產生：移到背景執行，不阻塞啟動
    Future.microtask(() async {
      try {
        await RecurringService().generateDue();
      } catch (e, st) {
        ErrorReporter().log('RecurringService.generateDue', e, st);
      }
    });
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
