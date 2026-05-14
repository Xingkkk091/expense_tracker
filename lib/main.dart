import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/app_lock_screen.dart';
import 'screens/carrier_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_service.dart';
import 'services/error_reporter.dart';

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
    const seed = Color(0xFF4F6AF5);
    return MaterialApp(
      title: '記帳本',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildTheme(Brightness.light, seed),
      darkTheme: _buildTheme(Brightness.dark, seed),
      routes: {
        '/settings': (_) => const SettingsScreen(),
        '/carrier': (_) => const CarrierScreen(),
      },
      home: const _BootGate(),
    );
  }

  ThemeData _buildTheme(Brightness b, Color seed) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: b),
      useMaterial3: true,
    );
    // 提升 hint 對比度 (#34)
    final hintColor = b == Brightness.dark
        ? Colors.white.withValues(alpha: 0.75)
        : Colors.black.withValues(alpha: 0.65);
    return base.copyWith(
      textTheme: b == Brightness.dark
          ? GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme)
          : GoogleFonts.notoSansTextTheme(),
      hintColor: hintColor,
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        hintStyle: TextStyle(color: hintColor),
      ),
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
