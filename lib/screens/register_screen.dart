import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import 'home_screen.dart';

const _charcoal = Color(0xFF1e2820);
const _moss     = Color(0xFF3d5a2e);
const _leaf     = Color(0xFF5c8a3c);
const _lime     = Color(0xFFa8c96e);
const _cream    = Color(0xFFf5f0e8);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  
  String? _selectedDistrict;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _isLoading = false;
  bool _isEmployee = false;

  final List<String> _districts = [
    'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle',
    'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara', 'Kandy', 'Kegalle',
    'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara', 'Moneragala',
    'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura',
    'Trincomalee', 'Vavuniya'
  ];

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a district'.tr(context))),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final size = double.tryParse(_farmSizeController.text.trim()) ?? 0.0;
      await AuthService.instance.register(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        pin: _pinController.text.trim(),
        district: _selectedDistrict!,
        farmSize: size,
        employeeCode: _isEmployee ? _employeeCodeController.text.trim() : null,
      );
      
      if (mounted) {
        // Clear stack and go home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (Route<dynamic> route) => false,
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
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _farmSizeController.dispose();
    _employeeCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Create Account'.tr(context), style: const TextStyle(color: _cream)),
        iconTheme: const IconThemeData(color: _cream),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join CashewSense'.tr(context),
                  style: const TextStyle(
                    color: _lime,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Register offline. We will sync when connected.'.tr(context),
                  style: TextStyle(color: _cream.withOpacity(0.7)),
                ),
                const SizedBox(height: 32),

                // Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: _cream),
                  decoration: InputDecoration(
                    labelText: 'Full Name'.tr(context),
                    prefixIcon: const Icon(Icons.person_outline, color: _lime),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required'.tr(context) : null,
                ),
                const SizedBox(height: 16),

                // Phone
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
                const SizedBox(height: 16),

                // District
                DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  dropdownColor: _moss,
                  style: const TextStyle(color: _cream),
                  decoration: InputDecoration(
                    labelText: 'District'.tr(context),
                    prefixIcon: const Icon(Icons.map_outlined, color: _lime),
                  ),
                  items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) => setState(() => _selectedDistrict = val),
                ),
                const SizedBox(height: 16),

                // Farm Size
                TextFormField(
                  controller: _farmSizeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: _cream),
                  decoration: InputDecoration(
                    labelText: 'Farm Size (Acres)'.tr(context),
                    prefixIcon: const Icon(Icons.landscape_outlined, color: _lime),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required'.tr(context);
                    if (double.tryParse(val) == null) return 'Must be a number'.tr(context);
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Employee Toggle
                SwitchListTile(
                  title: Text('Are you an employee?'.tr(context), style: const TextStyle(color: _cream)),
                  subtitle: Text('Register using a farm owner code'.tr(context), style: TextStyle(color: _cream.withOpacity(0.7))),
                  value: _isEmployee,
                  activeColor: _lime,
                  onChanged: (val) => setState(() => _isEmployee = val),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_isEmployee) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _employeeCodeController,
                    style: const TextStyle(color: _cream),
                    decoration: InputDecoration(
                      labelText: 'Employee Code'.tr(context),
                      prefixIcon: const Icon(Icons.badge_outlined, color: _lime),
                    ),
                    validator: (val) {
                      if (_isEmployee && (val == null || val.trim().isEmpty)) {
                        return 'Required'.tr(context);
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // PIN
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: _obscurePin,
                  style: const TextStyle(color: _cream),
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'PIN (4-6 digits)'.tr(context),
                    prefixIcon: const Icon(Icons.lock_outline, color: _lime),
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _lime),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required'.tr(context);
                    if (val.length < 4 || val.length > 6) return '4 to 6 digits'.tr(context);
                    if (int.tryParse(val) == null) return 'Numbers only'.tr(context);
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm PIN
                TextFormField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: _obscureConfirmPin,
                  style: const TextStyle(color: _cream),
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Confirm PIN'.tr(context),
                    prefixIcon: const Icon(Icons.lock_outline, color: _lime),
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPin ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _lime),
                      onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                    ),
                  ),
                  validator: (val) {
                    if (val != _pinController.text) return 'PINs do not match'.tr(context);
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _leaf,
                    foregroundColor: _cream,
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _cream, strokeWidth: 2))
                      : Text('Register'.tr(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
