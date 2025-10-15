import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const CashewSenseApp());
}

class CashewSenseApp extends StatelessWidget {
  const CashewSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CashewSense',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(
          0xFFFFFBEA,
        ), // sets default for all screens
      ),
      home: const SplashScreen(),
    );
    ;
  }
}
