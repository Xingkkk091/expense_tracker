import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';

void main() {
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
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        textTheme: GoogleFonts.notoSansTextTheme(),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        textTheme:
            GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
