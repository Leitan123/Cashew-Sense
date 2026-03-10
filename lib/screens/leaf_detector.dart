import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '/widgets/common_widgets.dart';
import '/services/database_service.dart';
import '/data/disease_database.dart';
import '/screens/scan_detail_screen.dart';
import 'package:provider/provider.dart';
import '/services/localization_service.dart';
import '/services/auth_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

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
    final userId = AuthService.instance.currentUserId ?? 0;
    final rows = await DatabaseService.instance.getScans(userId, limit: 20);
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

  /// Check if the image likely contains a leaf by analysing green-channel
  /// dominance. Returns true when enough pixels are "greenish".
  bool _isLeafImage(img.Image image) {
    final sampled = img.copyResize(image, width: 64, height: 64);
    int greenPixels = 0;
    final totalPixels = sampled.width * sampled.height;

    for (int y = 0; y < sampled.height; y++) {
      for (int x = 0; x < sampled.width; x++) {
        final pixel = sampled.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        // A pixel is "greenish" when green is the dominant channel
        if (g > r && g > b && g > 40) {
          greenPixels++;
        }
      }
    }

    final greenRatio = greenPixels / totalPixels;
    // At least 15 % of pixels should be green for a leaf image
    return greenRatio >= 0.15;
  }

  void _runModel(File imageFile) async {
    if (_interpreter == null) return;

    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;

    // Validate: reject non-leaf images before running the disease model
    if (!_isLeafImage(image)) {
      setState(() {
        _image = imageFile;
        _result = '';
      });
      if (mounted) {
        _showInvalidImageDialog();
      }
      return;
    }

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

    final maxConfidence = output[0].reduce((a, b) => a > b ? a : b);
    final maxIndex = output[0].indexOf(maxConfidence);

    final resultLabel =
        '${classNames[maxIndex]} (${(maxConfidence * 100).toStringAsFixed(2)}%)';
    final diseaseName = classNames[maxIndex];

    // Save image permanently out of cache before inserting to db
    final dbPath = await getDatabasesPath();
    final imagesDir = Directory(p.join(dbPath, 'saved_scans'));
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

    final fileName = 'leaf_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final permanentImage = await imageFile.copy(p.join(imagesDir.path, fileName));

    // Persist to SQLite
    final userId = AuthService.instance.currentUserId ?? 0;
    await DatabaseService.instance.insertScan(userId, permanentImage.path, diseaseName);

    // Trigger a sync immediately
    AuthService.instance.syncData();

    setState(() {
      _result = resultLabel;
    });

    // Reload list from DB so Recent Scans is always consistent with the database
    await _loadScansFromDb();
  }

  void _showInvalidImageDialog() {
    final currentLang = context.read<LocalizationService>().currentLanguage;
    final titles = {
      'en': 'Invalid Image',
      'si': 'වලංගු නොවන රූපය',
      'ta': 'தவறான படம்',
    };
    final messages = {
      'en': 'Please upload a correct cashew leaf image for accurate disease detection.',
      'si': 'නිවැරදි කජු පත්‍ර රූපයක් උඩුගත කරන්න.',
      'ta': 'துல்லியமான நோய் கண்டறிதலுக்கு சரியான முந்திரி இலை படத்தை பதிவேற்றவும்.',
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1e2820),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.orangeAccent.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 24),
            const SizedBox(width: 8),
            Text(titles[currentLang] ?? 'Invalid Image',
                style: TextStyle(color: _cream, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          messages[currentLang] ?? 'Please upload a correct cashew leaf image for accurate disease detection.',
          style: TextStyle(color: _cream.withOpacity(0.65), fontSize: 13, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _moss,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
    final currentLang = context.read<LocalizationService>().currentLanguage;
    final db = localizedDiseaseDatabase[currentLang]?[disease];
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
    final currentLang = context.watch<LocalizationService>().currentLanguage;

    final titles = {
      'en': 'Leaf Disease Detector',
      'si': 'පත්‍ර රෝග හඳුනාගැනීම',
      'ta': 'இலை நோய் கண்டறிதல்',
    };
    final recentScansText = {
      'en': 'Recent Scans',
      'si': 'මෑතකදී කළ පරීක්ෂණ',
      'ta': 'சமீபத்திய ஸ்கேன்கள்',
    };
    final noScansText = {
      'en': 'No recent scans found.',
      'si': 'මෑතකදී කළ පරීක්ෂණ කිසිවක් හමු නොවීය.',
      'ta': 'சமீபத்திய ஸ்கேன்கள் எதுவும் கிடைக்கவில்லை.',
    };
    final identifyText = {
      'en': 'Identify Leaf Disease',
      'si': 'පත්‍ර රෝග හඳුනාගන්න',
      'ta': 'இலை நோயைக் கண்டறியவும்',
    };
    final takePhotoText = {
      'en': 'Take Photo',
      'si': 'ඡායාරූපයක් ගන්න',
      'ta': 'படம் எடுக்கவும்',
    };
    final tapCameraText = {
      'en': 'Tap the camera to analyse',
      'si': 'විශ්ලේෂණය කිරීමට කැමරාව ඔබන්න',
      'ta': 'பகுப்பாய்வு செய்ய கேமராவை தொடவும்',
    };

    return Scaffold(
      backgroundColor: _charcoal,
      appBar: buildCashewAppBar(title: titles[currentLang] ?? 'Leaf Disease Detector'),
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
                                Text(identifyText[currentLang] ?? 'Identify Leaf Disease',
                                    style: TextStyle(
                                      color: _cream,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      shadows: const [Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black45)],
                                    )),
                                const SizedBox(height: 4),
                                Text(tapCameraText[currentLang] ?? 'Tap the camera to analyse',
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
                  Text(takePhotoText[currentLang] ?? 'Take Photo',
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
                          recentScansText[currentLang] ?? 'RECENT SCANS',
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
                            child: Text(noScansText[currentLang] ?? 'No recent scans yet.',
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ScanDetailScreen(
                                        imagePath: imageFile.path,
                                        diseaseName: disease,
                                      ),
                                    ),
                                  );
                                },
                                onLongPress: () async {
                                  final id = scan['id'] as int;
                                  
                                  final deleteTitles = {
                                    'en': 'Delete Scan?',
                                    'si': 'පරීක්ෂණය මකා දමන්නද?',
                                    'ta': 'ஸ்கேனை நீக்கவா?',
                                  };
                                  final deleteMsg = {
                                    'en': 'Are you sure you want to remove this scan from your history?',
                                    'si': 'ඔබට මෙම පරීක්ෂණය ඉතිහාසයෙන් ඉවත් කිරීමට අවශ්‍ය බව විශ්වාසද?',
                                    'ta': 'யவரலாற்றிலிருந்து இந்த ஸ்கேனை அகற்ற விரும்புகிறீர்களா?',
                                  };
                                  final cancelText = {
                                    'en': 'CANCEL',
                                    'si': 'අවලංගු කරන්න',
                                    'ta': 'ரத்துசெய்',
                                  };
                                  final deleteText = {
                                    'en': 'DELETE',
                                    'si': 'මකා දමන්න',
                                    'ta': 'நீக்கு',
                                  };

                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: const Color(0xFF1e2820),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        side: BorderSide(color: _lime.withOpacity(0.18)),
                                      ),
                                      title: Row(
                                        children: [
                                          const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                          const SizedBox(width: 8),
                                          Text(deleteTitles[currentLang] ?? 'Delete Scan?',
                                              style: TextStyle(color: _cream, fontSize: 16, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      content: Text(
                                        deleteMsg[currentLang] ?? 'Remove this ${disease.replaceAll("_", " ")} scan from your history?',
                                        style: TextStyle(color: _cream.withOpacity(0.65), fontSize: 13, height: 1.5),
                                      ),
                                      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: Text(cancelText[currentLang] ?? 'Cancel',
                                              style: TextStyle(color: _cream.withOpacity(0.5), fontSize: 13)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent.withOpacity(0.85),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                          ),
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          child: Text(deleteText[currentLang] ?? 'Delete', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await DatabaseService.instance.deleteScan(id);
                                    await _loadScansFromDb();
                                  }
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

