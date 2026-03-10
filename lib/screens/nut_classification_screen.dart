// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../services/yolo_service.dart';
// import '../widgets/common_widgets.dart';
// import '../services/localization_service.dart';

// const _charcoal = Color(0xFF1e2820);
// const _moss     = Color(0xFF3d5a2e);
// const _leaf     = Color(0xFF5c8a3c);
// const _lime     = Color(0xFFa8c96e);
// const _cream    = Color(0xFFf5f0e8);

// class NutClassificationScreen extends StatefulWidget {
//   const NutClassificationScreen({super.key});

//   @override
//   State<NutClassificationScreen> createState() =>
//       _NutClassificationScreenState();
// }

// class _NutClassificationScreenState extends State<NutClassificationScreen> {
//   File? _selectedImage;
//   final ImagePicker _picker = ImagePicker();
//   final TextEditingController _weightController = TextEditingController();

//   final YoloService _yoloService = YoloService();
//   List<List<double>> _predictions = [];
//   bool _loading = false;
//   bool _modelLoaded = false;

//   String _modelGrade = "";
//   String _weightGrade = "";
//   String _finalGrade = "";
//   String _decision = "";

//   @override
//   void initState() {
//     super.initState();
//     _loadModel();
//   }

//   Future<void> _loadModel() async {
//     setState(() => _loading = true);
//     await _yoloService.loadModel();
//     setState(() {
//       _modelLoaded = true;
//       _loading = false;
//     });
//   }

//   Future<void> _pickImage() async {
//     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//     if (image != null) {
//       setState(() {
//         _selectedImage = File(image.path);
//       });
//     }
//   }

//   String _gradeFromWeight(double weight) {
//     if (weight >= 8.0) return "Grade_A";
//     if (weight >= 5.0) return "Grade_B";
//     return "Grade_C";
//   }

//   Future<void> _submit() async {
//     if (_selectedImage == null || _weightController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please select image and enter weight'.tr(context))),
//       );
//       return;
//     }
//     if (!_modelLoaded) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Model is not loaded yet'.tr(context))),
//       );
//       return;
//     }

//     final double weight = double.parse(_weightController.text);

//     setState(() {
//       _loading = true;
//       _predictions = [];
//       _modelGrade = "";
//       _weightGrade = "";
//       _finalGrade = "";
//       _decision = "";
//     });

//     final results = await _yoloService.predict(_selectedImage!);

//     String currentModelGrade = "No Detection";
//     if (results.isNotEmpty) {
//       final bestDetection = results[0];
//       int clsId = bestDetection[5].toInt();
//       if (clsId >= 0 && clsId < _yoloService.classNames.length) {
//         currentModelGrade = _yoloService.classNames[clsId];
//       } else {
//         currentModelGrade = "Class $clsId";
//       }
//     }

//     String currentWeightGrade = _gradeFromWeight(weight);

//     String finalDecision = "";
//     String finalGradeOutcome = "";
//     if (currentModelGrade == currentWeightGrade) {
//       finalGradeOutcome = currentModelGrade;
//       finalDecision = "Model and weight agree".tr(context);
//     } else {
//       finalGradeOutcome = currentWeightGrade;
//       finalDecision = "Weight-based correction applied".tr(context);
//     }

//     setState(() {
//       _predictions = results;
//       _modelGrade = currentModelGrade;
//       _weightGrade = currentWeightGrade;
//       _finalGrade = finalGradeOutcome;
//       _decision = finalDecision;
//       _loading = false;
//     });

//     debugPrint("Image: ${_selectedImage!.path}");
//     debugPrint("Weight: $weight g");
//     debugPrint("Found ${results.length} objects.");
//     debugPrint("Model Grade: $currentModelGrade, Weight Grade: $currentWeightGrade");
//   }

//   @override
//   void dispose() {
//     _weightController.dispose();
//     super.dispose();
//   }

