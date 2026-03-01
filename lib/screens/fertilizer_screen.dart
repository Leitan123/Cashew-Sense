import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/trunk_model_service.dart';
import '../widgets/common_widgets.dart';

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

  late TextEditingController _nCtrl;
  late TextEditingController _pCtrl;
  late TextEditingController _kCtrl;
  late TextEditingController _phCtrl;
  late TextEditingController _moistureCtrl;

  List<_FertilizerRec>? _recommendations;
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();
    _nCtrl        = TextEditingController(text: widget.nitrogen?.toString()         ?? '');
    _pCtrl        = TextEditingController(text: widget.phosphorus?.toString()       ?? '');
    _kCtrl        = TextEditingController(text: widget.potassium?.toString()        ?? '');
    _phCtrl       = TextEditingController(text: widget.ph?.toStringAsFixed(1)       ?? '');
    _moistureCtrl = TextEditingController(text: widget.moisture?.toStringAsFixed(1) ?? '');
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

  // ── Helper: dose string ───────────────────────────────────────────────────
  String _trunkDose(int trunkClass, List<int> doses) {
    const sizes = ['very small', 'small', 'medium', 'large'];
    return '${doses[trunkClass]} g per tree  (${sizes[trunkClass]} tree)';
  }

  // ── Farmer-friendly recommendation logic ──────────────────────────────────
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

  // ── Build ──────────────────────────────────────────────────────────────────
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
            _buildSectionHeader('📸 Capture Trunk Image'),
            const SizedBox(height: 10),
            _buildImageSection(),
            const SizedBox(height: 20),
            if (_trunkResult != null) _buildTrunkResult(),
            const SizedBox(height: 20),
            _buildSectionHeader('🌿 Soil NPK Values'),
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

  // ── Image section ─────────────────────────────────────────────────────────
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
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
                    icon: const Icon(Icons.photo_library,
                        color: Colors.white),
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

  // ── Trunk result ──────────────────────────────────────────────────────────
  Widget _buildTrunkResult() {
    final label      = _trunkResult!['label'] as String;
    final confidence = _trunkResult!['confidence'] as String;
    final index      = _trunkResult!['classIndex'] as int;

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple
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
                        fontSize: 13,
                        color: colors[index].withOpacity(0.8))),
                const SizedBox(height: 4),
                Text(descs[index],
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700)),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      style:
                          TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                  child: _buildInput(
                      'N (mg/kg)', _nCtrl, Colors.green)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildInput(
                      'P (mg/kg)', _pCtrl, Colors.amber.shade700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _buildInput(
                      'K (mg/kg)', _kCtrl, Colors.red.shade400)),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      _buildInput('pH', _phCtrl, Colors.teal)),
            ],
          ),
          const SizedBox(height: 10),
          _buildInput('Moisture (%)', _moistureCtrl, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildInput(
      String label, TextEditingController ctrl, Color color) {
    return TextField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color, fontSize: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Recommendation card ───────────────────────────────────────────────────
  Widget _buildRecCard(_FertilizerRec rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(rec.icon, color: rec.color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(rec.nutrient,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
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

          // Farmer advice box
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: rec.statusColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: rec.statusColor.withOpacity(0.3)),
            ),
            child: Text(
              rec.advice,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4),
            ),
          ),

          _recRow(Icons.local_florist, 'Use', rec.fertilizer),
          const SizedBox(height: 6),
          _recRow(Icons.scale, 'Amount', rec.dose),
          const SizedBox(height: 6),
          _recRow(Icons.schedule, 'When', rec.timing),
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
              style: const TextStyle(
                  fontSize: 13, color: Colors.black87)),
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
              'These recommendations are based on trunk size and soil sensor data. '
              'Always consult a local agronomist for region-specific advice.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
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