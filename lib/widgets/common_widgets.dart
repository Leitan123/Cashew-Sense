import 'package:flutter/material.dart';

/// 🌿 Reusable App Bar for CashewSense
PreferredSizeWidget buildCashewAppBar({
  required String title,
  bool showActions = true,
}) {
  return AppBar(
    backgroundColor: const Color(0xFF2E3A20),
    elevation: 0,
    leading: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset('assets/app_logo.png'),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    ),
    actions: showActions
        ? [
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {},
            ),
          ]
        : null,
  );
}

/// 🧭 Reusable Bottom Navigation Bar
Widget buildCashewBottomNav({
  required int currentIndex,
  required Function(int) onTap,
}) {
  return BottomNavigationBar(
    backgroundColor: const Color(0xFF2E3A20),
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white60,
    type: BottomNavigationBarType.fixed,
    currentIndex: currentIndex,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
      BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'News'),
    ],
    onTap: onTap,
  );
}
