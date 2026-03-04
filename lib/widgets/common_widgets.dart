import 'package:flutter/material.dart';
import '/screens/settings_screen.dart';

const _charcoal = Color(0xFF1e2820);
const _moss     = Color(0xFF3d5a2e);
const _lime     = Color(0xFFa8c96e);
const _cream    = Color(0xFFf5f0e8);

/// 🌿 Reusable App Bar for CashewSense
PreferredSizeWidget buildCashewAppBar({
  required String title,
  bool showActions = true,
}) {
  return AppBar(
    backgroundColor: _moss,
    elevation: 0,
    leading: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset('assets/app_logo.png'),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: _cream,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),
    actions: showActions
        ? [
            IconButton(
              icon: Icon(Icons.person_outline, color: _cream.withOpacity(0.8)),
              onPressed: () {},
            ),
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.settings_outlined, color: _cream.withOpacity(0.8)),
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

/// 🧭 Reusable Bottom Navigation Bar
Widget buildCashewBottomNav({
  required int currentIndex,
  required Function(int) onTap,
}) {
  return BottomNavigationBar(
    backgroundColor: _charcoal,
    selectedItemColor: _lime,
    unselectedItemColor: _cream.withOpacity(0.45),
    type: BottomNavigationBarType.fixed,
    currentIndex: currentIndex,
    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
      BottomNavigationBarItem(icon: Icon(Icons.newspaper_rounded), label: 'News'),
    ],
    onTap: onTap,
  );
}
