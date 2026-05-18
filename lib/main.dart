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
import 'screens/invoice_lottery_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/wallet_manage_screen.dart';
import 'screens/wallet_transfer_screen.dart';
import 'services/auth_service.dart';
import 'services/error_reporter.dart';
import 'services/notification_service.dart';
import 'services/recurring_service.dart';
import 'services/widget_service.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/invoice_scanner_screen.dart';
import 'services/invoice_parser.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 啟動時的初始化全部包 try-catch；任何單一服務失敗都不該擋住 App 啟動
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

class _BootGateState extends State<_BootGate> with WidgetsBindingObserver {
  _BootStage _stage = _BootStage.loading;
  Uri? _pendingWidgetUri;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
    _listenWidgetClicks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App 回前景時強制推一次 widget，確保桌面數字最新
    if (state == AppLifecycleState.resumed && mounted) {
      // ignore: use_build_context_synchronously
      final ctx = appNavigatorKey.currentContext ?? context;
      try {
        ctx.read<TransactionProvider>().load();
      } catch (_) {/* ignore */}
    }
  }

  void _listenWidgetClicks() {
    try {
      WidgetService().clicks.listen(
        (uri) {
          if (uri != null) _handleWidgetUri(uri);
        },
        onError: (e) {
          ErrorReporter().log('widgetClicks', e);
        },
      );
    } catch (e, st) {
      // 若插件未註冊就完全略過，不能讓 widget 整個拖垮 App
      ErrorReporter().log('listenWidgetClicks', e, st);
    }
  }

  Future<void> _handleWidgetUri(Uri uri) async {
    // 等到 ready 狀態才導航
    while (_stage != _BootStage.ready) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    switch (uri.host) {
      case 'add':
        nav.push(MaterialPageRoute(
            builder: (_) => const AddTransactionScreen()));
        break;
      case 'scan':
        final invoice = await nav.push<InvoiceData>(
          MaterialPageRoute(builder: (_) => const InvoiceScannerScreen()),
        );
        if (invoice != null) {
          nav.push(MaterialPageRoute(
            builder: (_) => AddTransactionScreen(invoicePrefill: invoice),
          ));
        }
        break;
      case 'home':
      default:
        // 已在 home
        break;
    }
  }

  Future<void> _bootstrap() async {
    // 取冷啟動 URI（widget 點擊喚醒）；失敗也 OK
    try {
      _pendingWidgetUri = await WidgetService().initialUri();
    } catch (_) {
      _pendingWidgetUri = null;
    }

    // 啟動關鍵路徑只查 onboarding/lock，盡快顯示畫面
    final seen = await OnboardingScreen.hasSeen();
    if (!mounted) return;
    if (!seen) {
      setState(() => _stage = _BootStage.onboarding);
    } else {
      final lock = await AuthService().isLockEnabled();
      if (!mounted) return;
      setState(() => _stage = lock ? _BootStage.locked : _BootStage.ready);
      // 進入 ready 後處理 pending URI
      if (_stage == _BootStage.ready && _pendingWidgetUri != null) {
        _handleWidgetUri(_pendingWidgetUri!);
        _pendingWidgetUri = null;
      }
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
            onUnlocked: () {
              setState(() => _stage = _BootStage.ready);
              if (_pendingWidgetUri != null) {
                _handleWidgetUri(_pendingWidgetUri!);
                _pendingWidgetUri = null;
              }
            });
      case _BootStage.ready:
        return const HomeScreen();
    }
  }
}
