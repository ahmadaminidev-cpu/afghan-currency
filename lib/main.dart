import 'package:flutter/material.dart';

import 'data/rate_repository.dart';
import 'screens/currency_home_page.dart';

void main() {
  runApp(const CurrencyApp());
}

class CurrencyApp extends StatelessWidget {
  const CurrencyApp({super.key, this.repository});

  final RateRepository? repository;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF14231D);
    const green = Color(0xFF08745B);
    const cream = Color(0xFFF5F3EC);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: Brightness.light,
      surface: cream,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Afghani Rates',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: cream,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 66,
          elevation: 0,
          backgroundColor: const Color(0xFFF8FAF8),
          indicatorColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? green
                  : const Color(0xFF7D8A85),
              size: 25,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? green
                  : const Color(0xFF7D8A85),
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: .06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: green, width: 1.5),
          ),
        ),
      ),
      home: CurrencyHomePage(repository: repository ?? RemoteRateRepository()),
    );
  }
}
