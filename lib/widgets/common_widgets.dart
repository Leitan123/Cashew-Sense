import 'package:flutter/material.dart';
import '/screens/settings_screen.dart';
import '/theme/app_theme.dart';

/// 🌿 Reusable App Bar for CashewSense (theme-aware)
PreferredSizeWidget buildCashewAppBar({
  required String title,
  bool showActions = true,
}) {
  return AppBar(
    title: Text(title),
    actions: showActions
        ? [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.settings_outlined, color: Theme.of(context).appBarTheme.iconTheme?.color),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ]
        : null,
  );
}

/// 🧭 Reusable Bottom Navigation Bar (theme-aware)
Widget buildCashewBottomNav({
  required int currentIndex,
  required Function(int) onTap,
}) {
  return Builder(builder: (context) {
    final c = context.ac;
    return BottomNavigationBar(
      backgroundColor: c.charcoal,
      selectedItemColor: c.lime,
      unselectedItemColor: c.cream.withOpacity(0.45),
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded),    label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.newspaper_rounded), label: 'News'),
      ],
      onTap: onTap,
    );
  });
}