//   Color get _gradeColor {
//     if (_finalGrade.contains('A')) return _lime;
//     if (_finalGrade.contains('B')) return Colors.orangeAccent;
//     return Colors.redAccent;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _charcoal,
//       appBar: buildCashewAppBar(title: 'Nut Classification'.tr(context)),
//       body: Stack(
//         children: [
//           // Background glow
//           Positioned(
//             top: -40, right: -40,
//             child: Container(
//               width: 200, height: 200,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: _leaf.withOpacity(0.10),
//               ),
//             ),
//           ),
//           SafeArea(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // ── Header Card ──────────────────────────────────────────
//                   Container(
//                     padding: const EdgeInsets.all(22),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [_moss, _leaf],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                             color: Colors.black.withOpacity(0.3),
//                             blurRadius: 16,
//                             offset: const Offset(0, 6)),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.15),
//                             borderRadius: BorderRadius.circular(50),
//                             border: Border.all(color: Colors.white.withOpacity(0.2)),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(Icons.circle, size: 7, color: _lime),
//                               const SizedBox(width: 5),
//                               Text('AI POWERED'.tr(context),
//                                   style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         RichText(
//                           text: TextSpan(
//                             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
//                             children: [
//                               TextSpan(text: 'Cashew Nut\n'.tr(context)),
//                               TextSpan(text: 'Classification'.tr(context), style: TextStyle(color: _lime)),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Upload a nut image and enter its weight for grade prediction.'.tr(context),
//                           style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.5),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // ── Image Picker ─────────────────────────────────────────
//                   Text('UPLOAD IMAGE'.tr(context),
//                       style: TextStyle(color: _cream.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
//                   const SizedBox(height: 12),

//                   GestureDetector(
//                     onTap: _pickImage,
//                     child: Container(
//                       height: 230,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF1e2820),
//                         borderRadius: BorderRadius.circular(18),
//                         border: Border.all(color: _lime.withOpacity(0.3), width: 1.5),
//                       ),
//                       child: _selectedImage == null
//                           ? Center(
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Container(
//                                     width: 54,
//                                     height: 54,
//                                     decoration: BoxDecoration(
//                                       gradient: LinearGradient(colors: [_moss, _leaf]),
//                                       shape: BoxShape.circle,
//                                       boxShadow: [BoxShadow(color: _leaf.withOpacity(0.3), blurRadius: 16)],
//                                     ),
//                                     child: const Icon(Icons.eco, color: Colors.white, size: 28),
//                                   ),
//                                   const SizedBox(height: 14),
//                                   Text('Tap to select image'.tr(context), style: TextStyle(color: _cream, fontSize: 15, fontWeight: FontWeight.w500)),
//                                   const SizedBox(height: 4),
//                                   Text('from your gallery'.tr(context), style: TextStyle(color: _cream.withOpacity(0.35), fontSize: 13)),
//                                 ],
//                               ),
//                             )
//                           : Stack(
//                               children: [
//                                 Positioned.fill(
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(18),
//                                     child: Image.file(_selectedImage!, fit: BoxFit.cover),
//                                   ),
//                                 ),
//                                 if (_predictions.isNotEmpty)
//                                   Positioned.fill(
//                                     child: LayoutBuilder(
//                                       builder: (context, constraints) {
//                                         final scaleX = constraints.maxWidth / 640;
//                                         final scaleY = constraints.maxHeight / 640;
//                                         return CustomPaint(
//                                           painter: NutBoxPainter(_predictions, scaleX, scaleY),
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                 if (_loading)
//                                   const Center(child: CircularProgressIndicator()),
//                               ],
//                             ),
//                     ),
//                   ),

//                   // ── Results Card ─────────────────────────────────────────
//                   if (_finalGrade.isNotEmpty) ...[
//                     const SizedBox(height: 24),
//                     Text('RESULTS'.tr(context),
//                         style: TextStyle(color: _cream.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
//                     const SizedBox(height: 12),
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF243020),
//                         border: Border.all(color: _lime.withOpacity(0.2)),
//                         borderRadius: BorderRadius.circular(18),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           _buildResultRow(Icons.psychology_outlined, 'Model Prediction'.tr(context), _modelGrade, _lime),
//                           const Divider(height: 20, color: Color(0x1Af5f0e8)),
//                           _buildResultRow(Icons.scale_outlined, 'Weight-Based Grade'.tr(context), _weightGrade, Colors.lightBlueAccent),
//                           const Divider(height: 20, color: Color(0x1Af5f0e8)),
//                           // Final grade badge
//                           Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(10),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(colors: [_moss, _leaf]),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: const Icon(Icons.verified_outlined, color: Colors.white, size: 22),
//                               ),
//                               const SizedBox(width: 14),
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text('FINAL GRADE'.tr(context),
//                                       style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
//                                   const SizedBox(height: 2),
//                                   Text(_finalGrade,
//                                       style: TextStyle(color: _gradeColor, fontSize: 22, fontWeight: FontWeight.bold)),
//                                 ],
//                               ),
//                               const Spacer(),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                                 decoration: BoxDecoration(
//                                   color: _leaf.withOpacity(0.15),
//                                   borderRadius: BorderRadius.circular(50),
//                                   border: Border.all(color: _lime.withOpacity(0.3)),
//                                 ),
//                                 child: Text(
//                                   _decision,
//                                   style: TextStyle(color: _lime, fontSize: 10, fontWeight: FontWeight.bold),
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],

