import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/localization_service.dart';

// ── Global Theme Tokens ─────────────────────────────────────────────────────
const _charcoal = Color(0xFF1e2820);
const _moss     = Color(0xFF3d5a2e);
const _leaf     = Color(0xFF5c8a3c);
const _lime     = Color(0xFFa8c96e);
const _cream    = Color(0xFFf5f0e8);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localizationService = LocalizationService();
  await localizationService.init();

  runApp(
    ChangeNotifierProvider.value(
      value: localizationService,
      child: const CashewSenseApp(),
    ),
  );
}

class CashewSenseApp extends StatelessWidget {
  const CashewSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CashewSense',
      theme: ThemeData(
        scaffoldBackgroundColor: _charcoal,
        colorScheme: ColorScheme.dark(
          primary:   _leaf,
          secondary: _lime,
          surface:   _charcoal,
        ),
        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: _moss,
          foregroundColor: _cream,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: _cream,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: _cream),
        ),
        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _moss,
            foregroundColor: _cream,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            padding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        // Text inputs
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF263320),
          labelStyle: TextStyle(color: _lime),
          hintStyle: TextStyle(color: _cream.withOpacity(0.4)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: _lime, width: 0.6),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: _lime, width: 0.5, style: BorderStyle.solid),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: _lime, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        // BottomNav
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _charcoal,
          selectedItemColor: _lime,
          unselectedItemColor: _cream,
        ),
        // TabBar
        tabBarTheme: const TabBarThemeData(
          indicatorColor: _lime,
          labelColor: _lime,
          unselectedLabelColor: _cream,
        ),
        // Cards
        cardTheme: CardThemeData(
          color: Color(0xFF243020),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            side: BorderSide(color: Color(0x2Da8c96e)),
          ),
        ),
        // Dividers
        dividerColor: Color(0x1Af5f0e8),
        // Progress indicator
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: _lime),
      ),
      home: const SplashScreen(),
    );
  }
}
