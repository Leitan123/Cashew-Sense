import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/localization_service.dart';
import '/services/auth_service.dart';
import '/services/theme_service.dart';
import '/theme/app_theme.dart';
import '/widgets/common_widgets.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLang = context.watch<LocalizationService>().currentLanguage;
    final isDark = context.watch<ThemeService>().isDark;
    final c = context.ac;

    return Scaffold(
      backgroundColor: c.charcoal,
      appBar: buildCashewAppBar(title: 'Settings', showActions: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileSection(context, c),
              const SizedBox(height: 32),

              // ── Appearance ──────────────────────────────────────────────────
              Text(
                'Appearance / පෙනුම / தோற்றம்',
                style: TextStyle(
                  color: c.cream.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildThemeToggle(context, isDark, c),
              const SizedBox(height: 32),

              // ── Language ────────────────────────────────────────────────────
              Text(
                'Language / භාෂාව / மொழி',
                style: TextStyle(
                  color: c.cream.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(context, 'English',            'en', currentLang, c),
              const SizedBox(height: 12),
              _buildLanguageOption(context, 'සිංහල (Sinhala)',   'si', currentLang, c),
              const SizedBox(height: 12),
              _buildLanguageOption(context, 'தமிழ் (Tamil)',     'ta', currentLang, c),
              const SizedBox(height: 32),

              _buildLogoutButton(context, c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, bool isDark, AppColors c) {
    return GestureDetector(
      onTap: () => context.read<ThemeService>().setDark(!isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: c.moss,
          border: Border.all(color: c.lime.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: c.lime,
              size: 26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDark ? 'Dark Mode' : 'Light Mode',
                    style: TextStyle(color: c.cream, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDark ? 'Tap to switch to Light Mode' : 'Tap to switch to Dark Mode',
                    style: TextStyle(color: c.cream.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            // Pill toggle
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? c.lime.withOpacity(0.8) : c.cream.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.lime.withOpacity(0.4)),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    left: isDark ? 26 : 2,
                    top: 2,
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: isDark ? c.charcoal : c.leaf,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                      ),
                      child: Icon(
                        isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                        size: 14,
                        color: isDark ? c.lime : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, AppColors c) {
    final userData = AuthService.instance.currentUserData;
    if (userData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.moss,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.lime.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.leaf.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: c.lime, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['name'] ?? 'User',
                      style: TextStyle(color: c.cream, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData['phone'] ?? '',
                      style: TextStyle(color: c.lime.withOpacity(0.8), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: c.cream.withOpacity(0.1)),
          const SizedBox(height: 16),
          _buildProfileRow(Icons.map_outlined,       'District',   userData['district']  ?? '', c),
          const SizedBox(height: 12),
          _buildProfileRow(Icons.landscape_outlined, 'Farm Size',  '${userData['farm_size']} Acres', c),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value, AppColors c) {
    return Row(
      children: [
        Icon(icon, color: c.lime.withOpacity(0.7), size: 18),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: c.cream.withOpacity(0.7), fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(color: c.cream, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppColors c) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.withOpacity(0.12),
        foregroundColor: Colors.redAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: const Icon(Icons.logout),
      label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      onPressed: () async {
        await AuthService.instance.logout();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, String label, String langCode, String currentLang, AppColors c) {
    final isSelected = langCode == currentLang;

    return GestureDetector(
      onTap: () {
        context.read<LocalizationService>().changeLanguage(langCode);
        final messages = {
          'en': 'Language changed to English',
          'si': 'භාෂාව සිංහලට වෙනස් කරන ලදි',
          'ta': 'மொழி தமிழுக்கு மாற்றப்பட்டது',
        };
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messages[langCode] ?? 'Language changed'),
            backgroundColor: c.leaf,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? c.leaf.withOpacity(0.13) : c.moss,
          border: Border.all(
            color: isSelected ? c.lime.withOpacity(0.5) : c.lime.withOpacity(0.12),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? c.lime : c.cream.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: c.lime),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? c.lime : c.cream,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
