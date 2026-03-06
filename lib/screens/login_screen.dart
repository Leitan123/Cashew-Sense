import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

const _charcoal = Color(0xFF1e2820);
const _moss     = Color(0xFF3d5a2e);
const _leaf     = Color(0xFF5c8a3c);
const _lime     = Color(0xFFa8c96e);
const _cream    = Color(0xFFf5f0e8);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePin = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.login(
        phone: _phoneController.text.trim(),
        pin: _pinController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _charcoal,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.agriculture_rounded, size: 80, color: _lime),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome Back'.tr(context),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _cream,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login to continue'.tr(context),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _cream.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: _cream),
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: 'Phone Number'.tr(context),
                      prefixIcon: const Icon(Icons.phone_android, color: _lime),
                      counterText: '',
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required'.tr(context);
                      if (val.length != 10) return 'Must be 10 digits'.tr(context);
                      if (int.tryParse(val) == null) return 'Numbers only'.tr(context);
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: _obscurePin,
                    style: const TextStyle(color: _cream),
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'PIN'.tr(context),
                      prefixIcon: const Icon(Icons.lock_outline, color: _lime),
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: _lime,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePin = !_obscurePin;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required'.tr(context);
                      if (val.length < 4) return 'At least 4 digits'.tr(context);
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _cream, strokeWidth: 2))
                        : Text('Login'.tr(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ".tr(context),
                        style: TextStyle(color: _cream.withOpacity(0.7)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          'Register'.tr(context),
                          style: const TextStyle(color: _lime, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
