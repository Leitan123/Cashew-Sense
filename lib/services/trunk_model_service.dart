// File: lib/services/trunk_model_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TrunkModelService {
  Interpreter? _interpreter;

  static const List<String> labels = [
    'Very Small',
    'Small',
    'Medium',
    'Large',
  ];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/trunk_classifier.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      print('✅ Trunk model loaded');
    } catch (e) {
      print('❌ Trunk model load error: $e');
      rethrow;
    }
  }

  /// Predict trunk size from image file
  /// Returns index: 0=very_small, 1=small, 2=medium, 3=large
  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (_interpreter == null) throw Exception('Model not loaded');

    // Read and decode image
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('Could not decode image');

    // Resize to 224x224
    img.Image resized = img.copyResize(image, width: 224, height: 224);

    // Convert to float32 input [1, 224, 224, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    // Output [1, 4]
    final output = List.generate(1, (_) => List.filled(4, 0.0));

    _interpreter!.run(input, output);

    final scores = output[0];
    int maxIndex = 0;
    double maxScore = scores[0];
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }

    return {
      'classIndex': maxIndex,
      'label': labels[maxIndex],
      'confidence': (maxScore * 100).toStringAsFixed(1),
      'scores': scores,
    };
  }

  void close() {
    _interpreter?.close();
  }
}