//                   const SizedBox(height: 24),

//                   // ── Weight Input ─────────────────────────────────────────
//                   Text('WEIGHT INPUT'.tr(context),
//                       style: TextStyle(color: _cream.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
//                   const SizedBox(height: 12),
//                   TextField(
//                     controller: _weightController,
//                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                     style: TextStyle(color: _cream),
//                     decoration: InputDecoration(
//                       labelText: 'Weight (g)'.tr(context),
//                       hintText: 'e.g. 12.75'.tr(context),
//                       prefixIcon: const Icon(Icons.scale, color: _lime, size: 20),
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   // ── Submit Button ────────────────────────────────────────
//                   Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(colors: [_moss, _leaf]),
//                       borderRadius: BorderRadius.circular(14),
//                       boxShadow: [
//                         BoxShadow(color: _leaf.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4)),
//                       ],
//                     ),
//                     child: ElevatedButton.icon(
//                       onPressed: _loading ? null : _submit,
//                       icon: _loading
//                           ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
//                           : const Icon(Icons.auto_awesome, color: Colors.white),
//                       label: Text(
//                         _loading ? 'Classifying...'.tr(context) : 'Classify Nut'.tr(context),
//                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.transparent,
//                         shadowColor: Colors.transparent,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResultRow(IconData icon, String label, String value, Color color) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.12),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: color, size: 18),
//         ),
//         const SizedBox(width: 14),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(label, style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
//             const SizedBox(height: 2),
//             Text(value, style: TextStyle(color: _cream, fontSize: 15, fontWeight: FontWeight.bold)),
//           ],
//         ),
//       ],
//     );
//   }
// }

// class NutBoxPainter extends CustomPainter {
//   final List<List<double>> predictions;
//   final double scaleX;
//   final double scaleY;

//   NutBoxPainter(this.predictions, this.scaleX, this.scaleY);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color(0xFFa8c96e).withOpacity(0.85)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.5;

//     final textPainter = TextPainter(textDirection: TextDirection.ltr);

//     const imgWidth = 640;
//     const imgHeight = 640;

//     for (var pred in predictions) {
//       final x = pred[0] * imgWidth * scaleX;
//       final y = pred[1] * imgHeight * scaleY;
//       final w = pred[2] * imgWidth * scaleX;
//       final h = pred[3] * imgHeight * scaleY;
//       final conf = pred[4];

//       int maxClassIndex = -1;
//       double maxClassProb = 0;
//       for (int i = 5; i < pred.length; i++) {
//         if (pred[i] > maxClassProb) {
//           maxClassProb = pred[i];
//           maxClassIndex = i - 5;
//         }
//       }

//       String label = 'Cashew';
//       if (maxClassIndex >= 0 && maxClassIndex < 3) {
//         label = ["Grade_A", "Grade_B", "Grade_C"][maxClassIndex];
//       } else {
//         label = 'Class $maxClassIndex';
//       }

//       final rect = Rect.fromLTWH(x - w / 2, y - h / 2, w, h);
//       canvas.drawRect(rect, paint);

//       final textSpan = TextSpan(
//         text: '$label ${(conf * 100).toStringAsFixed(0)}%',
//         style: const TextStyle(color: Color(0xFFa8c96e), fontSize: 13, fontWeight: FontWeight.bold),
//       );
//       textPainter.text = textSpan;
//       textPainter.layout();
//       textPainter.paint(canvas, Offset(rect.left, rect.top - 18));
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }




