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

class NutClassificationScreen extends StatefulWidget {
  const NutClassificationScreen({super.key});

  @override
  State<NutClassificationScreen> createState() =>
      _NutClassificationScreenState();
}

class _NutClassificationScreenState extends State<NutClassificationScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _weightController = TextEditingController();

  final YoloService _yoloService = YoloService();
  List<List<double>> _predictions = [];
  bool _loading = false;
  bool _modelLoaded = false;

  String _modelGrade = "";
  String _weightGrade = "";
  String _finalGrade = "";
  String _decision = "";

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() => _loading = true);
    await _yoloService.loadModel();
    setState(() {
      _modelLoaded = true;
      _loading = false;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  String _gradeFromWeight(double weight) {
    if (weight >= 8.0) return "Grade_A";
    if (weight >= 5.0) return "Grade_B";
    return "Grade_C";
  }

  Future<void> _submit() async {
    if (_selectedImage == null || _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select image and enter weight'.tr(context))),
      );
      return;
    }
    if (!_modelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model is not loaded yet'.tr(context))),
      );
      return;
    }

    final double weight = double.parse(_weightController.text);

    setState(() {
      _loading = true;
      _predictions = [];
      _modelGrade = "";
      _weightGrade = "";
      _finalGrade = "";
      _decision = "";
    });

    final results = await _yoloService.predict(_selectedImage!);

    String currentModelGrade = "No Detection";
    if (results.isNotEmpty) {
      final bestDetection = results[0];
      int clsId = bestDetection[5].toInt();
      if (clsId >= 0 && clsId < _yoloService.classNames.length) {
        currentModelGrade = _yoloService.classNames[clsId];
      } else {
        currentModelGrade = "Class $clsId";
      }
    }

    String currentWeightGrade = _gradeFromWeight(weight);

    String finalDecision = "";
    String finalGradeOutcome = "";
    if (currentModelGrade == currentWeightGrade) {
      finalGradeOutcome = currentModelGrade;
      finalDecision = "Model and weight agree".tr(context);
    } else {
      finalGradeOutcome = currentWeightGrade;
      finalDecision = "Weight-based correction applied".tr(context);
    }

    setState(() {
      _predictions = results;
      _modelGrade = currentModelGrade;
      _weightGrade = currentWeightGrade;
      _finalGrade = finalGradeOutcome;
      _decision = finalDecision;
      _loading = false;
    });

    debugPrint("Image: ${_selectedImage!.path}");
    debugPrint("Weight: $weight g");
    debugPrint("Found ${results.length} objects.");
    debugPrint("Model Grade: $currentModelGrade, Weight Grade: $currentWeightGrade");
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Color get _gradeColor {
    if (_finalGrade.contains('A')) return _lime;
    if (_finalGrade.contains('B')) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _charcoal,
      appBar: buildCashewAppBar(title: 'Nut Classification'.tr(context)),
      body: Stack(
        children: [
          // Background glow
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
                  // ── Header Card ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(22),
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
                            blurRadius: 16,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
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
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            children: [
                              const TextSpan(text: 'Cashew Nut\n'),
                              TextSpan(text: 'Classification', style: TextStyle(color: _lime)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload a nut image and enter its weight for grade prediction.',
                          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Image Picker ─────────────────────────────────────────
                  Text('UPLOAD IMAGE',
                      style: TextStyle(color: _cream.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 230,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1e2820),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _lime.withOpacity(0.3), width: 1.5),
                      ),
                      child: _selectedImage == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [_moss, _leaf]),
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: _leaf.withOpacity(0.3), blurRadius: 16)],
                                    ),
                                    child: const Icon(Icons.eco, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(height: 14),
                                  Text('Tap to select image', style: TextStyle(color: _cream, fontSize: 15, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text('from your gallery', style: TextStyle(color: _cream.withOpacity(0.35), fontSize: 13)),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                  ),
                                ),
                                if (_predictions.isNotEmpty)
                                  Positioned.fill(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final scaleX = constraints.maxWidth / 640;
                                        final scaleY = constraints.maxHeight / 640;
                                        return CustomPaint(
                                          painter: NutBoxPainter(_predictions, scaleX, scaleY),
                                        );
                                      },
                                    ),
                                  ),
                                if (_loading)
                                  const Center(child: CircularProgressIndicator()),
                              ],
                            ),
                    ),
                  ),

                  // ── Results Card ─────────────────────────────────────────
                  if (_finalGrade.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('RESULTS',
                        style: TextStyle(color: _cream.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF243020),
                        border: Border.all(color: _lime.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildResultRow(Icons.psychology_outlined, 'Model Prediction', _modelGrade, _lime),
                          const Divider(height: 20, color: Color(0x1Af5f0e8)),
                          _buildResultRow(Icons.scale_outlined, 'Weight-Based Grade', _weightGrade, Colors.lightBlueAccent),
                          const Divider(height: 20, color: Color(0x1Af5f0e8)),
                          // Final grade badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [_moss, _leaf]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.verified_outlined, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('FINAL GRADE',
                                      style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                  const SizedBox(height: 2),
                                  Text(_finalGrade,
                                      style: TextStyle(color: _gradeColor, fontSize: 22, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _leaf.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: _lime.withOpacity(0.3)),
                                ),
                                child: Text(
                                  _decision,
                                  style: TextStyle(color: _lime, fontSize: 10, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Weight Input ─────────────────────────────────────────
                  Text('WEIGHT INPUT',
                      style: TextStyle(color: _cream.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: _cream),
                    decoration: const InputDecoration(
                      labelText: 'Weight (g)',
                      hintText: 'e.g. 12.75',
                      prefixIcon: Icon(Icons.scale, color: _lime, size: 20),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Submit Button ────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_moss, _leaf]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: _leaf.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome, color: Colors.white),
                      label: Text(
                        _loading ? 'Classifying...' : 'Classify Nut',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: _cream, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class NutBoxPainter extends CustomPainter {
  final List<List<double>> predictions;
  final double scaleX;
  final double scaleY;

  NutBoxPainter(this.predictions, this.scaleX, this.scaleY);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFa8c96e).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const imgWidth = 640;
    const imgHeight = 640;

    for (var pred in predictions) {
      final x = pred[0] * imgWidth * scaleX;
      final y = pred[1] * imgHeight * scaleY;
      final w = pred[2] * imgWidth * scaleX;
      final h = pred[3] * imgHeight * scaleY;
      final conf = pred[4];

      int maxClassIndex = -1;
      double maxClassProb = 0;
      for (int i = 5; i < pred.length; i++) {
        if (pred[i] > maxClassProb) {
          maxClassProb = pred[i];
          maxClassIndex = i - 5;
        }
      }

      String label = 'Cashew';
      if (maxClassIndex >= 0 && maxClassIndex < 3) {
        label = ["Grade_A", "Grade_B", "Grade_C"][maxClassIndex];
      } else {
        label = 'Class $maxClassIndex';
      }

      final rect = Rect.fromLTWH(x - w / 2, y - h / 2, w, h);
      canvas.drawRect(rect, paint);

      final textSpan = TextSpan(
        text: '$label ${(conf * 100).toStringAsFixed(0)}%',
        style: const TextStyle(color: Color(0xFFa8c96e), fontSize: 13, fontWeight: FontWeight.bold),
      );
      textPainter.text = textSpan;
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
