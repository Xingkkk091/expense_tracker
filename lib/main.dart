import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/transaction_provider.dart';
import 'services/locale_controller.dart';
import 'screens/app_lock_screen.dart';
import 'screens/auto_backup_screen.dart';
import 'screens/budget_history_screen.dart';
import 'screens/carrier_screen.dart';
import 'screens/category_manage_screen.dart';
import 'screens/home_screen.dart';
import 'screens/food_picker_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/recurring_manage_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/invoice_lottery_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/wallet_manage_screen.dart';
import 'screens/wallet_transfer_screen.dart';
import 'services/auth_service.dart';
import 'services/auto_backup_service.dart';
import 'services/error_reporter.dart';
import 'services/notification_service.dart';
import 'services/recurring_service.dart';
import 'theme/app_theme.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ErrorReporter().init();
  } catch (_) {/* ignore */}
  try {
    await NotificationService().init();
  } catch (_) {/* ignore */}
  final localeController = LocaleController();
  try {
    await localeController.load();
  } catch (_) {/* ignore */}
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

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>().locale;
    return MaterialApp(
      navigatorKey: appNavigatorKey,
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
        '/wallet-transfer': (_) => const WalletTransferScreen(),
        '/subscriptions': (_) => const SubscriptionScreen(),
        '/invoice-lottery': (_) => const InvoiceLotteryScreen(),
        '/auto-backup': (_) => const AutoBackupScreen(),
      },
      home: const _BootGate(),
    );
  }
}

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
    final seen = await OnboardingScreen.hasSeen();
    if (!mounted) return;
    if (!seen) {
      setState(() => _stage = _BootStage.onboarding);
    } else {
      final lock = await AuthService().isLockEnabled();
      if (!mounted) return;
      setState(() => _stage = lock ? _BootStage.locked : _BootStage.ready);
      // 進入 ready 後檢查是否有可還原備份
      if (_stage == _BootStage.ready) {
        _checkRecoverableBackup();
      }
    }
    Future.microtask(() async {
      try {
        await RecurringService().generateDue();
      } catch (e, st) {
        ErrorReporter().log('RecurringService.generateDue', e, st);
      }
    });
  }

  Future<void> _checkRecoverableBackup() async {
    try {
      final svc = AutoBackupService();
      final recoverable = await svc.findRecoverableIfDbEmpty();
      if (recoverable == null) return;
      // 等待第一個 frame 才彈
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final ctx = appNavigatorKey.currentContext ?? context;
      final restore = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('偵測到先前的備份'),
          content: Text(
              '目前沒有記帳資料，但找到 ${DateFormat('yyyy/MM/dd HH:mm').format(recoverable.createdAt)} '
              '的自動備份'
              '${recoverable.txCount != null ? "（${recoverable.txCount} 筆交易）" : ""}。\n\n'
              '要還原嗎？'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('暫時不用')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('還原'),
            ),
          ],
        ),
      );
      if (restore == true && mounted) {
        final ok = await svc.restoreFromFile(recoverable.path);
        if (ok && mounted) {
          await ctx.read<TransactionProvider>().load();
          if (mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
              content: Text('資料已還原'),
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      }
    } catch (e, st) {
      ErrorReporter().log('checkRecoverableBackup', e, st);
    }
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
