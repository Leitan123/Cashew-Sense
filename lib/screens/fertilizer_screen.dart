import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/trunk_model_service.dart';
import '../services/soil_model_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';
import '../services/localization_service.dart';
import 'package:provider/provider.dart';

const _charcoal = Color(0xFF1e2820);
const _moss     = Color(0xFF3d5a2e);
const _leaf     = Color(0xFF5c8a3c);
const _lime     = Color(0xFFa8c96e);
const _cream    = Color(0xFFf5f0e8);

class FertilizerScreen extends StatefulWidget {
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

  File? _imageFile;
  Map<String, dynamic>? _trunkResult;
  bool _classifying = false;
  bool _invalidImage = false;

  late TextEditingController _nCtrl;
  late TextEditingController _pCtrl;
  late TextEditingController _kCtrl;
  late TextEditingController _phCtrl;
  late TextEditingController _moistureCtrl;

  List<_FertilizerRec>? _recommendations;
  bool _modelReady = false;
  List<Map<String, dynamic>> _recentScans = [];

  @override
  void initState() {
    super.initState();
    _nCtrl        = TextEditingController(text: widget.nitrogen?.toString()         ?? '');
    _pCtrl        = TextEditingController(text: widget.phosphorus?.toString()       ?? '');
    _kCtrl        = TextEditingController(text: widget.potassium?.toString()        ?? '');
    _phCtrl       = TextEditingController(text: widget.ph?.toStringAsFixed(1)       ?? '');
    _moistureCtrl = TextEditingController(text: widget.moisture?.toStringAsFixed(1) ?? '');
    _loadModel();
    _loadScansFromDb();
  }

  Future<void> _loadScansFromDb() async {
    final userId = AuthService.instance.currentUserId;
    if (userId != null) {
      final rows = await DatabaseService.instance.getSoilScans(userId);
      if (mounted) {
        setState(() {
          _recentScans = rows.take(15).toList(); // Show top 15 max on recent scans UI
        });
      }
    }
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
    _nCtrl.dispose();
    _pCtrl.dispose();
    _kCtrl.dispose();
    _phCtrl.dispose();
    _moistureCtrl.dispose();
    super.dispose();
  }

