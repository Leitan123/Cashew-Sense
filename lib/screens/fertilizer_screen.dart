// File: lib/screens/fertilizer_screen.dart
//
// Combines:
//  • Trunk image → TFLite classification (very small / small / medium / large)
//  • NPK BLE sensor values (passed in or entered manually)
//  • Smart fertilizer recommendation for cashew trees

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/trunk_model_service.dart';
import '../widgets/common_widgets.dart';

class FertilizerScreen extends StatefulWidget {
  // Optional: pass NPK values directly from BLE screen
  final double? moisture;
  final double? temperature;
  final int? ec;
  final double? ph;
  final int? nitrogen;
  final int? phosphorus;
  final int? potassium;

  const FertilizerScreen({
    super.key,
    this.moisture,
    this.temperature,
    this.ec,
    this.ph,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
  });

  @override
  State<FertilizerScreen> createState() => _FertilizerScreenState();
}

class _FertilizerScreenState extends State<FertilizerScreen> {
  final TrunkModelService _trunkModel = TrunkModelService();
  final ImagePicker _picker = ImagePicker();

  // Image & trunk result
  File? _imageFile;
  Map<String, dynamic>? _trunkResult;
  bool _classifying = false;

  // NPK manual controllers (pre-filled if passed from BLE)
  late TextEditingController _nCtrl;
  late TextEditingController _pCtrl;
  late TextEditingController _kCtrl;
  late TextEditingController _phCtrl;
  late TextEditingController _moistureCtrl;

