import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '/widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  Expanded Data Models based on the web UI
// ─────────────────────────────────────────────────────────────

class TreatmentInfo {
  final String name;
  final String type; // 'organic', 'biological', 'mechanical', 'chemical'
  final bool ecoFriendly;
  final String description;
  final String? timing;
  final String? frequency;

  const TreatmentInfo({
    required this.name,
    required this.type,
    required this.ecoFriendly,
    required this.description,
    this.timing,
    this.frequency,
  });
}

class PreventionInfo {
  final String measure;
  final String description;
  final String? frequency;

  const PreventionInfo({
    required this.measure,
    required this.description,
    this.frequency,
  });
}

class PestInfo {
  final String name;
  final String emoji;
  final String scientificName;
  final String target;
  final String severity; // 'High' | 'Medium' | 'Low'
  final String description;
  final List<String> symptoms;
  final List<TreatmentInfo> treatments;
  final List<PreventionInfo> prevention;
  final String? additionalInfo;

  const PestInfo({
    required this.name,
    required this.emoji,
    required this.scientificName,
    required this.target,
    required this.severity,
    required this.description,
    this.symptoms = const [],
    this.treatments = const [],
    this.prevention = const [],
    this.additionalInfo,
  });
}

class PestDetector extends StatefulWidget {
  const PestDetector({super.key});

  @override
  State<PestDetector> createState() => _PestDetectorState();
}

