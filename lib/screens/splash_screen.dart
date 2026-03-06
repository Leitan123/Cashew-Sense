import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

const _charcoal = Color(0xFF1e2820);
const _moss     = Color(0xFF3d5a2e);
const _leaf     = Color(0xFF5c8a3c);
const _lime     = Color(0xFFa8c96e);
const _cream    = Color(0xFFf5f0e8);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initApp();
  }

  Future<void> _initApp() async {
    // Artificial delay to show splash animation nicely
    await Future.delayed(const Duration(seconds: 3));
    
    // Initialize services
    await DatabaseService.instance.init();
    await AuthService.instance.init();
    SyncService.instance.init();

    if (mounted) {
      if (AuthService.instance.isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _charcoal,
      body: Stack(
        children: [
          // Background glow blobs
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _leaf.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lime.withOpacity(0.10),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with glowing ring
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [_moss.withOpacity(0.6), _charcoal.withOpacity(0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _lime.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset('assets/app_logo.png', height: 110),
                ),
                const SizedBox(height: 28),
                // App name
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Cashew',
                        style: TextStyle(color: _cream),
                      ),
                      TextSpan(
                        text: 'Sense',
                        style: TextStyle(color: _lime),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Healthy trees, stronger yields',
                  style: TextStyle(
                    fontSize: 15,
                    color: _cream.withOpacity(0.5),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 48),
                // Animated progress bar
                Container(
                  width: 160,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _leaf.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        widthFactor: _controller.value,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_leaf, _lime],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: _lime.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                CircularProgressIndicator(
                  color: _lime,
                  strokeWidth: 2.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
