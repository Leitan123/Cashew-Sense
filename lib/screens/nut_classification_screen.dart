import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/yolo_service.dart';

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
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  String _gradeFromWeight(double weight) {
    if (weight >= 8.0) {
      return "Grade_A";
    } else if (weight >= 5.0) {
      return "Grade_B";
    } else {
      return "Grade_C";
    }
  }

  Future<void> _submit() async {
    if (_selectedImage == null || _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select image and enter weight')),
      );
      return;
    }

    if (!_modelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model is not loaded yet')),
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
    
    // Process top model prediction
    String currentModelGrade = "No Detection";
    if (results.isNotEmpty) {
      // Results are sorted by confidence, get the first one
      final bestDetection = results[0];
      int clsId = bestDetection[5].toInt();
      
      if (clsId >= 0 && clsId < _yoloService.classNames.length) {
          currentModelGrade = _yoloService.classNames[clsId];
      } else {
          currentModelGrade = "Class \$clsId";
      }
    }
    
    // Process weight grade
    String currentWeightGrade = _gradeFromWeight(weight);
    
    // Final decision logic
    String finalDecision = "";
    String finalGradeOutcome = "";
    
    if (currentModelGrade == currentWeightGrade) {
        finalGradeOutcome = currentModelGrade;
        finalDecision = "Model and weight agree";
    } else {
        finalGradeOutcome = currentWeightGrade;
        finalDecision = "Weight-based correction applied";
    }

    setState(() {
      _predictions = results;
      _modelGrade = currentModelGrade;
      _weightGrade = currentWeightGrade;
      _finalGrade = finalGradeOutcome;
      _decision = finalDecision;
      _loading = false;
    });

    debugPrint("Image: \${_selectedImage!.path}");
    debugPrint("Weight: \$weight g");
    debugPrint("Found \${results.length} objects.");
    debugPrint("Model Grade: \$currentModelGrade, Weight Grade: \$currentWeightGrade");
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Cashew Nut Classification'),
        backgroundColor: const Color(0xFF2E3A20),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// Image preview
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _selectedImage == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, size: 48),
                            SizedBox(height: 8),
                            Text('Tap to select image'),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.fill,
                                width: double.infinity,
                              ),
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

            if (_finalGrade.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('🧠 Model Prediction: $_modelGrade', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('⚖️ Weight-Based Grade: $_weightGrade', style: const TextStyle(fontSize: 16)),
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Final Grade: $_finalGrade',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _decision,
                              style: const TextStyle(fontSize: 14, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            /// Weight input
            TextField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Weight (g)',
                hintText: 'e.g. 12.75',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Submit button
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3A20),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Classify Nut',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
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
      ..color = Colors.green.withOpacity(0.8)
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

      int maxClassIndex = -1;
      double maxClassProb = 0;
      for (int i = 5; i < pred.length; i++) {
        if (pred[i] > maxClassProb) {
          maxClassProb = pred[i];
          maxClassIndex = i - 5;
        }
      }

      String label = 'Cashew';
      if (maxClassIndex >= 0 && maxClassIndex < 3) { // Use service class mapping if possible
        label = ["Grade_A", "Grade_B", "Grade_C"][maxClassIndex];
      } else {
        label = 'Class $maxClassIndex';
      }
      
      final rect = Rect.fromLTWH(x - w / 2, y - h / 2, w, h);
      canvas.drawRect(rect, paint);

      final textSpan = TextSpan(
        text: '$label ${(conf * 100).toStringAsFixed(0)}%',
        style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
      );
      textPainter.text = textSpan;
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
