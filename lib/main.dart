import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/localization_service.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localizationService = LocalizationService();
  await localizationService.init();

  final themeService = ThemeService();
  await themeService.init();

  // Setup AuthService to auto-sync when internet comes online
  AuthService.instance.setupAutoSync();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localizationService),
        ChangeNotifierProvider.value(value: themeService),
      ],
      child: const CashewSenseApp(),
    ),
  );
}

class CashewSenseApp extends StatelessWidget {
  const CashewSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeService>().themeMode;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CashewSense',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