import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/yolo_service.dart';
import '../widgets/common_widgets.dart';
import '../services/localization_service.dart';

const _charcoal = Color(0xFF1e2820);
const _moss     = Color(0xFF3d5a2e);
const _leaf     = Color(0xFF5c8a3c);
const _lime     = Color(0xFFa8c96e);
const _cream    = Color(0xFFf5f0e8);

// ── Grade map ────────────────────────────────────────────────────────────────
const Map<String, String> _gradeMap = {
  "W-180 (White WHoles)":                      "A",
  "WW-180 (Extra White - Super White )":        "A",
  "W-210": "A", "WW-210": "A", "W-240": "A",
  "WW-240": "A", "WWW320": "A",
  "W-320": "B", "S-210": "B", "S-240": "B", "S-320": "B",
  "S 210 (Dull White - Like Yellow)":           "B",
  "A-320 (Off White)":                          "B",
  "A-240 (off White)":                          "A",
  "SSW (Scrotch Whrinkles Wholes)":             "B",
  "DW (Draught Whole)":                         "C",
  "OW (oily Wholes)":                           "C",
  "RW (Red Whole)":                             "C",
  "UW (Unpilled Photri Whole)":                 "C",
  "PKW (Partial Wholes Always Black Knots)":    "C",
  "KW (Knot Wholes) Single Knot Green":         "C",
  "KW-1 (Multiple Black Green Mix Knot Wholes)":"C",
};

const Map<String, double> _weightThresholds = {
  "W-180 (White WHoles)": 2.5,
  "WW-180 (Extra White - Super White )": 2.5,
  "W-210": 2.15, "WW-210": 2.15, "S-210": 2.15,
  "S 210 (Dull White - Like Yellow)": 2.15,
  "W-240": 1.9, "WW-240": 1.9, "S-240": 1.9,
  "A-240 (off White)": 1.9,
  "W-320": 1.4, "WWW320": 1.4, "S-320": 1.4,
  "A-320 (Off White)": 1.4,
};
const double _defaultWeight = 1.0;

const Map<String, Map<String, String>> _gradeInfo = {
  "A": {"label": "Grade A", "tag": "Premium",  "description": "Premium white whole cashews"},
  "B": {"label": "Grade B", "tag": "Standard", "description": "Standard / scorched / off-white cashews"},
  "C": {"label": "Grade C", "tag": "Economy",  "description": "Defect / special condition cashews"},
};

