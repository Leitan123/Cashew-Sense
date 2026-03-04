import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '/widgets/common_widgets.dart';
import '/services/database_service.dart';

const _charcoal = Color(0xFF1e2820);
const _moss     = Color(0xFF3d5a2e);
const _leaf     = Color(0xFF5c8a3c);
const _lime     = Color(0xFFa8c96e);
const _cream    = Color(0xFFf5f0e8);

class LeafDetector extends StatefulWidget {
  const LeafDetector({super.key});

  @override
  State<LeafDetector> createState() => _LeafDetectorState();
}

class _LeafDetectorState extends State<LeafDetector> {
  Interpreter? _interpreter;
  File? _image;
  String _result = '';
  final List<String> classNames = ['Anthracnose', 'Healthy', 'Leaf_Miner', 'Red_Rust'];
  // Each entry: { 'id': int, 'imagePath': String, 'diseaseName': String, 'timestamp': int }
  List<Map<String, dynamic>> _recentScans = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initDb();
    _loadModel();
  }

  Future<void> _initDb() async {
    await DatabaseService.instance.init();
    await _loadScansFromDb();
  }

  Future<void> _loadScansFromDb() async {
    final rows = await DatabaseService.instance.getScans(limit: 20);
    setState(() {
      _recentScans = rows;
    });
  }

  Future<void> _loadModel() async {
    try {
      debugPrint('🟡 Loading model...');
      _interpreter = await Interpreter.fromAsset(
        'assets/cashew_classifier_mobile.tflite',
      );
      debugPrint('✅ Model loaded successfully!');
      setState(() {});
    } catch (e) {
      debugPrint('❌ Failed to load model: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = '';
      });
      _runModel(File(pickedFile.path));
    }
  }

  void _runModel(File imageFile) async {
    if (_interpreter == null) return;

    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;

    final resizedImage = img.copyResize(image, width: 128, height: 128);

    final input = Float32List(1 * 128 * 128 * 3);
    int pixelIndex = 0;
    for (int y = 0; y < 128; y++) {
      for (int x = 0; x < 128; x++) {
        final pixel = resizedImage.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    final inputTensor = input.reshape([1, 128, 128, 3]);
    final output = List.generate(1, (_) => List.filled(classNames.length, 0.0));

    _interpreter!.run(inputTensor, output);

    final maxIndex = output[0].indexOf(
      output[0].reduce((a, b) => a > b ? a : b),
    );

    final resultLabel =
        '${classNames[maxIndex]} (${(output[0][maxIndex] * 100).toStringAsFixed(2)}%)';
    final diseaseName = classNames[maxIndex];

    // Persist to SQLite
    await DatabaseService.instance.insertScan(imageFile.path, diseaseName);

    setState(() {
      _result = resultLabel;
    });

    // Reload list from DB so Recent Scans is always consistent with the database
    await _loadScansFromDb();
  }

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  bool get _isHealthy => _result.toLowerCase().contains('healthy');

  String get _detectedDisease {
    if (_result.toLowerCase().contains('anthracnose')) return 'Anthracnose';
    if (_result.toLowerCase().contains('red_rust') || _result.toLowerCase().contains('red rust')) return 'Red_Rust';
    if (_result.toLowerCase().contains('leaf_miner') || _result.toLowerCase().contains('leaf miner')) return 'Leaf_Miner';
    return '';
  }

  Widget _buildDiseasePanel() {
    final disease = _detectedDisease;
    final db = _diseaseDatabase[disease];
    if (db == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1e2820).withOpacity(0.9),
        border: Border.all(color: _lime.withOpacity(0.18)),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Disease header
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3d5a2e), Color(0xFF5c8a3c)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.coronavirus_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(db['common_name'], style: TextStyle(color: _lime, fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(db['scientific_name'], style: TextStyle(color: _cream.withOpacity(0.5), fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text((db['severity'] as String).toUpperCase(),
                    style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.7)),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Description
          Text(db['description'], style: TextStyle(color: _cream.withOpacity(0.65), fontSize: 13, height: 1.6)),

          const SizedBox(height: 20),
          _sectionTitle('Symptoms'),
          ...(db['symptoms'] as List<String>).map((s) => _symptomRow(s)),

          const SizedBox(height: 20),
          _sectionTitle('Remedies & Treatment'),
          ...(db['treatments'] as List<Map<String, dynamic>>).map((t) => _treatmentCard(t)),

          const SizedBox(height: 20),
          _sectionTitle('Prevention'),
          ...(db['prevention'] as List<Map<String, dynamic>>).map((p) => _preventionCard(p)),

          if (db['note'] != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _lime.withOpacity(0.05),
                border: Border.all(color: _lime.withOpacity(0.12)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(db['note'], style: TextStyle(color: _cream.withOpacity(0.6), fontSize: 12, height: 1.6))),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.8)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.07))),
        ],
      ),
    );
  }

  Widget _symptomRow(String sym) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.025), borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠', style: TextStyle(color: Colors.orange, fontSize: 11)),
          const SizedBox(width: 8),
          Expanded(child: Text(sym, style: TextStyle(color: _cream.withOpacity(0.7), fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }

  Widget _treatmentCard(Map<String, dynamic> t) {
    final bool isEco = t['type'] != 'chemical';
    Color typeColor = Colors.redAccent;
    Color typeBg = Colors.redAccent.withOpacity(0.12);
    String typeLabel = 'Chemical';
    if (t['type'] == 'organic') { typeColor = _lime; typeBg = _lime.withOpacity(0.15); typeLabel = 'Organic'; }
    else if (t['type'] == 'biological') { typeColor = Colors.lightBlue; typeBg = Colors.lightBlue.withOpacity(0.12); typeLabel = 'Biological'; }
    else if (t['type'] == 'mechanical') { typeColor = Colors.grey; typeBg = Colors.grey.withOpacity(0.12); typeLabel = 'Mechanical'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEco ? _leaf.withOpacity(0.07) : Colors.redAccent.withOpacity(0.05),
        border: Border.all(color: isEco ? _lime.withOpacity(0.14) : Colors.redAccent.withOpacity(0.14)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(t['name'], style: TextStyle(color: _cream, fontSize: 13, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(50)),
                child: Text(typeLabel.toUpperCase(), style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(t['description'], style: TextStyle(color: _cream.withOpacity(0.65), fontSize: 12, height: 1.5)),
          if (t['timing'] != null || t['note'] != null) ...[
            const SizedBox(height: 8),
            if (t['timing'] != null) Text('🕐 ${t['timing']}', style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 11)),
            if (t['note'] != null) Text('⚠️ ${t['note']}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
          ]
        ],
      ),
    );
  }

  Widget _preventionCard(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p['measure'], style: TextStyle(color: _cream, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(p['description'], style: TextStyle(color: _cream.withOpacity(0.6), fontSize: 12, height: 1.5)),
          if (p['frequency'] != null) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _lime.withOpacity(0.1), borderRadius: BorderRadius.circular(50)),
              child: Text('🔁 ${p['frequency']}', style: TextStyle(color: _lime, fontSize: 10)),
            )
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _charcoal,
      appBar: buildCashewAppBar(title: 'CashewSense'),
      bottomNavigationBar: buildCashewBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
      ),
      body: Stack(
        children: [
          // Background glows
          Positioned(
            top: -40, left: -40,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _leaf.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -50, right: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lime.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Hero Banner ──────────────────────────────────────────
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          image: const DecorationImage(
                            image: AssetImage('assets/leaf_banner.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _moss.withOpacity(0.75),
                                _charcoal.withOpacity(0.6),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle, size: 7, color: _lime),
                                      const SizedBox(width: 5),
                                      const Text('AI POWERED',
                                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text('Identify Leaf Disease',
                                    style: TextStyle(
                                      color: _cream,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      shadows: const [Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black45)],
                                    )),
                                const SizedBox(height: 4),
                                Text('Tap the camera to analyse',
                                    style: TextStyle(color: _cream.withOpacity(0.65), fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Camera FAB
                      Positioned(
                        bottom: -26,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [_moss, _leaf]),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _lime.withOpacity(0.35),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),

                  // ── Label ────────────────────────────────────────────────
                  Text('Take Photo',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: _cream.withOpacity(0.7), letterSpacing: 0.3)),
                  const SizedBox(height: 20),

                  // ── Image + Result ───────────────────────────────────────
                  if (_image != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(_image!, height: 220, width: double.infinity, fit: BoxFit.cover),
                          ),
                          if (_result.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isHealthy
                                      ? [_leaf.withOpacity(0.2), _lime.withOpacity(0.08)]
                                      : [Colors.red.withOpacity(0.15), Colors.red.withOpacity(0.05)],
                                ),
                                border: Border.all(
                                  color: _isHealthy ? _lime.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                    color: _isHealthy ? _lime : Colors.redAccent,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _result,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _isHealthy ? _lime : Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_isHealthy) ...[
                              const SizedBox(height: 20),
                              _buildDiseasePanel(),
                            ],
                          ],
                        ],
                      ),
                    )
                  else
                    Icon(Icons.image_outlined, size: 120, color: _cream.withOpacity(0.12)),

                  const SizedBox(height: 32),

                  // ── Recent Scans ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'RECENT SCANS',
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
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: _recentScans.isEmpty
                        ? Center(
                            child: Text('No recent scans yet.',
                                style: TextStyle(color: _cream.withOpacity(0.3), fontSize: 13)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: _recentScans.length,
                            itemBuilder: (context, index) {
                              final scan = _recentScans[index];
                              final imageFile = File(scan['imagePath'] as String);
                              final disease = scan['diseaseName'] as String;
                              final isHealthy = disease.toLowerCase() == 'healthy';
                              return GestureDetector(
                                onLongPress: () async {
                                  // Long-press to delete
                                  final id = scan['id'] as int;
                                  await DatabaseService.instance.deleteScan(id);
                                  await _loadScansFromDb();
                                },
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isHealthy
                                          ? _lime.withOpacity(0.4)
                                          : Colors.redAccent.withOpacity(0.4),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(
                                          imageFile,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: Colors.grey.withOpacity(0.2),
                                            child: const Icon(Icons.broken_image,
                                                color: Colors.white38),
                                          ),
                                        ),
                                        // Disease name label at the bottom
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4, horizontal: 6),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.75),
                                                ],
                                              ),
                                            ),
                                            child: Text(
                                              disease.replaceAll('_', ' '),
                                              style: TextStyle(
                                                color: isHealthy ? _lime : Colors.redAccent,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Disease Database ──────────────────────────────────────────────────────────
const Map<String, dynamic> _diseaseDatabase = {
  'Anthracnose': {
    'common_name': 'Anthracnose',
    'scientific_name': 'Colletotrichum gloeosporioides',
    'severity': 'high',
    'description':
        'A widespread fungal disease affecting cashew leaves, flowers, and developing nuts. Severe during rainy seasons; spores spread rapidly via wind and rain splash.',
    'symptoms': [
      'Dark brown/black spots on leaves',
      'Leaf tip drying and scorching',
      'Flower blight — inflorescence turns brown and drops',
      'Young nut drop before maturity',
      'Dieback of shoots in severe cases',
    ],
    'treatments': [
      {
        'name': 'Field Sanitation',
        'type': 'mechanical',
        'description':
            'Remove infected leaves, flowers, and fallen debris. Prune infected branches and burn or bury all infected material. Reduces fungal spore load significantly.',
        'timing': 'Immediately upon detecting symptoms',
      },
      {
        'name': 'Copper Oxychloride (0.3%)',
        'type': 'chemical',
        'description': 'Apply as preventive and curative spray on canopy. Highly effective at suppressing Colletotrichum.',
        'timing': 'Before flowering, at flowering, after fruit set. Repeat every 15–20 days during heavy rain.',
      },
      {
        'name': 'Bordeaux Mixture (1%)',
        'type': 'chemical',
        'description': 'A classic copper-lime based fungicide. Good protectant activity and helps prevent spread.',
        'timing': 'Before and during rainy season',
      },
      {
        'name': 'Carbendazim / Propiconazole / Mancozeb',
        'type': 'chemical',
        'description':
            'Systemic fungicides (Carbendazim, Propiconazole) for curative effect. Mancozeb as a contact protectant. Rotate between different chemical groups to prevent resistance.',
        'timing': 'Second and third spray in season',
        'note': 'Rotate fungicides to prevent resistance build-up.',
      },
      {
        'name': 'Trichoderma-based Biofungicide',
        'type': 'biological',
        'description': 'Apply Trichoderma viride or T. harzianum as soil drench or foliar spray for eco-friendly suppression.',
        'timing': 'Before rainy season as a preventive measure',
      },
      {
        'name': 'Neem Oil Spray (2%)',
        'type': 'organic',
        'description': 'Mild preventive spray. Best used as an early-stage or low-pressure treatment.',
        'timing': 'Early signs / supplementary use',
      },
    ],
    'prevention': [
      {
        'measure': 'Improve Air Circulation',
        'description': 'Prune overcrowded canopy. Maintain proper spacing between trees to reduce leaf wetness duration.',
        'frequency': 'Annually after harvest',
      },
      {
        'measure': 'Balanced Nutrition',
        'description':
            'Avoid excessive nitrogen fertilizer — too much soft growth is more susceptible to infection. Apply proper NPK with micronutrients.',
        'frequency': 'At each fertilization cycle',
      },
      {
        'measure': 'Preventive Sprays Before Rainy Season',
        'description': 'In humid climates with heavy monsoon rains, begin preventive copper sprays before the rains arrive.',
        'frequency': 'Before each monsoon onset',
      },
    ],
    'note':
        'For research: Record disease severity index (0–5 scale) per tree along with rainfall data, tree age, canopy density, and fungicide history. This data can reveal disease-severity vs nut quality correlation and help identify disease-resistant trees.',
  },
  'Red_Rust': {
    'common_name': 'Red Rust (Algal Leaf Spot)',
    'scientific_name': 'Cephaleuros virescens',
    'severity': 'medium',
    'description':
        'Caused by an algal pathogen (not a fungus). Orange-red velvety patches appear on older leaves and stems. Thrives in humid, shaded orchards with poor drainage. Common during Sri Lankan monsoon season.',
    'symptoms': [
      'Orange-red to rust-coloured velvety circular patches on leaves',
      'Patches mostly appear on older leaves and on the upper surface',
      'Can also affect bark/stems of young branches',
      'Common in humid, dense, and poorly-drained orchards',
    ],
    'treatments': [
      {
        'name': 'Copper Oxychloride (0.3%)',
        'type': 'chemical',
        'description':
            'Most effective treatment for algal leaf spot. Spray directly on affected leaves and branches.',
        'timing': '2–3 sprays during early rainy season',
      },
      {
        'name': 'Bordeaux Mixture (1%)',
        'type': 'chemical',
        'description': 'Copper-lime based spray. Effective as a preventive coat against algal spread.',
        'timing': 'Before rainy season, repeat at 3-week intervals',
      },
    ],
    'prevention': [
      {
        'measure': 'Pruning & Sunlight Management',
        'description':
            'Thin dense canopy to improve sunlight penetration. Red rust thrives in humid and shaded conditions. Remove crossing branches.',
        'frequency': 'Annually, after harvest',
      },
      {
        'measure': 'Improve Drainage',
        'description': 'Ensure good soil drainage in the orchard. Avoid waterlogging at tree base.',
      },
      {
        'measure': 'Balanced Nutrition',
        'description':
            'Apply proper NPK fertilizers. Include micronutrients especially Zinc and Magnesium. Healthy, well-nourished trees resist algal infection better.',
        'frequency': 'Each fertilization cycle',
      },
      {
        'measure': 'Preventive Spraying',
        'description': 'In high-humidity climates, begin copper spray programme before the rainy season.',
        'frequency': 'Before every monsoon',
      },
    ],
    'note':
        'Red rust is caused by algae, not fungi — so conventional fungicides are less effective. Copper-based products are the most reliable control option.',
  },
  'Leaf_Miner': {
    'common_name': 'Leaf Miner',
    'scientific_name': 'Acrocercops syngramma',
    'severity': 'low',
    'description':
        'A minor pest primarily affecting young cashew leaves. Tiny caterpillars tunnel between the upper and lower surfaces of tender leaves, forming distinctive silvery blisters or serpentine trails.',
    'symptoms': [
      'Silvery or whitish blisters / mines on the upper surface of young leaves',
      'Serpentine (winding) trails visible through leaf surface',
      'Leaves may curl, distort, and dry up in severe cases',
      'Mostly affects the first flush of new leaves',
    ],
    'treatments': [
      {
        'name': 'Natural Enemy Conservation',
        'type': 'biological',
        'description':
            'Parasitic wasps (chalcid parasitoids) naturally feed on leaf miner larvae. Avoid broad-spectrum pesticides that kill these beneficial insects.',
        'timing': 'Ongoing — encourage year-round',
      },
      {
        'name': 'Neem Oil Spray (2%)',
        'type': 'organic',
        'description': 'Spray 2% neem oil (with soft soap as emulsifier) during flushing to deter egg-laying females.',
        'timing': 'At first sign of new flushing',
        'frequency': 'Every 10–15 days during flush period',
      },
      {
        'name': 'Dimethoate (30 EC)',
        'type': 'chemical',
        'description':
            'Spray Dimethoate 30 EC at 1.5 ml/litre only if the infestation exceeds the Economic Threshold Level. Avoid routine use to protect natural enemies.',
        'timing': 'New flush period',
        'note': 'Use only when infestation is severe; rotate with other chemistries.',
      },
    ],
    'prevention': [
      {
        'measure': 'Monitor New Flushes',
        'description':
            'Inspect flushing regularly to detect early leaf miner activity before populations build up.',
        'frequency': 'Weekly during flush periods',
      },
      {
        'measure': 'Avoid Over-fertilising with Nitrogen',
        'description':
            'Excess nitrogen promotes rapid, soft flushes that are more attractive to leaf miner egg-laying. Use balanced NPK.',
      },
    ],
    'note':
        'Leaf miner is generally a minor pest and rarely causes significant economic damage. Heavy-handed chemical use often kills natural parasitoids and worsens long-term infestations.',
  },
};


