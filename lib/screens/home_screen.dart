import 'package:flutter/material.dart';
import 'leaf_detector.dart';
import '/widgets/common_widgets.dart';
import 'soil_analysis_screen.dart';
import 'pest_detection_screen.dart';
import 'nut_classification_screen.dart';
import 'ble_soil_screen.dart';
import 'fertilizer_screen.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Scaffold(
      backgroundColor: c.charcoal,
      appBar: buildCashewAppBar(title: 'CashewSense'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero banner ──────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: const DecorationImage(
                  image: AssetImage('assets/main_slide.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      c.leaf.withOpacity(0.82),
                      c.charcoal.withOpacity(0.55),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // AI Powered badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 7, color: c.lime),
                          const SizedBox(width: 5),
                          Text(
                            'AI POWERED'.tr(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome to CashewSense'.tr(context),
                      style: TextStyle(
                        color: c.moss,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        shadows: const [
                          Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black45),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your intelligent agriculture companion'.tr(context),
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // ── Section label ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'FEATURES'.tr(context),
                    style: TextStyle(
                      color: c.cream.withOpacity(0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 1, color: c.cream.withOpacity(0.08))),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Feature Cards Grid ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  _buildFeatureCard(context, c,
                      icon: Icons.coronavirus_outlined,
                      title: 'Disease\nDetection'.tr(context),
                      subtitle: 'Leaf analysis'.tr(context),
                      iconColor: Colors.redAccent,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LeafDetector()))),
                  _buildFeatureCard(context, c,
                      icon: Icons.eco_outlined,
                      title: 'Nut\nClassification'.tr(context),
                      subtitle: 'Grade A/B/C'.tr(context),
                      iconColor: c.lime,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const NutClassificationScreen()))),
                  _buildFeatureCard(context, c,
                      icon: Icons.pest_control_outlined,
                      title: 'Pest\nDetection'.tr(context),
                      subtitle: 'YOLO AI model'.tr(context),
                      iconColor: Colors.orangeAccent,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PestDetectionScreen()))),
                  _buildFeatureCard(context, c,
                      icon: Icons.bluetooth_rounded,
                      title: 'NPK Sensor\n(Bluetooth)'.tr(context),
                      subtitle: 'Live BLE data'.tr(context),
                      iconColor: Colors.lightBlueAccent,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const BleSoilScreen()))),
                  _buildFeatureCard(context, c,
                      icon: Icons.agriculture_rounded,
                      title: 'Fertilizer\nAdvisor'.tr(context),
                      subtitle: 'Smart NPK plan'.tr(context),
                      iconColor: Colors.amberAccent,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const FertilizerScreen()))),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: buildCashewBottomNav(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    AppColors c, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.moss,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.lime.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.leaf, c.lime],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: c.leaf.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 30, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: c.cream,
                height: 1.3,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: c.lime.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}