  // ── Image picking ─────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    setState(() {
      _imageFile = File(picked.path);
      _trunkResult = null;
      _recommendations = null;
      _invalidImage = false;
    });
    await _classifyTrunk();
  }

  Future<void> _classifyTrunk() async {
    if (_imageFile == null || !_modelReady) return;
    setState(() => _classifying = true);
    try {
      final result = await _trunkModel.predict(_imageFile!);
      final scores = List<double>.from(result['scores'] as List);

      // Sort descending to get top-2
      final sorted = [...scores]..sort((a, b) => b.compareTo(a));
      final top1 = sorted[0];
      final top2 = sorted[1];
      final confidence = top1 * 100;
      final margin = (top1 - top2) * 100; // gap between best and second-best

      // Valid trunk: model must be highly confident AND clearly prefer one class
      final bool isTrunk = confidence >= 75.0 && margin >= 20.0;

      if (!isTrunk) {
        setState(() {
          _trunkResult = null;
          _invalidImage = true;
        });
      } else {
        setState(() {
          _trunkResult = result;
          _invalidImage = false;
        });
      }
    } catch (e) {
      _showSnack('Classification failed: $e');
    } finally {
      setState(() => _classifying = false);
    }
  }

  // ── Helper: dose string ───────────────────────────────────────────────────
  String _trunkDose(int trunkClass, List<int> doses) {
    const sizes = ['very small', 'small', 'medium', 'large'];
    return '${doses[trunkClass]} g per tree  (${sizes[trunkClass]} tree)';
  }

  // ── Farmer-friendly recommendation logic ──────────────────────────────────
  void _generateRecommendation() {
    if (_invalidImage) {
      _showSnack('Please upload a correct cashew trunk image first');
      return;
    }
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
    final recs = <_FertilizerRec>[];

    // ── NITROGEN ─────────────────────────────────────────────────────────────
    if (n < 20) {
      recs.add(_FertilizerRec(
        nutrient: 'Nitrogen (N) — Leaf & Growth',
        status: '⚠️ Very Low',
        statusColor: Colors.red,
        fertilizer: 'Urea (White Granules)',
        dose: _trunkDose(trunkClass, [50, 100, 150, 200]),
        timing: '🌧️ Apply just before rain OR water after applying.\n'
                'Split into 2 rounds — once at start of season, once in the middle.',
        advice: '🍃 Your plant leaves may look pale yellow or light green. '
                'This fertilizer will make leaves dark green and help the plant grow faster.',
        icon: Icons.grass,
        color: Colors.green.shade700,
      ));
    } else if (n < 40) {
      recs.add(_FertilizerRec(
        nutrient: 'Nitrogen (N) — Leaf & Growth',
        status: '🔶 A Little Low',
        statusColor: Colors.orange,
        fertilizer: 'Urea (White Granules)',
        dose: _trunkDose(trunkClass, [25, 50, 75, 100]),
        timing: '🌧️ Apply before rain. One application is enough.',
        advice: '🍃 Nitrogen is slightly low. A small top-up will keep your plant healthy and growing well.',
        icon: Icons.grass,
        color: Colors.green.shade700,
      ));
    } else if (n <= 80) {
      recs.add(_FertilizerRec(
        nutrient: 'Nitrogen (N) — Leaf & Growth',
        status: '✅ Good',
        statusColor: Colors.green,
        fertilizer: 'No fertilizer needed',
        dose: 'Nothing to add',
        timing: 'Check again next season.',
        advice: '🍃 Your plant has enough nitrogen. Leaves should look healthy and dark green.',
        icon: Icons.grass,
        color: Colors.green.shade700,
      ));
    } else {
      recs.add(_FertilizerRec(
        nutrient: 'Nitrogen (N) — Leaf & Growth',
        status: '🔴 Too Much',
        statusColor: Colors.deepOrange,
        fertilizer: 'Stop adding Urea or any nitrogen',
        dose: 'Skip this season completely',
        timing: 'Do not apply until next year.',
        advice: '🍃 Too much nitrogen makes the plant grow leaves but reduces nuts. '
                'Skip nitrogen fertilizer this season.',
        icon: Icons.grass,
        color: Colors.green.shade700,
      ));
    }

    // ── PHOSPHORUS ───────────────────────────────────────────────────────────
    if (p < 10) {
      recs.add(_FertilizerRec(
        nutrient: 'Phosphorus (P) — Flowers & Roots',
        status: '⚠️ Very Low',
        statusColor: Colors.red,
        fertilizer: 'SSP — Single Super Phosphate (Grey powder)',
        dose: _trunkDose(trunkClass, [30, 60, 90, 120]),
        timing: '☔ Apply before the rainy season starts.\n'
                'Mix into the soil around the base of the tree.',
        advice: '🌸 Low phosphorus means fewer flowers and poor root growth. '
                'Adding this will help your tree flower better and produce more nuts.',
        icon: Icons.bubble_chart,
        color: Colors.amber.shade700,
      ));
    } else if (p < 20) {
      recs.add(_FertilizerRec(
        nutrient: 'Phosphorus (P) — Flowers & Roots',
        status: '🔶 A Little Low',
        statusColor: Colors.orange,
        fertilizer: 'SSP — Single Super Phosphate (Grey powder)',
        dose: _trunkDose(trunkClass, [15, 30, 45, 60]),
        timing: '☔ Apply before the rainy season. Mix into soil.',
        advice: '🌸 A small dose will improve flowering and root strength.',
        icon: Icons.bubble_chart,
        color: Colors.amber.shade700,
      ));
    } else if (p <= 40) {
      recs.add(_FertilizerRec(
        nutrient: 'Phosphorus (P) — Flowers & Roots',
        status: '✅ Good',
        statusColor: Colors.green,
        fertilizer: 'No fertilizer needed',
        dose: 'Nothing to add',
        timing: 'Check again next season.',
        advice: '🌸 Phosphorus level is good. Your tree should flower well this season.',
        icon: Icons.bubble_chart,
        color: Colors.amber.shade700,
      ));
    } else {
      recs.add(_FertilizerRec(
        nutrient: 'Phosphorus (P) — Flowers & Roots',
        status: '🔴 Too Much',
        statusColor: Colors.deepOrange,
        fertilizer: 'Stop adding SSP or any phosphorus',
        dose: 'Skip this season completely',
        timing: 'Do not apply until next year.',
        advice: '🌸 Too much phosphorus can block the plant from absorbing other nutrients. '
                'Do not add any this season.',
        icon: Icons.bubble_chart,
        color: Colors.amber.shade700,
      ));
    }

    // ── POTASSIUM ─────────────────────────────────────────────────────────────
    if (k < 30) {
      recs.add(_FertilizerRec(
        nutrient: 'Potassium (K) — Nut Size & Quality',
        status: '⚠️ Very Low',
        statusColor: Colors.red,
        fertilizer: 'MOP — Muriate of Potash (Pink/Red granules)',
        dose: _trunkDose(trunkClass, [40, 80, 120, 160]),
        timing: '🌸 Apply when flowers start to appear.\n'
                'This directly helps nuts grow bigger and stronger.',
        advice: '🥜 Low potassium causes small, poor quality nuts. '
                'Adding this during flowering season will improve nut size significantly.',
        icon: Icons.grain,
        color: Colors.red.shade400,
      ));
    } else if (k < 60) {
      recs.add(_FertilizerRec(
        nutrient: 'Potassium (K) — Nut Size & Quality',
        status: '🔶 A Little Low',
        statusColor: Colors.orange,
        fertilizer: 'MOP — Muriate of Potash (Pink/Red granules)',
        dose: _trunkDose(trunkClass, [20, 40, 60, 80]),
        timing: '🌸 Apply during early flowering.',
        advice: '🥜 A small top-up will help improve nut quality this season.',
        icon: Icons.grain,
        color: Colors.red.shade400,
      ));
    } else if (k <= 120) {
      recs.add(_FertilizerRec(
        nutrient: 'Potassium (K) — Nut Size & Quality',
        status: '✅ Good',
        statusColor: Colors.green,
        fertilizer: 'No fertilizer needed',
        dose: 'Nothing to add',
        timing: 'Check again next season.',
        advice: '🥜 Potassium is at a good level. Expect good nut size this season.',
        icon: Icons.grain,
        color: Colors.red.shade400,
      ));
    } else {
      recs.add(_FertilizerRec(
        nutrient: 'Potassium (K) — Nut Size & Quality',
        status: '🔴 Too Much',
        statusColor: Colors.deepOrange,
        fertilizer: 'Stop adding MOP or any potassium',
        dose: 'Skip this season completely',
        timing: 'Do not apply until next year.',
        advice: '🥜 Too much potassium can block magnesium. '
                'Skip potassium fertilizer this season.',
        icon: Icons.grain,
        color: Colors.red.shade400,
      ));
    }

    // ── pH ────────────────────────────────────────────────────────────────────
    if (ph < 5.0) {
      recs.add(_FertilizerRec(
        nutrient: 'Soil Sourness (pH)',
        status: '⚠️ Too Sour (Very Acidic)',
        statusColor: Colors.red,
        fertilizer: 'Agricultural Lime (White powder/granules)',
        dose: '1 kg per tree',
        timing: '⏳ Apply 4–6 weeks BEFORE adding any fertilizer.\n'
                'Mix into the top soil around the tree.',
        advice: '🌱 Your soil is too sour (acidic). This stops the plant from '
                'absorbing fertilizer properly. Lime will fix the soil first so '
                'your fertilizers can work properly.',
        icon: Icons.science,
        color: Colors.teal,
      ));
    } else if (ph < 5.5) {
      recs.add(_FertilizerRec(
        nutrient: 'Soil Sourness (pH)',
        status: '🔶 Slightly Sour',
        statusColor: Colors.orange,
        fertilizer: 'Agricultural Lime (White powder/granules)',
        dose: '500 g per tree',
        timing: '⏳ Apply 2–4 weeks before fertilizing.',
        advice: '🌱 Soil is slightly sour. A small amount of lime will help '
                'your plant absorb fertilizers better.',
        icon: Icons.science,
        color: Colors.teal,
      ));
    } else if (ph <= 7.0) {
      recs.add(_FertilizerRec(
        nutrient: 'Soil Sourness (pH)',
        status: '✅ Perfect',
        statusColor: Colors.green,
        fertilizer: 'Nothing needed',
        dose: 'Nothing to add',
        timing: 'Check again next season.',
        advice: '🌱 Soil pH is perfect for cashew. All nutrients can be '
                'absorbed well by the plant.',
        icon: Icons.science,
        color: Colors.teal,
      ));
    } else {
      recs.add(_FertilizerRec(
        nutrient: 'Soil Sourness (pH)',
        status: '🔴 Too Sweet (Alkaline)',
        statusColor: Colors.deepOrange,
        fertilizer: 'Sulfur powder (Yellow)',
        dose: '300 g per tree',
        timing: '💧 Apply and water the soil well after.',
        advice: '🌱 Soil is too alkaline. This can make plants look weak and '
                'pale. Sulfur will bring the soil back to the right level.',
        icon: Icons.science,
        color: Colors.teal,
      ));
    }

    // ── MOISTURE ──────────────────────────────────────────────────────────────
    if (m < 20) {
      recs.add(_FertilizerRec(
        nutrient: 'Soil Water (Moisture)',
        status: '⚠️ Very Dry',
        statusColor: Colors.red,
        fertilizer: '🚿 Water your trees immediately',
        dose: '30–40 litres per tree',
        timing: '🌅 Water in the morning or evening — not midday.\n'
                '⚠️ Do NOT apply any fertilizer until soil is moist.',
        advice: '💧 The soil is very dry. Fertilizer applied to dry soil will '
                'burn the roots and waste money. Water first, then fertilize after 2 days.',
        icon: Icons.water_drop,
        color: Colors.blue,
      ));
    } else if (m < 35) {
      recs.add(_FertilizerRec(
        nutrient: 'Soil Water (Moisture)',
        status: '🔶 A Little Dry',
        statusColor: Colors.orange,
        fertilizer: '🚿 Water your trees before fertilizing',
        dose: '20 litres per tree',
        timing: '🌅 Water the day before you apply fertilizer.',
        advice: '💧 Soil is slightly dry. A light watering before applying '
                'fertilizer will help nutrients reach the roots properly.',
        icon: Icons.water_drop,
        color: Colors.blue,
      ));
    } else if (m <= 70) {
      recs.add(_FertilizerRec(
        nutrient: 'Soil Water (Moisture)',
        status: '✅ Good',
        statusColor: Colors.green,
        fertilizer: 'No action needed',
        dose: 'Continue normal watering',
        timing: 'Good time to apply fertilizer now.',
        advice: '💧 Soil moisture is perfect. This is the best time to apply '
                'your fertilizers — they will absorb well into the roots.',
        icon: Icons.water_drop,
        color: Colors.blue,
      ));
    } else {
      recs.add(_FertilizerRec(
        nutrient: 'Soil Water (Moisture)',
        status: '🔴 Too Wet / Waterlogged',
        statusColor: Colors.deepOrange,
        fertilizer: '⛔ Do not apply any fertilizer now',
        dose: 'Wait until water drains',
        timing: '⏳ Wait 3–5 days after rain stops before fertilizing.',
        advice: '💧 Soil has too much water. If you add fertilizer now it will '
                'wash away and be wasted. Wait for the soil to drain first.',
        icon: Icons.water_drop,
        color: Colors.blue,
      ));
    }

    setState(() => _recommendations = recs);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveScanWithImage() async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to save soil scans.'.tr(context))),
      );
      return;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please capture an image first to save the scan.'.tr(context))),
      );
      return;
    }

    final imagePath = _imageFile!.path;

    final n  = int.tryParse(_nCtrl.text)        ?? 0;
    final p  = int.tryParse(_pCtrl.text)        ?? 0;
    final k  = int.tryParse(_kCtrl.text)        ?? 0;
    final ph = double.tryParse(_phCtrl.text)       ?? 7.0;
    final m  = double.tryParse(_moistureCtrl.text) ?? 0.0;
    
    // We do not have EC and Temp fields in this screen for editing, so use passed or default
    final ecVal = widget.ec ?? 0;
    final tempVal = widget.temperature ?? 0.0;
    
    // Calculate a rough score from model
    final SoilModelService soilModel = SoilModelService();
    await soilModel.loadModel();
    double? soilScore;
    try {
      soilScore = soilModel.predict(
        f1: m, f2: tempVal, f3: ecVal.toDouble(),
        ph: ph, f5: n.toDouble(), f6: p.toDouble(), f7: k.toDouble(),
      );
    } catch (_) {}
    soilModel.close();

    try {
      await DatabaseService.instance.insertSoilScan({
        'user_id': userId,
        'imagePath': imagePath,
        'moisture': m,
        'temperature': tempVal,
        'ec': ecVal,
        'ph': ph,
        'nitrogen': n,
        'phosphorus': p,
        'potassium': k,
        'soil_score': soilScore,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'synced': 0, // Unsynced initially
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Soil scan saved successfully!'.tr(context))),
      );

      await _loadScansFromDb();

      // Trigger sync
      if (AuthService.instance.isLoggedIn) {
        AuthService.instance.syncData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save scan: $e')),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCashewAppBar(title: 'Fertilizer Advisor'.tr(context)),
      backgroundColor: _charcoal,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('📸 ' + 'Capture Trunk Image'.tr(context)),
            const SizedBox(height: 10),
            _buildImageSection(),
            const SizedBox(height: 20),
            if (_invalidImage) _buildInvalidImageCard(),
            if (_trunkResult != null) _buildTrunkResult(),
            const SizedBox(height: 20),
            _buildSectionHeader('🌿 ' + 'Soil NPK Values'.tr(context)),
            const SizedBox(height: 10),
            _buildNpkInputs(),
            const SizedBox(height: 20),
            _buildGenerateButton(),
            const SizedBox(height: 20),
            if (_recommendations != null) ...[
              _buildSectionHeader('💊 ' + 'Fertilizer Recommendations'.tr(context)),
              const SizedBox(height: 10),
              ..._recommendations!.map(_buildRecCard),
              const SizedBox(height: 10),
              _buildSummaryNote(),
            ],
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.blueGrey, Colors.blueAccent]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton.icon(
                onPressed: _saveScanWithImage,
                icon: const Icon(Icons.cloud_upload, color: Colors.white),
                label: Text(
                  'Save with Image'.tr(context),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildRecentScansSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _lime,
            ),
          ),
        ],
      ),
    );
  }

  // ── Image section ─────────────────────────────────────────────────────────
  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF243020),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lime.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          if (_imageFile != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
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
                color: const Color(0xFF1e2820),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_moss, _leaf]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_camera, size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text('No image selected'.tr(context), style: TextStyle(color: _cream.withOpacity(0.4))),
                  ],
                ),
              ),
            ),
          if (_classifying)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _lime, strokeWidth: 2),
                  const SizedBox(width: 12),
                  Text('Classifying trunk size...'.tr(context), style: TextStyle(color: _cream.withOpacity(0.7))),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_moss, _leaf]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: Text('Camera'.tr(context), style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3a2a20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _lime.withOpacity(0.3)),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, color: Colors.white),
                      label: Text('Gallery'.tr(context), style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
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

  // ── Invalid image warning ─────────────────────────────────────────────────
  Widget _buildInvalidImageCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF3a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invalid Image',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please upload a correct cashew trunk image to continue.',
                  style: TextStyle(color: Colors.red.shade200, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Trunk result ──────────────────────────────────────────────────────────
  Widget _buildTrunkResult() {
    final label      = _trunkResult!['label'] as String;
    final confidence = _trunkResult!['confidence'] as String;
    final index      = _trunkResult!['classIndex'] as int;

    final colors = [
      Colors.lightBlueAccent,
      Colors.orangeAccent,
      _lime,
      Colors.purpleAccent,
    ];
    final icons = [
      Icons.crop_square,
      Icons.square,
      Icons.square_rounded,
      Icons.crop_free
    ];
    final descs = [
      'Young seedling stage. Needs gentle care and starter nutrients.',
      'Early growth stage. Begin balanced NPK programme.',
      'Established tree. Full fertilization schedule recommended.',
      'Mature cashew tree. High yield potential with proper nutrition.',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF243020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors[index].withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors[index].withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icons[index], color: colors[index], size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${'Trunk Size: '.tr(context)}$label',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors[index])),
                Text('${'Confidence: '.tr(context)}$confidence%',
                    style: TextStyle(fontSize: 13, color: colors[index].withOpacity(0.8))),
                const SizedBox(height: 4),
                Text(descs[index],
                    style: TextStyle(fontSize: 12, color: _cream.withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── NPK inputs ────────────────────────────────────────────────────────────
  Widget _buildNpkInputs() {
    final fromBle = widget.nitrogen != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF243020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lime.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          if (fromBle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _leaf.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _lime.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bluetooth_connected, color: _lime, size: 16),
                  const SizedBox(width: 6),
                  Text('Values auto-filled from BLE sensor'.tr(context),
                      style: TextStyle(color: _lime, fontSize: 12)),
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
      style: TextStyle(color: _cream),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color, fontSize: 13),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_moss, _leaf]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: _leaf.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton.icon(
        onPressed: _generateRecommendation,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(
          'Generate Fertilizer Recommendation'.tr(context),
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ── Recommendation card ───────────────────────────────────────────────────
  Widget _buildRecCard(_FertilizerRec rec) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF243020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lime.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: rec.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(rec.icon, color: rec.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.nutrient,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _cream),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rec.status,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: rec.statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.science, 'Recommended Fertilizer:', rec.fertilizer, _lime),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.scale, 'Dose:', rec.dose, Colors.white70),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.schedule, 'Timing:', rec.timing, Colors.white70),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _charcoal,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates, size: 14, color: _lime),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.advice,
                    style: TextStyle(fontSize: 12, color: _cream.withOpacity(0.8), height: 1.4),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: _cream.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: _cream.withOpacity(0.5)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor, height: 1.2),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _moss.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _lime.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: _lime, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'These recommendations are based on trunk size and soil sensor data. '
              'Always consult a local agronomist for region-specific advice.',
              style: TextStyle(fontSize: 12, color: _cream.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScansSection() {
    if (_recentScans.isEmpty) return const SizedBox.shrink();

    final currentLang = Provider.of<LocalizationService>(context).currentLanguage;
    final recentScansText = {
      'en': 'RECENT SAVED SCANS',
      'si': 'මෑතකදී සුරැකි පරීක්ෂණ',
      'ta': 'சமீபத்திய சேமித்த ஸ்கேன்கள்',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              recentScansText[currentLang] ?? 'RECENT SAVED SCANS',
              style: TextStyle(
                color: _cream.withOpacity(0.35),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.07))),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentScans.length,
            itemBuilder: (context, index) {
              final scan = _recentScans[index];
              final imagePath = scan['imagePath'];
              Widget imgWidget;
              if (imagePath != null && imagePath != 'placeholder') {
                final file = File(imagePath as String);
                if (file.existsSync()) {
                  imgWidget = Image.file(file, fit: BoxFit.cover);
                } else {
                  imgWidget = Container(color: Colors.grey.withOpacity(0.2), child: const Icon(Icons.broken_image, color: Colors.white38));
                }
              } else {
                imgWidget = Container(color: Colors.grey.withOpacity(0.2), child: const Icon(Icons.broken_image, color: Colors.white38));
              }

              final score = scan['soil_score'] != null
                  ? (scan['soil_score'] as double).toStringAsFixed(1)
                  : '--';

              return GestureDetector(
                onTap: () => _showScanDetails(scan),
                child: Container(
                  width: 95,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _lime.withOpacity(0.4)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imgWidget,
                        Positioned(
                          left: 0, right: 0, bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Score: $score',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                if (scan['synced'] == 1)
                                  Icon(Icons.cloud_done, color: _lime, size: 10)
                                else
                                  const Icon(Icons.cloud_upload_outlined, color: Colors.orange, size: 10)
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  void _showScanDetails(Map<String, dynamic> scan) {
    final imagePath = scan['imagePath'];
    Widget expandedImageWidget;
    if (imagePath != null && imagePath != 'placeholder') {
      final file = File(imagePath as String);
      if (file.existsSync()) {
        expandedImageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: double.infinity, height: 200, fit: BoxFit.cover),
        );
      } else {
        expandedImageWidget = Container(
          width: double.infinity, height: 150,
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.broken_image, color: Colors.white54, size: 48),
        );
      }
    } else {
      expandedImageWidget = Container(
        width: double.infinity, height: 150,
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 48),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _charcoal,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Soil Parameters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _lime)),
                  const Divider(color: _moss),
                  const SizedBox(height: 12),
                  expandedImageWidget,
                  const SizedBox(height: 20),
                  _buildDetailRow('Moisture', '${scan['moisture'] ?? '--'} %'),
                  _buildDetailRow('Temperature', '${scan['temperature'] ?? '--'} °C'),
                  _buildDetailRow('EC', '${scan['ec'] ?? '--'} µS/cm'),
                  _buildDetailRow('pH', '${scan['ph'] ?? '--'}'),
                  _buildDetailRow('Nitrogen (N)', '${scan['nitrogen'] ?? '--'} mg/kg'),
                  _buildDetailRow('Phosphorus (P)', '${scan['phosphorus'] ?? '--'} mg/kg'),
                  _buildDetailRow('Potassium (K)', '${scan['potassium'] ?? '--'} mg/kg'),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _cream.withOpacity(0.7))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: _cream)),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────
class _FertilizerRec {
  final String nutrient;
  final String status;
  final Color statusColor;
  final String fertilizer;
  final String dose;
  final String timing;
  final String advice;
  final IconData icon;
  final Color color;

  const _FertilizerRec({
    required this.nutrient,
    required this.status,
    required this.statusColor,
    required this.fertilizer,
    required this.dose,
    required this.timing,
    required this.advice,
    required this.icon,
    required this.color,
  });
}