Map<String, dynamic> _computeGrade(String cls, double weightG) {
  final String orig     = _gradeMap[cls] ?? "C";
  String grade          = orig;
  final double expected = _weightThresholds[cls] ?? _defaultWeight;
  final bool   weightOk = weightG >= expected * 0.85;
  if (!weightOk) {
    if (grade == "A") grade = "B";
    else if (grade == "B") grade = "C";
  }
  final info = _gradeInfo[grade] ?? {};
  return {
    'finalGrade':        grade,
    'gradeLabel':        info['label']       ?? 'Grade $grade',
    'gradeTag':          info['tag']         ?? '',
    'gradeDescription':  info['description'] ?? '',
    'originalGrade':     orig,
    'downgraded':        orig != grade,
    'weightOk':          weightOk,
    'expectedMinWeight': expected,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Separate enum to track what the app is doing — no more _loading boolean mess
// ─────────────────────────────────────────────────────────────────────────────
enum _AppState {
  modelLoading,   // startup: loading tflite
  idle,           // ready, waiting for user
  classifying,    // user pressed button, inference running
  done,           // results ready
}

class NutClassificationScreen extends StatefulWidget {
  const NutClassificationScreen({super.key});
  @override
  State<NutClassificationScreen> createState() => _NutClassificationScreenState();
}

class _NutClassificationScreenState extends State<NutClassificationScreen> {
  File? _selectedImage;
  final ImagePicker _picker            = ImagePicker();
  final TextEditingController _weight  = TextEditingController();
  final YoloService _yolo              = YoloService();

  _AppState _appState = _AppState.modelLoading;

  List<NutDetection> _detections = [];

  // result fields
  String _predictedClass    = "";
  double _confidence        = 0.0;
  String _originalGrade     = "";
  String _finalGrade        = "";
  String _gradeLabel        = "";
  String _gradeTag          = "";
  String _gradeDescription  = "";
  bool   _weightOk          = true;
  bool   _downgraded        = false;
  double _expectedMinWeight = 0.0;

  // ── init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadModel();          // only thing that runs on start
  }

  // Loads model in background, then goes idle — does NOT touch results
  Future<void> _loadModel() async {
    try {
      await _yolo.loadModel();
    } catch (e) {
      debugPrint("Model load error: $e");
    }
    if (mounted) setState(() => _appState = _AppState.idle);
  }

  // ── Image picker ──────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    // Block while classifying
    if (_appState == _AppState.classifying) return;

    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    // Just store the image — DO NOT run classify
    setState(() {
      _selectedImage = File(picked.path);
      _appState      = _AppState.idle;   // reset to idle, clear old results
      _clearResults();
    });
  }

  // ── Only called when button is EXPLICITLY pressed ─────────────────────────
  Future<void> _onClassifyPressed() async {
    // Guard — button should already be disabled in these states, but double-check
    if (_appState != _AppState.idle && _appState != _AppState.done) return;
    if (_selectedImage == null) {
      _showSnack('Please select an image first');
      return;
    }
    if (_weight.text.trim().isEmpty) {
      _showSnack('Please enter the nut weight');
      return;
    }
    double weightG;
    try {
      weightG = double.parse(_weight.text.trim());
    } catch (_) {
      _showSnack('Invalid weight — enter a number like 1.85');
      return;
    }

    // ── Start classifying ─────────────────────────────────────────────────
    setState(() {
      _appState = _AppState.classifying;
      _clearResults();
    });

    try {
      final detections = await _yolo.predict(_selectedImage!);

      String cls   = "No Detection";
      double conf  = 0.0;

      if (detections.isNotEmpty) {
        final best = detections.reduce(
          (a, b) => a.confidence >= b.confidence ? a : b,
        );
        conf = best.confidence;
        final id = best.classId;
        cls  = (id >= 0 && id < _yolo.classNames.length)
            ? _yolo.classNames[id]
            : 'Class $id';
      }

      // ── Non-cashew detection guard ─────────────────────────────────────
      // If no nut was detected, or confidence is too low, treat as
      // "not a cashew nut" and show a user-friendly message.
      const double kMinCashewConfidence = 0.35;
      if (detections.isEmpty || conf < kMinCashewConfidence) {
        if (mounted) {
          setState(() => _appState = _AppState.idle);
          _showNotCashewDialog();
        }
        return;
      }

      final grade = _computeGrade(cls, weightG);

      if (mounted) {
        setState(() {
          _detections        = detections;
          _predictedClass    = cls;
          _confidence        = conf;
          _originalGrade     = grade['originalGrade'];
          _finalGrade        = grade['finalGrade'];
          _gradeLabel        = grade['gradeLabel'];
          _gradeTag          = grade['gradeTag'];
          _gradeDescription  = grade['gradeDescription'];
          _weightOk          = grade['weightOk'];
          _downgraded        = grade['downgraded'];
          _expectedMinWeight = grade['expectedMinWeight'];
          _appState          = _AppState.done;
        });
      }
    } catch (e) {
      debugPrint("Predict error: $e");
      if (mounted) {
        _showSnack('Classification failed: $e');
        setState(() => _appState = _AppState.idle);
      }
    }
  }

  void _clearResults() {
    _detections = []; _predictedClass = ""; _confidence = 0.0;
    _originalGrade = ""; _finalGrade = ""; _gradeLabel = "";
    _gradeTag = ""; _gradeDescription = ""; _weightOk = true;
    _downgraded = false; _expectedMinWeight = 0.0;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showNotCashewDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF243020),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.info_outline_rounded,
            color: Colors.orangeAccent, size: 48),
        title: Text('Not a Cashew Nut'.tr(context),
            style: const TextStyle(color: _cream, fontWeight: FontWeight.bold)),
        content: Text(
          'The uploaded image does not appear to be a cashew nut. Please upload a clear image of a cashew nut for grading.'.tr(context),
          textAlign: TextAlign.center,
          style: TextStyle(color: _cream.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'.tr(context),
                style: const TextStyle(color: _lime, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _weight.dispose(); super.dispose(); }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color get _gradeColor {
    if (_finalGrade == "A") return _lime;
    if (_finalGrade == "B") return Colors.orangeAccent;
    return Colors.redAccent;
  }

  bool get _canClassify =>
      _appState == _AppState.idle || _appState == _AppState.done;

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _charcoal,
      appBar: buildCashewAppBar(title: 'Nut Classification'.tr(context)),
      body: Stack(
        children: [
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _leaf.withOpacity(0.10),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 24),

                  // Model loading banner
                  if (_appState == _AppState.modelLoading)
                    _buildBanner(
                      Icons.hourglass_top_rounded,
                      'Loading AI model…',
                      _lime,
                    ),

                  _sectionLabel('UPLOAD IMAGE'.tr(context)),
                  const SizedBox(height: 12),
                  _buildImagePicker(),

                  if (_appState == _AppState.done) ...[
                    const SizedBox(height: 24),
                    _sectionLabel('RESULTS'.tr(context)),
                    const SizedBox(height: 12),
                    _buildResultsCard(),
                  ],

                  const SizedBox(height: 24),
                  _sectionLabel('WEIGHT INPUT'.tr(context)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: _cream),
                    decoration: InputDecoration(
                      labelText: 'Weight (g)'.tr(context),
                      hintText: 'e.g. 1.85'.tr(context),
                      prefixIcon: const Icon(Icons.scale, color: _lime, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildClassifyButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(color: _cream.withOpacity(0.3), fontSize: 11,
        fontWeight: FontWeight.bold, letterSpacing: 1.5),
  );

  Widget _buildBanner(IconData icon, String msg, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Text(msg, style: TextStyle(color: color, fontSize: 13)),
    ]),
  );

  Widget _buildHeaderCard() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [_moss, _leaf],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3),
          blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.circle, size: 7, color: _lime),
          const SizedBox(width: 5),
          Text('AI POWERED'.tr(context), style: const TextStyle(
              color: Colors.white, fontSize: 9,
              fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ]),
      ),
      const SizedBox(height: 12),
      RichText(text: TextSpan(
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
            color: Colors.white),
        children: [
          TextSpan(text: 'Cashew Nut\n'.tr(context)),
          TextSpan(text: 'Classification'.tr(context),
              style: const TextStyle(color: _lime)),
        ],
      )),
      const SizedBox(height: 8),
      Text('Upload a nut image and enter its weight for grade prediction.'.tr(context),
          style: TextStyle(color: Colors.white.withOpacity(0.65),
              fontSize: 13, height: 1.5)),
    ]),
  );

  Widget _buildImagePicker() => GestureDetector(
    onTap: _pickImage,    // ONLY picks image — never classifies
    child: Container(
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1e2820),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lime.withOpacity(0.3), width: 1.5),
      ),
      child: _selectedImage == null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_moss, _leaf]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _leaf.withOpacity(0.3), blurRadius: 16)],
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              Text('Tap to select image'.tr(context),
                  style: const TextStyle(color: _cream, fontSize: 15,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('from your gallery'.tr(context),
                  style: TextStyle(color: _cream.withOpacity(0.35), fontSize: 13)),
            ]))
          : Stack(children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
              // Mask overlay — only shown when done, not while classifying
              if (_appState == _AppState.done && _detections.isNotEmpty)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: LayoutBuilder(
                      builder: (ctx, constraints) => CustomPaint(
                        painter: NutMaskPainter(
                          detections:   _detections,
                          classNames:   _yolo.classNames,
                          canvasWidth:  constraints.maxWidth,
                          canvasHeight: constraints.maxHeight,
                        ),
                      ),
                    ),
                  ),
                ),
              // Classifying spinner — centred, only during inference
              if (_appState == _AppState.classifying)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: _lime),
                      const SizedBox(height: 12),
                      Text('Classifying…'.tr(context),
                          style: const TextStyle(color: _lime, fontSize: 13)),
                    ],
                  )),
                ),
            ]),
    ),
  );

  Widget _buildClassifyButton() {
    // Button is active only when model is ready AND we're not mid-inference
    final bool active = _canClassify &&
        _selectedImage != null &&
        _appState != _AppState.modelLoading;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: active ? [_moss, _leaf] : [Colors.grey.shade800, Colors.grey.shade700],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: active
            ? [BoxShadow(color: _leaf.withOpacity(0.35),
                blurRadius: 14, offset: const Offset(0, 4))]
            : [],
      ),
      child: ElevatedButton.icon(
        // onPressed is null while model is loading or classifying
        onPressed: active ? _onClassifyPressed : null,
        icon: _appState == _AppState.modelLoading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(
          _appState == _AppState.modelLoading
              ? 'Loading model…'.tr(context)
              : _appState == _AppState.classifying
                  ? 'Classifying…'.tr(context)
                  : 'Classify Nut'.tr(context),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildResultsCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF243020),
      border: Border.all(color: _lime.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildResultRow(Icons.document_scanner_outlined,
          'Detected Class'.tr(context), _predictedClass, _lime),
      const Divider(height: 20, color: Color(0x1Af5f0e8)),
      _buildResultRow(Icons.percent_outlined, 'Confidence'.tr(context),
          '${(_confidence * 100).toStringAsFixed(1)}%', Colors.lightBlueAccent),
      const Divider(height: 20, color: Color(0x1Af5f0e8)),
      _buildResultRow(Icons.psychology_outlined,
          'Vision Grade'.tr(context), 'Grade $_originalGrade', _lime),
      const Divider(height: 20, color: Color(0x1Af5f0e8)),
      _buildWeightCheckRow(),
      const Divider(height: 20, color: Color(0x1Af5f0e8)),
      _buildFinalGradeRow(),
      if (_downgraded) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.35)),
          ),
          child: Row(children: [
            const Icon(Icons.arrow_downward_rounded,
                color: Colors.orangeAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Downgraded Grade $_originalGrade → Grade $_finalGrade '
              '(min ${(_expectedMinWeight * 0.85).toStringAsFixed(2)} g required)',
              style: const TextStyle(color: Colors.orangeAccent,
                  fontSize: 11, height: 1.4),
            )),
          ]),
        ),
      ],
      const SizedBox(height: 12),
      Text(_gradeDescription,
          style: TextStyle(color: _cream.withOpacity(0.45),
              fontSize: 12, height: 1.4)),
    ]),
  );

  Widget _buildWeightCheckRow() {
    final color = _weightOk ? Colors.greenAccent : Colors.orangeAccent;
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(
          _weightOk ? Icons.check_circle_outline : Icons.warning_amber_outlined,
          color: color, size: 18),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Weight Check'.tr(context),
            style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(
          _weightOk
              ? 'OK  (≥ ${(_expectedMinWeight * 0.85).toStringAsFixed(2)} g)'
              : 'Below threshold  (min ${(_expectedMinWeight * 0.85).toStringAsFixed(2)} g)',
          style: TextStyle(color: _cream, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }

  Widget _buildFinalGradeRow() => Row(children: [
    Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_moss, _leaf]),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: const Icon(Icons.verified_outlined, color: Colors.white, size: 22),
    ),
    const SizedBox(width: 14),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FINAL GRADE'.tr(context),
          style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 10,
              fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      const SizedBox(height: 2),
      Text(_gradeLabel, style: TextStyle(color: _gradeColor,
          fontSize: 22, fontWeight: FontWeight.bold)),
    ]),
    const Spacer(),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _leaf.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _lime.withOpacity(0.3)),
      ),
      child: Text(_gradeTag,
          style: const TextStyle(color: _lime, fontSize: 10,
              fontWeight: FontWeight.bold)),
    ),
  ]);

  Widget _buildResultRow(IconData icon, String label, String value, Color color) =>
    Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 10,
            fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: _cream, fontSize: 14,
            fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis, maxLines: 2),
      ])),
    ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// NutMaskPainter
