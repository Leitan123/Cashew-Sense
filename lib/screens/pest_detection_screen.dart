import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/yolo_service.dart';
import '../widgets/common_widgets.dart';
import '../services/localization_service.dart';
class PestDetectionScreen extends StatefulWidget {
  const PestDetectionScreen({super.key});

  @override
  State<PestDetectionScreen> createState() => _PestDetectionScreenState();
}

class _PestDetectionScreenState extends State<PestDetectionScreen> {
  File? _imageFile;
  List<List<double>> _predictions = [];
  final YoloService _yoloService = YoloService();
  bool _loading = false;
  bool _modelLoaded = false;
  
  // UI Colors based on the web design
  final Color _moss = const Color(0xFF3d5a2e);
  final Color _leaf = const Color(0xFF5c8a3c);
  final Color _lime = const Color(0xFFa8c96e);
  final Color _cream = const Color(0xFFf5f0e8);
  final Color _charcoal = const Color(0xFF1e2820);

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() => _loading = true);
    try {
      await _yoloService.loadModel(
        modelPath: 'assets/pest_model.tflite',
        classes: [
          'Thrips',
          'mites',
          'stem_borer',
        ],
      );
      setState(() {
        _modelLoaded = true;
        _loading = false;
      });
    } catch (e) {
      print("Error loading model: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading model: $e")),
        );
      }
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    if (!_modelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Model is not loaded yet")),
      );
      return;
    }

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _predictions = [];
      _loading = true;
    });

    final results = await _yoloService.predict(_imageFile!);

    setState(() {
      _predictions = results;
      _loading = false;
    });
  }

  // Get the most confident prediction's class index to show its info
  int _getTopPredictionClassIndex() {
    if (_predictions.isEmpty) return -1;
    final topPred = _predictions[0];
    if (topPred.length > 5) {
      return topPred[5].toInt();
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    int topClassIdx = _getTopPredictionClassIndex();
    String detectedLabel = topClassIdx >= 0 && topClassIdx < _yoloService.classNames.length 
        ? _yoloService.classNames[topClassIdx] 
        : '';
        
    Map<String, dynamic>? recommendation =_pestDatabase[detectedLabel];

    return Scaffold(
      backgroundColor: _charcoal,
      appBar: buildCashewAppBar(title: 'Pest Detection'.tr(context)),
      body: Stack(
        children: [
          // Background blurry glows
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _leaf.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ColorFilter.mode(Colors.black.withOpacity(0), BlendMode.dst),
                child: Container(),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lime.withOpacity(0.15),
              ),
               child: BackdropFilter(
                filter: ColorFilter.mode(Colors.black.withOpacity(0), BlendMode.dst),
                child: Container(),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  _buildHeaderCard(),
                  const SizedBox(height: 24),
                  
                  // Left Panel (Upload & Preview)
                  _buildUploadSection(detectedLabel, recommendation),
                  const SizedBox(height: 24),
                  
                  // Right Panel (Recommendations)
                  _buildRecommendationsPanel(detectedLabel, recommendation),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_moss, _leaf],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: _lime),
                const SizedBox(width: 6),
                const Text('AI POWERED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Playfair Display'),
              children: [
                const TextSpan(text: 'Cashew '),
                TextSpan(text: 'Pest', style: TextStyle(color: _lime)),
                const TextSpan(text: '\nDetection'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Upload a leaf or nut photo for instant pest identification and treatment advice.',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: _lime),
              const SizedBox(width: 6),
              Text(
                'Model ready · Cashew Crop AI v1.0',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildUploadSection(String detectedLabel, Map<String, dynamic>? recommendation) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1e2820).withOpacity(0.88),
        border: Border.all(color: _lime.withOpacity(0.18)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UPLOAD IMAGE', style: TextStyle(color: _cream.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: _lime.withOpacity(0.03),
                border: Border.all(color: _lime.withOpacity(0.3), width: 2, style: BorderStyle.solid), // Flutter doesn't easily do dashed borders without a custom painter or package, fallback to solid
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_moss, _leaf]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: _leaf.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 6))],
                    ),
                    child: const Icon(Icons.science, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text('Tap to pick image', style: TextStyle(color: _cream, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('from your gallery or camera', style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 13)),
                  if (_imageFile != null) ...[
                    const SizedBox(height: 12),
                    Text('✓ Selected Image', style: TextStyle(color: _lime, fontSize: 13, fontWeight: FontWeight.bold)),
                  ]
                ],
              ),
            ),
          ),
          
          if (_loading) ...[
             const SizedBox(height: 24),
             const Center(child: CircularProgressIndicator()),
          ],

          if (_imageFile != null && !_loading) ...[
            const SizedBox(height: 24),
            Text('DETECTION OUTPUT', style: TextStyle(color: _cream.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Stack(
                  children: [
                    Image.file(_imageFile!, fit: BoxFit.contain, width: double.infinity),
                    if (_predictions.isNotEmpty)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final scaleX = constraints.maxWidth / 640;
                            final scaleY = constraints.maxHeight / 640;
                            return CustomPaint(
                              painter: BoxPainter(_predictions, scaleX, scaleY, _yoloService.classNames),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          if (detectedLabel.isNotEmpty) ...[
             const SizedBox(height: 20),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 gradient: LinearGradient(colors: [_leaf.withOpacity(0.18), _lime.withOpacity(0.07)]),
                 border: Border.all(color: _lime.withOpacity(0.28)),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Row(
                 children: [
                   Container(
                     width: 48,
                     height: 48,
                     decoration: BoxDecoration(
                       gradient: LinearGradient(colors: [_moss, _leaf]),
                       borderRadius: BorderRadius.circular(10),
                     ),
                     child: const Icon(Icons.bug_report, color: Colors.white),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('DETECTED PEST', style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                         const SizedBox(height: 2),
                         Text(detectedLabel, style: TextStyle(color: _lime, fontSize: 16, fontWeight: FontWeight.bold)),
                         if (recommendation != null)
                           Text(recommendation['scientific_name'], style: TextStyle(color: _cream.withOpacity(0.5), fontSize: 12, fontStyle: FontStyle.italic)),
                       ],
                     ),
                   ),
                   if (recommendation != null)
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                       decoration: BoxDecoration(
                         color: Colors.red.withOpacity(0.15),
                         border: Border.all(color: Colors.red.withOpacity(0.3)),
                         borderRadius: BorderRadius.circular(50),
                       ),
                       child: Text(
                         recommendation['severity']?.toUpperCase() ?? 'HIGH',
                         style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.7),
                       ),
                     ),
                 ],
               ),
             ),
          ]
        ],
      ),
    );
  }

  Widget _buildRecommendationsPanel(String detectedLabel, Map<String, dynamic>? rec) {
    if (_imageFile == null) {
      // Empty state waiting
      return _buildEmptyState('🌱', 'Awaiting Detection', 'Upload a cashew leaf or nut image above. Recommendations will appear here after analysis.');
    } else if (_loading) {
       return const SizedBox.shrink();
    } else if (detectedLabel.isNotEmpty && rec == null) {
      // Detected something but no matching data
      return _buildEmptyState('🔍', 'No Recommendation Found', 'No data found for $detectedLabel. Please consult an agronomist.');
    } else if (rec != null) {
      // Show Recommendations
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1e2820).withOpacity(0.88),
          border: Border.all(color: _lime.withOpacity(0.18)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('About This Pest'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.025),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(rec['description'], style: TextStyle(color: _cream.withOpacity(0.7), fontSize: 13, height: 1.6)),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Symptoms to Look For'),
            ...(rec['symptoms'] as List<String>).map((sym) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚠', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(sym, style: TextStyle(color: _cream.withOpacity(0.7), fontSize: 13, height: 1.5))),
                  ],
                ),
              ),
            )),
            
            if (rec['treatments'] != null) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Treatment Options'),
              ...(rec['treatments'] as List<dynamic>).map((t) => _buildTreatmentCard(t)),
            ],

            if (rec['prevention'] != null) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Prevention Measures'),
              ...(rec['prevention'] as List<dynamic>).map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  border: Border.all(color: Colors.white.withOpacity(0.045)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['measure'], style: TextStyle(color: _cream, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(p['description'], style: TextStyle(color: _cream.withOpacity(0.6), fontSize: 13, height: 1.5)),
                    if (p['frequency'] != null) ...[
                       const SizedBox(height: 8),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(color: _lime.withOpacity(0.1), borderRadius: BorderRadius.circular(50)),
                         child: Text('🔁 ${p['frequency']}', style: TextStyle(color: _lime, fontSize: 10)),
                       )
                    ]
                  ],
                ),
              )),
            ],

             if (rec['additional_info'] != null) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Additional Notes'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _lime.withOpacity(0.04),
                    border: Border.all(color: _lime.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡'),
                      const SizedBox(width: 10),
                      Expanded(child: Text(rec['additional_info'], style: TextStyle(color: _cream.withOpacity(0.6), fontSize: 13, height: 1.5))),
                    ],
                  ),
                ),
             ]
            
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildTreatmentCard(Map<String, dynamic> t) {
    bool isEco = t['eco_friendly'] == true || t['type'] != 'chemical';
    
    Color typeColor = Colors.redAccent;
    Color typeBg = Colors.redAccent.withOpacity(0.15);
    String typeLabel = 'Chemical';
    
    if (t['type'] == 'organic') {
      typeColor = _lime;
      typeBg = _lime.withOpacity(0.18);
      typeLabel = 'Organic';
    } else if (t['type'] == 'biological') {
      typeColor = Colors.lightBlue;
      typeBg = Colors.lightBlue.withOpacity(0.15);
      typeLabel = 'Biological';
    } else if (t['type'] == 'mechanical') {
      typeColor = Colors.grey;
      typeBg = Colors.grey.withOpacity(0.15);
      typeLabel = 'Mechanical';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEco ? _leaf.withOpacity(0.08) : Colors.redAccent.withOpacity(0.05),
        border: Border.all(color: isEco ? _lime.withOpacity(0.16) : Colors.redAccent.withOpacity(0.16)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(t['name'], style: TextStyle(color: _cream, fontSize: 14, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(50)),
                child: Text(typeLabel.toUpperCase(), style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.7)),
              )
            ],
          ),
           const SizedBox(height: 10),
           Text(t['description'], style: TextStyle(color: _cream.withOpacity(0.7), fontSize: 13, height: 1.5)),
           const SizedBox(height: 12),
           Wrap(
             spacing: 12,
             children: [
               if (t['timing'] != null) Text('🕐 ${t['timing']}', style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 11)),
               if (t['frequency'] != null) Text('🔁 ${t['frequency']}', style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 11)),
             ],
           )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: TextStyle(color: _cream.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.8)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.1))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String icon, String title, String desc) {
    return Container(
      height: 300,
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: _cream, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(desc, textAlign: TextAlign.center, style: TextStyle(color: _cream.withOpacity(0.5), fontSize: 14, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class BoxPainter extends CustomPainter {
  final List<List<double>> predictions;
  final double scaleX;
  final double scaleY;
  final List<String> classNames;

  BoxPainter(this.predictions, this.scaleX, this.scaleY, this.classNames);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const imgWidth = 640;
    const imgHeight = 640;

    for (var pred in predictions) {
      final x = pred[0] * imgWidth * scaleX;
      final y = pred[1] * imgHeight * scaleY;
      final w = pred[2] * imgWidth * scaleX;
      final h = pred[3] * imgHeight * scaleY;
      final conf = pred[4];
      
      int classIndex = -1;
      if (pred.length > 5) {
        classIndex = pred[5].toInt();
      }
      
      String label = 'Pest';
      if (classIndex >= 0 && classIndex < classNames.length) {
        label = classNames[classIndex];
      }

      final rect = Rect.fromLTWH(x - w / 2, y - h / 2, w, h);
      canvas.drawRect(rect, paint);

      final textSpan = TextSpan(
        text: '$label ${(conf * 100).toStringAsFixed(0)}%',
        style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
      );
      textPainter.text = textSpan;
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 16));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// MOCK DATABASE FOR CASHEW PESTS
const Map<String, dynamic> _pestDatabase = {
  'Thrips': {
    'scientific_name': 'Scirtothrips dorsalis',
    'severity': 'medium',
    'description': 'Minute insects that scrape and suck sap from leaves and floral parts, leading to stunted shoots and scarred nuts.',
    'symptoms': [
      'Scab marks on the surface of cashew nuts',
      'Corky, brownish discoloration on apples',
      'Leaves becoming pale and curled'
    ],
    'treatments': [
      {
        'name': 'Neem formulation',
        'type': 'organic',
        'eco_friendly': true,
        'description': 'Spray NSKE (Neem Seed Kernel Extract) 5% during flowering.',
        'timing': 'Flowering/Fruiting stage'
      },
      {
        'name': 'Profenofos',
        'type': 'chemical',
        'eco_friendly': false,
        'description': 'Spray Profenofos 50 EC (1 ml/litre) if severe.',
        'timing': 'When scabs become highly visible'
      }
    ],
    'prevention': [
      {
         'measure': 'Monitor Flushing',
         'description': 'Frequent scouting of flushing to catch the population build-up early.'
      }
    ]
  },
  'mites': {
    'scientific_name': 'Tetranychidae',
    'severity': 'medium',
    'description': 'Spider mites that feed on plant sap, commonly found on the underside of cashew leaves causing speckling and webbing.',
    'symptoms': [
      'Tiny yellowish or white speckles on leaves',
      'Fine webbing on the underside of leaves',
      'Bronze or silvery appearance of damaged leaves',
      'Leaf dropping in severe cases'
    ],
    'treatments': [
       {
        'name': 'Predatory Mites',
        'type': 'biological',
        'eco_friendly': true,
        'description': 'Release Phytoseiulus persimilis or other predatory mites.',
        'timing': 'Early signs of damage'
      },
      {
        'name': 'Wettable Sulphur',
        'type': 'chemical',
        'eco_friendly': false,
        'description': 'Spray wettable sulphur (3g/litre).',
        'timing': 'During dry spells when mite populations peak',
        'frequency': 'Every 10-15 days'
      }
    ],
    'prevention': [
       {
         'measure': 'Adequate Irrigation',
         'description': 'Water stress combined with warm weather encourages mite outbreaks.'
       }
    ]
  },
  'stem_borer': {
    'scientific_name': 'Plocaederus ferrugineus',
    'severity': 'high',
    'description': 'A lethal pest causing the death of the entire cashew tree. The grubs bore into the bark and sapwood of the main stem and roots.',
    'symptoms': [
      'Yellowing of leaves followed by drying of twigs',
      'Presence of small holes in the collar region',
      'Extrusion of frass (powdery material) mixed with gum',
      'Yellowing and shedding of leaves leading to death'
    ],
    'treatments': [
      {
        'name': 'Mechanical Extraction',
        'type': 'mechanical',
        'eco_friendly': true,
        'description': 'Chisel out the bark of the tunneled portion and mechanically kill the grub.',
        'timing': 'Early stages of infestation'
      },
      {
        'name': 'Chlorpyriphos Swabbing',
        'type': 'chemical',
        'eco_friendly': false,
        'description': 'Swab the main stem up to 1 meter height and exposed roots with Chlorpyriphos 20 EC (10ml/litre).',
        'timing': 'After mechanical extraction',
        'frequency': 'Once/Twice a year'
      }
    ],
    'prevention': [
      {
        'measure': 'Phyto-sanitation',
        'description': 'Remove and burn dead and severely infested trees to prevent the spread to adjacent trees.',
        'frequency': 'Immediate'
      }
    ],
    'additional_info': 'Check the collar region of trees frequently during summer months when adult beetles emerge and lay eggs.'
  }
};
