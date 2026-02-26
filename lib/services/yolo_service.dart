import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class YoloService {
  late Interpreter _interpreter;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/best_float32.tflite');
    _isLoaded = true;
    print("✅ YOLO TFLite model loaded");
  }

  Future<List<List<double>>> predict(File imageFile) async {
    if (!_isLoaded) {
      throw Exception("YOLO model not loaded");
    }

    // Decode and resize image
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return [];
    image = img.copyResize(image, width: 640, height: 640);

    // Input shape [1, 640, 640, 3]
    var input = List.generate(
      1,
      (_) => List.generate(
        640,
        (_) => List.generate(640, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final pixel = image.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    // ✅ Output shape must match model
    // Model output: [1, 7, 8400] (7 = [x, y, w, h, conf, class1, class2...])
    var output = List.generate(1, (_) => List.generate(7, (_) => List.filled(8400, 0.0)));

    // Run inference
    _interpreter.run(input, output);

    // Transpose output to [8400, 7] for easier processing
    List<List<double>> transposed = List.generate(8400, (_) => List.filled(7, 0.0));
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j < 8400; j++) {
        transposed[j][i] = output[0][i][j];
      }
    }

    // Filter by confidence
    List<List<double>> results = [];
    for (var pred in transposed) {
      if (pred[4] > 0.25) results.add(pred);
    }

    return results;
  }
}