// ─────────────────────────────────────────────────────────────────────────────
class NutMaskPainter extends CustomPainter {
  final List<NutDetection> detections;
  final List<String>       classNames;
  final double canvasWidth;
  final double canvasHeight;

  const NutMaskPainter({
    required this.detections, required this.classNames,
    required this.canvasWidth, required this.canvasHeight,
  });

  static const Map<String, Color> _gradeColors = {
    "A": Color(0xFFa8c96e),
    "B": Colors.orangeAccent,
    "C": Colors.redAccent,
  };

  @override
  void paint(Canvas canvas, Size size) {
    for (final det in detections) {
      final String cls = (det.classId >= 0 && det.classId < classNames.length)
          ? classNames[det.classId] : 'Unknown';
      final String grade = _gradeMap[cls] ?? "C";
      final Color  base  = _gradeColors[grade] ?? const Color(0xFFa8c96e);

      if (det.mask != null) {
        _drawMask(canvas, size, det, base, grade);
      } else {
        _drawBox(canvas, size, det, base, grade);
      }
    }
  }

  void _drawMask(Canvas canvas, Size size, NutDetection det, Color base, String grade) {
    final mask = det.mask!;
    final double sx = size.width  / det.maskW;
    final double sy = size.height / det.maskH;

    final fillPath    = Path();
    final borderPath  = Path();

    for (int y = 0; y < det.maskH; y++) {
      int? start;
      for (int x = 0; x <= det.maskW; x++) {
        final bool on = x < det.maskW && mask[y][x];
        if (on && start == null) {
          start = x;
        } else if (!on && start != null) {
          fillPath.addRect(Rect.fromLTWH(
              start * sx, y * sy, (x - start) * sx, sy + 0.5));
          start = null;
        }
      }
    }

    for (int y = 0; y < det.maskH; y++) {
      for (int x = 0; x < det.maskW; x++) {
        if (!mask[y][x]) continue;
        final bool border =
            (x == 0 || !mask[y][x - 1]) || (x == det.maskW - 1 || !mask[y][x + 1]) ||
            (y == 0 || !mask[y - 1][x]) || (y == det.maskH - 1 || !mask[y + 1][x]);
        if (border) borderPath.addRect(
            Rect.fromLTWH(x * sx, y * sy, sx + 0.5, sy + 0.5));
      }
    }

    // Fill — 35% opacity (mirrors app.py addWeighted 0.35)
    canvas.drawPath(fillPath,   Paint()..color = base.withOpacity(0.35)..style = PaintingStyle.fill);
    // Outline — 85% opacity
    canvas.drawPath(borderPath, Paint()..color = base.withOpacity(0.85)..style = PaintingStyle.fill);
    // Ellipse — yellow, mirrors app.py fitEllipse
    _drawEllipse(canvas, size, mask, det.maskH, det.maskW, sx, sy);
    // Label
    _drawLabel(canvas,
        Offset(det.cx * size.width, (det.cy - det.h / 2) * size.height - 20),
        'Grade $grade  ${(det.confidence * 100).toStringAsFixed(0)}%', base);
  }