  // Recommendation
  List<_FertilizerRec>? _recommendations;
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();
    _nCtrl       = TextEditingController(text: widget.nitrogen?.toString()    ?? '');
    _pCtrl       = TextEditingController(text: widget.phosphorus?.toString()  ?? '');
    _kCtrl       = TextEditingController(text: widget.potassium?.toString()   ?? '');
    _phCtrl      = TextEditingController(text: widget.ph?.toStringAsFixed(1)  ?? '');
    _moistureCtrl= TextEditingController(text: widget.moisture?.toStringAsFixed(1) ?? '');
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _trunkModel.loadModel();
      setState(() => _modelReady = true);
    } catch (e) {
      _showSnack('Model load failed: $e');
    }
  }

  @override
  void dispose() {
    _trunkModel.close();
    _nCtrl.dispose(); _pCtrl.dispose(); _kCtrl.dispose();
    _phCtrl.dispose(); _moistureCtrl.dispose();
    super.dispose();
  }

  // ── Image picking ────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    setState(() {
      _imageFile = File(picked.path);
      _trunkResult = null;
      _recommendations = null;
    });
    await _classifyTrunk();
  }

  Future<void> _classifyTrunk() async {
    if (_imageFile == null || !_modelReady) return;
    setState(() => _classifying = true);
    try {
      final result = await _trunkModel.predict(_imageFile!);
      setState(() => _trunkResult = result);
    } catch (e) {
      _showSnack('Classification failed: $e');
    } finally {
      setState(() => _classifying = false);
    }
  }

  // ── Fertilizer logic ─────────────────────────────────────────────────────
  void _generateRecommendation() {
    if (_trunkResult == null) {
      _showSnack('Please capture a trunk image first');
      return;
    }

    final n  = double.tryParse(_nCtrl.text)        ?? 0;
    final p  = double.tryParse(_pCtrl.text)        ?? 0;
    final k  = double.tryParse(_kCtrl.text)        ?? 0;
    final ph = double.tryParse(_phCtrl.text)       ?? 7;
    final m  = double.tryParse(_moistureCtrl.text) ?? 50;

    final trunkClass = _trunkResult!['classIndex'] as int;
    // 0=very_small, 1=small, 2=medium, 3=large

    final recs = <_FertilizerRec>[];

    // ── Nitrogen (N) recommendation
    double nTarget = [20.0, 40.0, 60.0, 80.0][trunkClass];
    if (n < nTarget * 0.6) {
      double dose = [50.0, 100.0, 150.0, 200.0][trunkClass];
      recs.add(_FertilizerRec(
        nutrient: 'Nitrogen (N)',
        status: 'Deficient',
        statusColor: Colors.red,
        fertilizer: 'Urea (46-0-0)',
        dose: '${dose.toInt()} g/tree',
        timing: 'Apply in 2 splits: early & mid season',
        icon: Icons.grass,
        color: Colors.green.shade700,
      ));
    } else if (n > nTarget * 1.4) {
      recs.add(_FertilizerRec(
        nutrient: 'Nitrogen (N)',
        status: 'Excess',
        statusColor: Colors.orange,
        fertilizer: 'No N fertilizer needed',
        dose: 'Skip this season',
        timing: 'Monitor leaf color; reduce next application',
        icon: Icons.grass,
        color: Colors.green.shade700,
      ));
    } else {
      recs.add(_FertilizerRec(
        nutrient: 'Nitrogen (N)',
        status: 'Optimal',
        statusColor: Colors.green,
        fertilizer: 'Maintain current regime',
        dose: 'Maintenance dose only',
        timing: 'Continue regular schedule',
        icon: Icons.grass,
        color: Colors.green.shade700,
      ));
    }

    // ── Phosphorus (P) recommendation
    double pTarget = [10.0, 20.0, 30.0, 40.0][trunkClass];
    if (p < pTarget * 0.6) {
      double dose = [30.0, 60.0, 90.0, 120.0][trunkClass];
      recs.add(_FertilizerRec(
        nutrient: 'Phosphorus (P)',
        status: 'Deficient',
        statusColor: Colors.red,
        fertilizer: 'Single Super Phosphate (SSP)',
        dose: '${dose.toInt()} g/tree',
        timing: 'Apply before rainy season for best absorption',
        icon: Icons.bubble_chart,
        color: Colors.amber.shade700,
      ));
    } else if (p > pTarget * 1.4) {
      recs.add(_FertilizerRec(
        nutrient: 'Phosphorus (P)',
        status: 'Excess',
        statusColor: Colors.orange,
        fertilizer: 'No P fertilizer needed',
        dose: 'Skip this season',
        timing: 'Excess P locks out Zn & Fe — monitor micronutrients',
        icon: Icons.bubble_chart,
        color: Colors.amber.shade700,
      ));
    } else {
      recs.add(_FertilizerRec(
        nutrient: 'Phosphorus (P)',
        status: 'Optimal',
        statusColor: Colors.green,
        fertilizer: 'Maintain current regime',
        dose: 'Maintenance dose only',
        timing: 'Continue regular schedule',
        icon: Icons.bubble_chart,
        color: Colors.amber.shade700,
      ));
    }

    // ── Potassium (K) recommendation
    double kTarget = [30.0, 60.0, 90.0, 120.0][trunkClass];
    if (k < kTarget * 0.6) {
      double dose = [40.0, 80.0, 120.0, 160.0][trunkClass];
      recs.add(_FertilizerRec(
        nutrient: 'Potassium (K)',
        status: 'Deficient',
        statusColor: Colors.red,
        fertilizer: 'Muriate of Potash (MOP)',
        dose: '${dose.toInt()} g/tree',
        timing: 'Apply during flowering for better nut set',
        icon: Icons.grain,
        color: Colors.red.shade400,
      ));
    } else if (k > kTarget * 1.4) {
      recs.add(_FertilizerRec(
        nutrient: 'Potassium (K)',
        status: 'Excess',
        statusColor: Colors.orange,
        fertilizer: 'No K fertilizer needed',
        dose: 'Skip this season',
        timing: 'High K can block Mg uptake — check leaf symptoms',
        icon: Icons.grain,
        color: Colors.red.shade400,
      ));
    } else {
      recs.add(_FertilizerRec(
        nutrient: 'Potassium (K)',
        status: 'Optimal',
        statusColor: Colors.green,
        fertilizer: 'Maintain current regime',
        dose: 'Maintenance dose only',
        timing: 'Continue regular schedule',
        icon: Icons.grain,
        color: Colors.red.shade400,
      ));
    }

    // ── pH recommendation
    if (ph < 5.5) {
      recs.add(_FertilizerRec(
        nutrient: 'Soil pH',
        status: 'Too Acidic (${ph.toStringAsFixed(1)})',
        statusColor: Colors.red,
        fertilizer: 'Agricultural Lime (CaCO₃)',
        dose: '500–1000 g/tree',
        timing: 'Apply 4–6 weeks before fertilizing',
        icon: Icons.science,
        color: Colors.teal,
      ));
    } else if (ph > 7.5) {
      recs.add(_FertilizerRec(
        nutrient: 'Soil pH',
        status: 'Too Alkaline (${ph.toStringAsFixed(1)})',
        statusColor: Colors.orange,
        fertilizer: 'Elemental Sulfur',
        dose: '200–400 g/tree',
        timing: 'Apply and water thoroughly',
        icon: Icons.science,
        color: Colors.teal,
      ));
    }

    // ── Moisture recommendation
    if (m < 30) {
      recs.add(_FertilizerRec(
        nutrient: 'Soil Moisture',
        status: 'Low (${m.toStringAsFixed(1)}%)',
        statusColor: Colors.red,
        fertilizer: 'Irrigation required',
        dose: '20–30 L/tree/week',
        timing: 'Irrigate before fertilizer application',
        icon: Icons.water_drop,
        color: Colors.blue,
      ));
    } else if (m > 80) {
      recs.add(_FertilizerRec(
        nutrient: 'Soil Moisture',
        status: 'Waterlogged (${m.toStringAsFixed(1)}%)',
        statusColor: Colors.orange,
        fertilizer: 'Improve drainage',
        dose: 'Delay fertilizer application',
        timing: 'Apply fertilizer only after water recedes',
        icon: Icons.water_drop,
        color: Colors.blue,
      ));
    }

    setState(() => _recommendations = recs);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCashewAppBar(title: 'Fertilizer Advisor'),
      backgroundColor: const Color(0xFFF5F5DC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('📸 Step 1: Capture Trunk Image'),
            const SizedBox(height: 10),
            _buildImageSection(),
            const SizedBox(height: 20),
            if (_trunkResult != null) _buildTrunkResult(),
            const SizedBox(height: 20),
            _buildSectionHeader('🌿 Step 2: Soil NPK Values'),
            const SizedBox(height: 10),
            _buildNpkInputs(),
            const SizedBox(height: 20),
            _buildGenerateButton(),
            const SizedBox(height: 20),
            if (_recommendations != null) ...[
              _buildSectionHeader('💊 Fertilizer Recommendations'),
              const SizedBox(height: 10),
              ..._recommendations!.map(_buildRecCard),
              const SizedBox(height: 10),
              _buildSummaryNote(),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E3A20),
      ),
    );
  }

  // Image capture section
  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (_imageFile != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.file(
                _imageFile!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No image selected',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          if (_classifying)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 12),
                  Text('Classifying trunk size...'),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Camera',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E3A20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text('Gallery',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Trunk classification result
  Widget _buildTrunkResult() {
    final label      = _trunkResult!['label'] as String;
    final confidence = _trunkResult!['confidence'] as String;
    final index      = _trunkResult!['classIndex'] as int;

    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple];
    final icons  = [Icons.crop_square, Icons.square, Icons.square_rounded, Icons.crop_free];
    final descs  = [
      'Young seedling stage. Needs gentle care and starter nutrients.',
      'Early growth stage. Begin balanced NPK programme.',
      'Established tree. Full fertilization schedule recommended.',
      'Mature cashew tree. High yield potential with proper nutrition.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors[index].withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors[index].withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors[index].withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icons[index], color: colors[index], size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trunk Size: $label',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors[index])),
                Text('Confidence: $confidence%',
                    style: TextStyle(
                        fontSize: 13, color: colors[index].withOpacity(0.8))),
                const SizedBox(height: 4),
                Text(descs[index],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NPK input fields
  Widget _buildNpkInputs() {
    final fromBle = widget.nitrogen != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (fromBle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bluetooth_connected,
                      color: Colors.green, size: 16),
                  SizedBox(width: 6),
                  Text('Values auto-filled from BLE sensor',
                      style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(child: _buildInput('N (mg/kg)', _nCtrl, Colors.green)),
              const SizedBox(width: 10),
              Expanded(child: _buildInput('P (mg/kg)', _pCtrl, Colors.amber.shade700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildInput('K (mg/kg)', _kCtrl, Colors.red.shade400)),
              const SizedBox(width: 10),
              Expanded(child: _buildInput('pH', _phCtrl, Colors.teal)),
            ],
          ),
          const SizedBox(height: 10),
          _buildInput('Moisture (%)', _moistureCtrl, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, Color color) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generateRecommendation,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text(
          'Generate Fertilizer Recommendation',
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E3A20),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // Recommendation card
  Widget _buildRecCard(_FertilizerRec rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(rec.icon, color: rec.color, size: 22),
              const SizedBox(width: 8),
              Text(rec.nutrient,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: rec.statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(rec.status,
                    style: TextStyle(
                        color: rec.statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 16),
          _recRow(Icons.local_florist, 'Fertilizer', rec.fertilizer),
          const SizedBox(height: 6),
          _recRow(Icons.scale, 'Dose', rec.dose),
          const SizedBox(height: 6),
          _recRow(Icons.schedule, 'Timing', rec.timing),
        ],
      ),
    );
  }

  Widget _recRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ),
      ],
    );
  }

  Widget _buildSummaryNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'These recommendations are based on AI analysis of trunk size and soil sensor data. '
              'Always consult a local agronomist for region-specific advice.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data class ─────────────────────────────────────────────────────────────
class _FertilizerRec {
  final String nutrient;
  final String status;
  final Color statusColor;
  final String fertilizer;
  final String dose;
  final String timing;
  final IconData icon;
  final Color color;

  const _FertilizerRec({
    required this.nutrient,
    required this.status,
    required this.statusColor,
    required this.fertilizer,
    required this.dose,
    required this.timing,
    required this.icon,
    required this.color,
  });
}