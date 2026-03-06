import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/localization_service.dart';
import '/services/auth_service.dart';
import '/widgets/common_widgets.dart';
import 'login_screen.dart';

const _charcoal = Color(0xFF1e2820);
const _moss     = Color(0xFF3d5a2e);
const _leaf     = Color(0xFF5c8a3c);
const _lime     = Color(0xFFa8c96e);
const _cream    = Color(0xFFf5f0e8);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLang = context.watch<LocalizationService>().currentLanguage;

    return Scaffold(
      backgroundColor: _charcoal,
      appBar: buildCashewAppBar(title: 'Settings', showActions: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileSection(context),
              const SizedBox(height: 32),
              
              Text(
                'Language / භාෂාව / மொழி',
                style: TextStyle(
                  color: _cream.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(context, 'English', 'en', currentLang),
              const SizedBox(height: 12),
              _buildLanguageOption(context, 'සිංහල (Sinhala)', 'si', currentLang),
              const SizedBox(height: 12),
              const SizedBox(height: 32),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final userData = AuthService.instance.currentUserData;
    if (userData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF243020),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lime.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _moss.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: _lime, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['name'] ?? 'User',
                      style: const TextStyle(
                        color: _cream,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData['phone'] ?? '',
                      style: TextStyle(
                        color: _lime.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          _buildProfileRow(Icons.map_outlined, 'District', userData['district'] ?? ''),
          const SizedBox(height: 12),
          _buildProfileRow(Icons.landscape_outlined, 'Farm Size', '${userData['farm_size']} Acres'),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: _lime.withOpacity(0.7), size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: _cream.withOpacity(0.7), fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(color: _cream, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.withOpacity(0.15),
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

  Widget _buildLanguageOption(BuildContext context, String label, String langCode, String currentLang) {
    final isSelected = langCode == currentLang;

    return GestureDetector(
      onTap: () {
        context.read<LocalizationService>().changeLanguage(langCode);
        
        // Show a popup confirm message
        final messages = {
          'en': 'Language changed to English',
          'si': 'භාෂාව සිංහලට වෙනස් කරන ලදි',
          'ta': 'மொழி தமிழுக்கு மாற்றப்பட்டது',
        };
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messages[langCode] ?? 'Language changed'),
            backgroundColor: _leaf,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? _leaf.withOpacity(0.15) : Colors.white.withOpacity(0.02),
          border: Border.all(
            color: isSelected ? _lime.withOpacity(0.5) : Colors.white.withOpacity(0.05),
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
                  color: isSelected ? _lime : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: _lime)))
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _lime : _cream,
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