  void _drawEllipse(Canvas canvas, Size size, List<List<bool>> mask,
      int mH, int mW, double sx, double sy) {
    int x1 = mW, x2 = 0, y1 = mH, y2 = 0;
    for (int y = 0; y < mH; y++) {
      for (int x = 0; x < mW; x++) {
        if (!mask[y][x]) continue;
        if (x < x1) x1 = x; if (x > x2) x2 = x;
        if (y < y1) y1 = y; if (y > y2) y2 = y;
      }
    }
    if (x1 >= x2 || y1 >= y2) return;
    canvas.drawOval(
      Rect.fromLTRB(x1 * sx, y1 * sy, (x2 + 1) * sx, (y2 + 1) * sy),
      Paint()
        ..color = const Color(0xFFFFFF00).withOpacity(0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawBox(Canvas canvas, Size size, NutDetection det, Color base, String grade) {
    final rect = Rect.fromLTWH(
      (det.cx - det.w / 2) * size.width,
      (det.cy - det.h / 2) * size.height,
      det.w * size.width,
      det.h * size.height,
    );
    canvas.drawRect(rect, Paint()
      ..color = base.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
    _drawLabel(canvas, Offset(rect.left, rect.top - 20),
        'Grade $grade  ${(det.confidence * 100).toStringAsFixed(0)}%', base);
  }

  void _drawLabel(Canvas canvas, Offset pos, String text, Color color) {
    (TextPainter(textDirection: TextDirection.ltr)
          ..text = TextSpan(
            text: text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold,
                shadows: const [Shadow(blurRadius: 4, color: Colors.black)]),
          )
          ..layout())
        .paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant NutMaskPainter old) => old.detections != detections;
}