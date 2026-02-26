import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/yolo_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pest Detection')),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _imageFile == null
                  ? const Text('No image selected')
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (_predictions.isNotEmpty)
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final scaleX = constraints.maxWidth / 640;
                                final scaleY = constraints.maxHeight / 640;
                                return CustomPaint(
                                  painter: BoxPainter(_predictions, scaleX, scaleY),
                                );
                              },
                            ),
                          ),
                        if (_loading)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoxPainter extends CustomPainter {
  final List<List<double>> predictions;
  final double scaleX;
  final double scaleY;

  BoxPainter(this.predictions, this.scaleX, this.scaleY);

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
      // YOLOv8 outputs normalized coordinates (0-1)
      final x = pred[0] * imgWidth * scaleX;
      final y = pred[1] * imgHeight * scaleY;
      final w = pred[2] * imgWidth * scaleX;
      final h = pred[3] * imgHeight * scaleY;
      final conf = pred[4];

      final rect = Rect.fromLTWH(x - w / 2, y - h / 2, w, h);
      canvas.drawRect(rect, paint);

      // Draw confidence text above box
      final textSpan = TextSpan(
        text: 'Pest ${(conf * 100).toStringAsFixed(0)}%',
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