class _PestDetectorState extends State<PestDetector>
    with SingleTickerProviderStateMixin {
  // ── TFLite ───────────────────────────────────────────────
  Interpreter? _interpreter;

  // ── State ────────────────────────────────────────────────
  File? _image;
  String _result = '';
  double _confidence = 0.0;
  bool _isAnalyzing = false;
  int _selectedNav = 2; // "Pests" tab active
  String? _error;

  // ── Animation ────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Color palette matching the web UI ────────────────────
  static const Color moss = Color(0xFF3D5A2E);
  static const Color leaf = Color(0xFF5C8A3C);
  static const Color lime = Color(0xFFA8C96E);
  static const Color cream = Color(0xFFF5F0E8);
  static const Color charcoal = Color(0xFF1E2820);
  
  static const Color danger = Color(0xFFE74C3C);
  static const Color warn = Color(0xFFF39C12);
  static const Color ok = Color(0xFF2ECC71);

  // ── Pest classes with expanded recommendations ────────────
  static const List<PestInfo> pestClasses = [
    PestInfo(
      name: 'Stem Borer',
      emoji: '🪲',
      scientificName: 'Plocaederus ferrugineus L.',
      target: 'Stem',
      severity: 'High',
      description: 'The Cashew Stem and Root Borer (CSRB) is the most destructive pest of cashew. The grubs bore into the trunk and roots, feeding on the bark and tissues, which can ultimately kill the tree.',
      symptoms: [
        'Presence of frass (wood dust and excreta) near the base of the trunk.',
        'Yellowing of leaves and gradual drying of the canopy.',
        'Gum exudation from the bored holes on the stem.'
      ],
      treatments: [
        TreatmentInfo(
          name: 'Manual Extraction',
          type: 'mechanical',
          ecoFriendly: true,
          description: 'Carefully peel the bark and extract the grubs mechanically if the infestation is detected early.',
          timing: 'At first sign of frass',
        ),
        TreatmentInfo(
          name: 'Chlorpyrifos Swabbing',
          type: 'chemical',
          ecoFriendly: false,
          description: 'Swab the trunk region up to 1 meter height with 0.2% chlorpyrifos solution.',
          timing: 'Post-monsoon (Nov-Dec)'
        )
      ],
      prevention: [
        PreventionInfo(
          measure: 'Phytosanitation',
          description: 'Remove and destroy dead and severely affected trees to prevent the spread of beetles.',
          frequency: 'Ongoing'
        ),
        PreventionInfo(
          measure: 'Trunk Painting',
          description: 'Paint the trunk with coal tar and kerosene (1:2) up to 1m height to deter egg laying.',
          frequency: 'Pre-monsoon'
        ),
      ],
      additionalInfo: 'Early detection is critical. Once the grubs reach the root zone, saving the tree becomes extremely difficult.',
    ),
    PestInfo(
      name: 'Mites',
      emoji: '🐜',
      scientificName: 'Tetranychus spp.',
      target: 'Leaves',
      severity: 'Medium',
      description: 'Mites are tiny arachnids that suck sap from the undersides of leaves, causing yellowing and webbing in severe cases.',
      symptoms: [
        'Yellow stippling or spotting on the upper leaf surface.',
        'Fine webbing on the undersides of leaves.',
        'Curling or bronzing of leaves.'
      ],
      treatments: [
        TreatmentInfo(
          name: 'Water Spray',
          type: 'mechanical',
          ecoFriendly: true,
          description: 'Apply a strong stream of water to the undersides of leaves to knock off mites.',
          timing: 'At first sign of infestation',
          frequency: 'Daily for a week'
        ),
        TreatmentInfo(
          name: 'Sulphur Dust',
          type: 'chemical',
          ecoFriendly: false,
          description: 'Apply wettable sulphur spray or dust to manage heavy mite populations.',
          timing: 'When symptoms spread'
        )
      ],
      prevention: [
        PreventionInfo(
          measure: 'Maintain Humidity',
          description: 'Mites thrive in dry conditions. Keeping the soil moist and humidity up can deter them.',
          frequency: 'Ongoing'
        )
      ],
    ),
    PestInfo(
      name: 'Thrips',
      emoji: '🐝',
      scientificName: 'Scirtothrips dorsalis',
      target: 'Flowers',
      severity: 'Medium',
      description: 'Tiny insects that scrape the surface of tender floral parts and raw nuts, causing corky outgrowths and reducing nut quality.',
      symptoms: [
        'Corky, scabby outgrowths on the surface of developing nuts.',
        'Shedding of severe infested flowers.',
        'Silvery patches on the underside of leaves.'
      ],
      treatments: [
        TreatmentInfo(
          name: 'Spinosad',
          type: 'biological',
          ecoFriendly: true,
          description: 'Apply Spinosad, a natural insecticide derived from soil bacteria.',
          timing: 'Early flowering'
        ),
        TreatmentInfo(
          name: 'Imidacloprid',
          type: 'chemical',
          ecoFriendly: false,
          description: 'Systemic insecticide application for heavy infestations.',
          timing: 'Nut setting stage'
        )
      ],
      prevention: [
        PreventionInfo(
          measure: 'Weed Management',
          description: 'Keep the plantation weed-free, as many weeds act as alternate hosts.',
          frequency: 'Monthly'
        )
      ],
    ),
    PestInfo(
      name: 'No Pest',
      scientificName: 'Healthy Subject',
      emoji: '🌿',
      target: 'Clean',
      severity: 'Low',
      description: 'The uploaded image shows no signs of recognized pests. The plant material appears healthy.',
      prevention: [
        PreventionInfo(
          measure: 'Regular Monitoring',
          description: 'Continue inspecting the orchard every 7-10 days, especially during flushing and flowering seasons.',
          frequency: 'Weekly'
        ),
        PreventionInfo(
          measure: 'Nutrient Management',
          description: 'Ensure balanced application of fertilizers to maintain plant vigor, helping them resist potential pest attacks natively.',
          frequency: 'Bi-annually'
        )
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadModel();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/pest_model.tflite',
      );
    } catch (e) {
      debugPrint('❌ Failed to load pest model: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    setState(() {
      _image = file;
      _result = '';
      _confidence = 0.0;
      _isAnalyzing = true;
      _error = null;
    });
    
    // Slight delay for UI to show loading state smoothly
    await Future.delayed(const Duration(milliseconds: 300));
    await _runModel(file);
  }

  Future<void> _runModel(File imageFile) async {
    if (_interpreter == null) {
      setState(() {
        _error = "Model not loaded. Please restart the app.";
        _isAnalyzing = false;
      });
      return;
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception("Failed to decode image");

      final oriented = img.bakeOrientation(image);

      // YOLOv8 Letterbox resizing: Resize while maintaining aspect ratio,
      // then pad to 640x640 with a neutral gray color (114,114,114).
      int width = oriented.width;
      int height = oriented.height;
      double scale = 640 / (width > height ? width : height);
      int newWidth = (width * scale).toInt();
      int newHeight = (height * scale).toInt();

      final resized = img.copyResize(
        oriented,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      final letterbox = img.Image(width: 640, height: 640)
        ..clear(img.ColorRgb8(114, 114, 114));
      
      int xOffset = (640 - newWidth) ~/ 2;
      int yOffset = (640 - newHeight) ~/ 2;
      
      img.compositeImage(letterbox, resized, dstX: xOffset, dstY: yOffset);

      final input = Float32List(1 * 640 * 640 * 3);
      int idx = 0;

      for (int y = 0; y < 640; y++) {
        for (int x = 0; x < 640; x++) {
          final pixel = letterbox.getPixel(x, y);
          input[idx++] = pixel.r / 255.0;
          input[idx++] = pixel.g / 255.0;
          input[idx++] = pixel.b / 255.0;
        }
      }

      final inputTensor = input.reshape([1, 640, 640, 3]);
      // YOLOv8 Output shape is [1, 7, 8400]
      // where 7 = 4 bbox coordinates + 3 class scores for 8400 grid cells
      final outputTensor = List.generate(
          1,
          (_) => List.generate(
              7, (_) => List.filled(8400, 0.0))); 

      _interpreter!.run(inputTensor, outputTensor);

      // Simple processing: Find the maximum class probability across all 8400 cells
      double maxClassProb = 0.0;
      int bestClassIdx = -1;

      // Class probabilities start at channel 4 (0=x, 1=y, 2=w, 3=h, 4=class0, 5=class1, 6=class2)
      for (int cellIdx = 0; cellIdx < 8400; cellIdx++) {
        for (int classFolderIdx = 0; classFolderIdx < 3; classFolderIdx++) {
           double prob = outputTensor[0][4 + classFolderIdx][cellIdx];
           if (prob > maxClassProb) {
             maxClassProb = prob;
             bestClassIdx = classFolderIdx;
           }
        }
      }
      
      String res = "No Pest";
      if (maxClassProb > 0.25 && bestClassIdx != -1) {
          // Actual model mapping detected from best.pt:
          // 0: Thrips
          // 1: mites
          // 2: stem_borer
          if (bestClassIdx == 0) res = "Thrips";
          if (bestClassIdx == 1) res = "Mites";
          if (bestClassIdx == 2) res = "Stem Borer";
      }

      setState(() {
        _result = res;
        _confidence = maxClassProb;
        _isAnalyzing = false;
      });
    } catch (e) {
      debugPrint("\$e");
      setState(() {
        _error = "Error analyzing image: \$e";
        _isAnalyzing = false;
      });
    }
  }

  PestInfo? get _detectedPest {
    if (_result.isEmpty) return null;
    try {
      return pestClasses.firstWhere((p) => p.name == _result);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Build Methods
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: charcoal,
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'DM Sans',
              bodyColor: cream.withOpacity(0.9),
              displayColor: cream,
            ),
      ),
      child: Scaffold(
        bottomNavigationBar: buildCashewBottomNav(
          currentIndex: _selectedNav,
          onTap: (i) => setState(() => _selectedNav = i),
        ),
        body: Stack(
          children: [
            // Background ambient glow (matching CSS body::before/after)
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: leaf.withOpacity(0.15),
                ),
                child: const SizedBox(),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lime.withOpacity(0.15),
                ),
                child: const SizedBox(),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTopHeader(),
                    _buildMainContent(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildTopHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [moss, leaf],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.1,
              child: Transform.rotate(
                angle: 0.35,
                child: const Text('🌿', style: TextStyle(fontSize: 80)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: lime,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'AI POWERED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                  ),
                  children: [
                    TextSpan(text: 'Cashew '),
                    TextSpan(text: 'Pest\n', style: TextStyle(color: lime)),
                    TextSpan(text: 'Detection'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Upload a leaf or nut photo for instant pest identification and treatment advice.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: lime,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Model ready · Cashew Crop AI v1.0',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: charcoal.withOpacity(0.8),
        border: Border.all(color: lime.withOpacity(0.18)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildUploadSection(),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          _buildRecommendationsSection(),
        ],
      ),
    );
  }

  // ── Upload Section (Left Panel equivalent) ───────────────
  Widget _buildUploadSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: danger.withOpacity(0.1),
                border: Border.all(color: danger.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: danger, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: danger, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          Text(
            'UPLOAD IMAGE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: cream.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 12),
          
          // Drop Zone
          GestureDetector(
            onTap: _showPickerSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: lime.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: lime.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid, // Flutter doesn't natively do dashed borders easily without a package
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [moss, leaf],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: leaf.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text('🔬', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _image == null ? 'Tap to browse' : 'Image Selected',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cream,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _image == null ? 'Camera or Gallery options' : 'Tap to change image',
                      style: TextStyle(
                        fontSize: 12,
                        color: cream.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          
          // Action Button
          GestureDetector(
            onTap: _image == null ? _showPickerSheet : () => _runModel(_image!),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [leaf, lime],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: leaf.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: _isAnalyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(charcoal),
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🌿', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 8),
                          Text(
                            'Analyse for Pests',
                            style: TextStyle(
                              color: charcoal,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          if (_image != null && !_isAnalyzing) ...[
            const SizedBox(height: 24),
            Text(
              'DETECTION OUTPUT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: cream.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 12),
            
            // Preview Image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.3),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  Image.file(
                    _image!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.85),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        '📷 Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [leaf.withOpacity(0.18), lime.withOpacity(0.07)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: lime.withOpacity(0.28)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [moss, leaf],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(_detectedPest?.emoji ?? '🐛', style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DETECTED PEST',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.2,
                              color: cream.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _result,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: lime,
                            ),
                          ),
                          if (_detectedPest != null)
                            Text(
                              _detectedPest!.scientificName,
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: cream.withOpacity(0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_detectedPest != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _severityColor(_detectedPest!.severity).withOpacity(0.15),
                          border: Border.all(
                            color: _severityColor(_detectedPest!.severity).withOpacity(0.3)
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          _detectedPest!.severity.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: _severityColor(_detectedPest!.severity),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ]
          ],
        ],
      ),
    );
  }

  Color _severityColor(String sev) {
    switch (sev.toLowerCase()) {
      case 'high': return danger;
      case 'medium': return warn;
      default: return ok;
    }
  }

  // ── Recommendations Section (Right Panel equivalent) ──────
  Widget _buildRecommendationsSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _image == null
          ? _buildEmptyState('🌱', 'Awaiting Detection', 'Upload a cashew leaf or nut image above. Recommendations will appear here after analysis.')
          : _isAnalyzing
              ? _buildEmptyState('🔄', 'Analyzing...', 'Please wait while we process the image.')
              : _result.isEmpty
                  ? _buildEmptyState('⚠️', 'Analysis Failed', 'Could not detect pest information. Please try another image.')
                  : _buildReccomendationDetails(),
    );
  }

  Widget _buildEmptyState(String icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Opacity(
            opacity: 0.6,
            child: Text(icon, style: const TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cream,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cream.withOpacity(0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReccomendationDetails() {
    final pest = _detectedPest;
    if (pest == null) return _buildEmptyState('🔍', 'No Recommendation Found', 'No data found for $_result. Please consult an agronomist.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About This Pest'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.025),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            pest.description,
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: cream.withOpacity(0.6),
            ),
          ),
        ),

        if (pest.symptoms.isNotEmpty) ...[
          _buildSectionTitle('Symptoms to Look For'),
          ...pest.symptoms.map((s) => _buildSymptomItem(s)),
        ],

        if (pest.treatments.isNotEmpty) ...[
          _buildSectionTitle('Treatment Options'),
          ...pest.treatments.map((t) => _buildTreatmentCard(t)),
        ],

        if (pest.prevention.isNotEmpty) ...[
          _buildSectionTitle('Prevention Measures'),
          ...pest.prevention.map((p) => _buildPreventionItem(p)),
        ],

        if (pest.additionalInfo != null) ...[
          _buildSectionTitle('Additional Notes'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lime.withOpacity(0.04),
              border: Border.all(color: lime.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pest.additionalInfo!,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: cream.withOpacity(0.6),
                    ),
                  ),
                )
              ],
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: cream.withOpacity(0.4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.06),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSymptomItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠', style: TextStyle(color: warn, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: cream.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(TreatmentInfo t) {
    final bgColor = t.ecoFriendly ? leaf.withOpacity(0.08) : danger.withOpacity(0.05);
    final borderColor = t.ecoFriendly ? lime.withOpacity(0.16) : danger.withOpacity(0.16);
    
    Color badgeColor;
    Color badgeBg;
    switch(t.type) {
      case 'organic':
        badgeColor = lime; badgeBg = lime.withOpacity(0.18); break;
      case 'biological':
        badgeColor = Colors.lightBlue; badgeBg = Colors.lightBlue.withOpacity(0.15); break;
      case 'mechanical':
        badgeColor = Colors.grey; badgeBg = Colors.grey.withOpacity(0.15); break;
      default:
        badgeColor = danger; badgeBg = danger.withOpacity(0.15);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: cream,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  t.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.description,
            style: TextStyle(
              fontSize: 11,
              color: cream.withOpacity(0.55),
              height: 1.5,
            ),
          ),
          if (t.timing != null || t.frequency != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (t.timing != null)
                  Text(
                    '🕐 ${t.timing}',
                    style: TextStyle(fontSize: 10, color: cream.withOpacity(0.4)),
                  ),
                if (t.timing != null && t.frequency != null)
                  const SizedBox(width: 12),
                if (t.frequency != null)
                  Text(
                    '🔁 ${t.frequency}',
                    style: TextStyle(fontSize: 10, color: cream.withOpacity(0.4)),
                  ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildPreventionItem(PreventionInfo p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.measure,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cream,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            p.description,
            style: TextStyle(
              fontSize: 11,
              color: cream.withOpacity(0.55),
              height: 1.4,
            ),
          ),
          if (p.frequency != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: lime.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '🔁 ${p.frequency}',
                style: const TextStyle(
                  fontSize: 9,
                  color: lime,
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
  

  // ── Bottom Sheet for Image Picking ───────────────────────
  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: charcoal,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose Input',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cream,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _sheetOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    bg: moss,
                    iconColor: Colors.white,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sheetOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    bg: Colors.white.withOpacity(0.05),
                    iconColor: cream,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required Color bg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}