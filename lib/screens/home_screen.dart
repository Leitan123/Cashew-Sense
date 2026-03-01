import 'package:flutter/material.dart';
import 'leaf_detector.dart';
import 'pest_detector.dart';
// import 'nut_classifier.dart';   // uncomment when ready
// import 'soil_analysis.dart';    // uncomment when ready

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNav = 0;

  // ── Palette ─────────────────────────────────────────────
  static const Color forest    = Color(0xFF1C2B10);
  static const Color moss      = Color(0xFF3A5220);
  static const Color sage      = Color(0xFF6B8F4E);
  static const Color lime      = Color(0xFFA8C66C);
  static const Color cream     = Color(0xFFF7F5EB);
  static const Color parchment = Color(0xFFEDE9D8);
  static const Color muted     = Color(0xFF7A8C6A);
  static const Color accent    = Color(0xFFD4860A);
  static const Color accentLt  = Color(0xFFF5A623);
  static const Color warnBg    = Color(0xFFFFF3E0);
  static const Color warnFg    = Color(0xFFE65100);
  static const Color okBg      = Color(0xFFE8F5E9);
  static const Color okFg      = Color(0xFF2E7D32);

  // ── Feature card data ────────────────────────────────────
  final List<Map<String, dynamic>> _features = [
    {
      'emoji':  '🦠',
      'label':  'Disease Detection',
      'desc':   'Identify leaf diseases instantly',
      'iconBg': Color(0xFFFFF3E0),
      'accent': Color(0x1AD4860A),
    },
    {
      'emoji':  '🌰',
      'label':  'Nut Classification',
      'desc':   'Grade & sort cashew quality',
      'iconBg': Color(0xFFF1F8E9),
      'accent': Color(0x1A6B8F4E),
    },
    {
      'emoji':  '🐛',
      'label':  'Pest Detection',
      'desc':   'Spot infestations early',
      'iconBg': Color(0xFFE8F5E9),
      'accent': Color(0x1FA8C66C),
    },
    {
      'emoji':  '🧪',
      'label':  'Soil Analysis',
      'desc':   'Nutrients & pH report',
      'iconBg': Color(0xFFF3E5AB),
      'accent': Color(0x143A5220),
    },
  ];

  // ── Recent activity data ─────────────────────────────────
  final List<Map<String, dynamic>> _activities = [
    {
      'emoji': '🍃',
      'title': 'Anthracnose detected – Field B',
      'sub':   'Disease Detection · 2 hrs ago',
      'badge': 'Warning',
      'warn':  true,
    },
    {
      'emoji': '🌰',
      'title': 'Grade A batch confirmed',
      'sub':   'Nut Classification · Yesterday',
      'badge': 'Healthy',
      'warn':  false,
    },
    {
      'emoji': '🧪',
      'title': 'Soil pH 6.1 – optimal range',
      'sub':   'Soil Analysis · 2 days ago',
      'badge': 'Good',
      'warn':  false,
    },
  ];

  void _onFeatureTap(int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeafDetector()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PestDetector()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coming soon!')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildBottomNav(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(),
            // _buildStatsStrip(),
            _buildHeroBanner(),
            _buildSectionHeader('Features', 'View all', onTap: () {}),
            _buildFeatureGrid(),
            _buildSectionHeader('Recent Activity', '', onTap: null),
            _buildActivityList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: forest,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [sage, lime],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🌿', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'CashewSense',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _appBarIconBtn(Icons.notifications_none_rounded, onTap: () {}),
              Positioned(
                top: 10, right: 10,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: accentLt,
                    shape: BoxShape.circle,
                    border: Border.all(color: forest, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _appBarIconBtn(Icons.person_outline_rounded, onTap: () {}),
        ),
      ],
    );
  }

  Widget _appBarIconBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ── Greeting ─────────────────────────────────────────────
  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good Morning 🌤',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: muted, letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800,
                color: forest, height: 1.15,
              ),
              children: [
                TextSpan(text: 'Monitor your '),
                TextSpan(
                  text: 'harvest',
                  style: TextStyle(color: sage),
                ),
                TextSpan(text: ', effortlessly.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // // ── Stats Strip — FIX: use Expanded + Column only, no FittedBox ──────────
  // Widget _buildStatsStrip() {
  //   final stats = [
  //     {'icon': '🌡️', 'val': '32°C', 'lbl': 'Temperature'},
  //     {'icon': '💧', 'val': '68%',  'lbl': 'Humidity'},
  //     {'icon': '🌾', 'val': '12',   'lbl': 'Scans Today'},
  //   ];

  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
  //     child: Row(
  //       children: List.generate(stats.length, (i) {
  //         final s = stats[i];
  //         return Expanded(
  //           child: Container(
  //             margin: EdgeInsets.only(right: i < stats.length - 1 ? 10 : 0),
  //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(14),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.07),
  //                   blurRadius: 6, offset: const Offset(0, 1),
  //                 ),
  //               ],
  //             ),
  //             // FIX: Row with flexible text instead of FittedBox
  //             child: Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Text(s['icon']!, style: const TextStyle(fontSize: 16)),
  //                 const SizedBox(width: 6),
  //                 Flexible(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Text(
  //                         s['val']!,
  //                         style: const TextStyle(
  //                           fontSize: 13,
  //                           fontWeight: FontWeight.w700,
  //                           color: forest,
  //                         ),
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                       Text(
  //                         s['lbl']!,
  //                         style: const TextStyle(
  //                           fontSize: 9,
  //                           fontWeight: FontWeight.w500,
  //                           color: muted,
  //                         ),
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),R
  //           ),
  //         );
  //       }),
  //     ),
  //   );
  // }

  // ── Hero Banner ───────────────────────────────────────────
  Widget _buildHeroBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LeafDetector()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(22, 12, 22, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [forest, moss, sage],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20, top: -20,
                      child: Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: lime.withOpacity(0.18),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20, bottom: -20,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: lime.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -18, bottom: -18,
              child: Opacity(
                opacity: 0.13,
                child: Transform.rotate(
                  angle: -0.26,
                  child: const Text('🍃', style: TextStyle(fontSize: 130)),
                ),
              ),
            ),
            Positioned(
              right: 40, top: -30,
              child: Opacity(
                opacity: 0.08,
                child: Transform.rotate(
                  angle: 0.52,
                  child: const Text('🍂', style: TextStyle(fontSize: 80)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: lime.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: lime.withOpacity(0.4), width: 1),
                          ),
                          child: const Text(
                            '✦ AI POWERED',
                            style: TextStyle(
                              color: lime, fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Detect diseases\nbefore they spread',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20, fontWeight: FontWeight.w800,
                            height: 1.25,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 8,
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Snap a leaf · Get results in seconds',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12, fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: lime,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 14, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Scan Now →',
                      style: TextStyle(
                        color: forest,
                        fontSize: 12, fontWeight: FontWeight.w700,
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

  // ── Section Header ────────────────────────────────────────
  Widget _buildSectionHeader(String title, String action,
      {required VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: forest,
            ),
          ),
          if (action.isNotEmpty)
            GestureDetector(
              onTap: onTap,
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: sage,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Feature Grid — FIX: increased childAspectRatio ───────
  Widget _buildFeatureGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _features.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          // FIX: was 1.05 — too short. 0.9 gives cards more vertical room.
          childAspectRatio: 0.90,
        ),
        itemBuilder: (context, index) =>
            _buildFeatureCard(_features[index], index),
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, int index) {
    return GestureDetector(
      onTap: () => _onFeatureTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Accent circle (top-right)
            Positioned(
              top: -20, right: -20,
              child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: feature['accent'] as Color,
                ),
              ),
            ),
            // Arrow
            Positioned(
              bottom: 12, right: 12,
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: parchment,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: sage, size: 14,
                ),
              ),
            ),
            // FIX: wrap content in a column that doesn't overflow
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: feature['iconBg'] as Color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        feature['emoji'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    feature['label'] as String,
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: forest, height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    feature['desc'] as String,
                    style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500,
                      color: muted, height: 1.4,
                    ),
                    // FIX: prevent text from overflowing
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Activity List ─────────────────────────────────────────
  Widget _buildActivityList() {
    return Column(
      children: List.generate(_activities.length, (index) {
        final item = _activities[index];
        return Column(
          children: [
            _buildActivityItem(item),
            if (index < _activities.length - 1)
              const Divider(
                height: 1, thickness: 1,
                indent: 22, endIndent: 22,
                color: Color(0x0F000000),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> item) {
    final isWarn = item['warn'] as bool;
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: parchment,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(item['emoji'] as String,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: forest,
                    ),
                    // FIX: prevent long titles overflowing
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['sub'] as String,
                    style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500, color: muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: isWarn ? warnBg : okBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item['badge'] as String,
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: isWarn ? warnFg : okFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded,       'label': 'Home'},
      {'icon': Icons.camera_alt_rounded, 'label': 'Scan'},
      {'icon': Icons.bar_chart_rounded,  'label': 'Reports'},
      {'icon': Icons.settings_rounded,   'label': 'Settings'},
    ];

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20, offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isActive = _selectedNav == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedNav = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? moss.withOpacity(0.07) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[index]['icon'] as IconData,
                    color: isActive ? moss : muted,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[index]['label'] as String,
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: isActive ? moss : muted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 4 : 0,
                    height: isActive ? 4 : 0,
                    decoration: BoxDecoration(
                      color: moss, shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
