// ignore: duplicate_ignore
// ignore: unused_import
// ignore_for_file: unused_import

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class SoilModelService {
  Interpreter? _interpreter;

  /// Load model from assets
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/soil_health_model.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      print('✅ TFLite model loaded successfully');
    } catch (e) {
      print('❌ Error loading TFLite model: $e');
      rethrow;
    }
  }

  /// Run prediction
  double predict({
    required double f1,
    required double f2,
    required double f3,
    required double ph,
    required double f5,
    required double f6,
    required double f7,
  }) {
    if (_interpreter == null) {
      throw Exception('Interpreter not initialized');
    }

    // Input shape: [1, 7]
    final input = [
      [f1, f2, f3, ph, f5, f6, f7]
    ];

    // Output shape: [1, 1]
    final output = List.generate(1, (_) => List.filled(1, 0.0));

    _interpreter!.run(input, output);

    return output[0][0];
  }

  /// Free resources
  void close() {
    _interpreter?.close();
  }
}
