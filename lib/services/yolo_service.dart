import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class YoloService {
  late Interpreter _interpreter;
  bool _isLoaded = false;
  
  // Assuming classes map to 0: Grade_A, 1: Grade_B, 2: Grade_C based on typical grading models.
  final List<String> classNames = ["Grade_A", "Grade_B", "Grade_C"];

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/best_float_new.tflite');
    _isLoaded = true;
    print("✅ YOLO TFLite model loaded");
  }

  Future<List<List<double>>> predict(File imageFile) async {
    if (!_isLoaded) {
      throw Exception("YOLO model not loaded");
    }

    // Get expected input shape
    final inputShape = _interpreter.getInputTensor(0).shape; // e.g. [1, imgSize, imgSize, 3]
    int imgHeight = inputShape[1];
    int imgWidth = inputShape[2];

    // Decode and resize image
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return [];
    image = img.copyResize(image, width: imgWidth, height: imgHeight);

    // Input shape [1, imgHeight, imgWidth, 3]
    var input = List.generate(
      1,
      (_) => List.generate(
        imgHeight,
        (_) => List.generate(imgWidth, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < imgHeight; y++) {
      for (int x = 0; x < imgWidth; x++) {
        final pixel = image.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    final outputTensors = _interpreter.getOutputTensors();
    final outputShape = outputTensors[0].shape; // e.g. [1, 7, 8400] or [1, 8400, 7]
    
    // Check if the shape is [1, num_channels, num_boxes] (YOLOv8 standard)
    int numChannels = outputShape[1];
    int numBoxes = outputShape[2];
    
    // Model output: [1, numChannels, numBoxes]
    var output = List.generate(1, (_) => List.generate(numChannels, (_) => List.filled(numBoxes, 0.0)));

    // Run inference
    _interpreter.run(input, output);

    // Transpose output to [numBoxes, numChannels] 
    List<List<double>> transposed = List.generate(numBoxes, (_) => List.filled(numChannels, 0.0));
    for (int i = 0; i < numChannels; i++) {
        for (int j = 0; j < numBoxes; j++) {
            transposed[j][i] = output[0][i][j];
        }
    }
    
    // Process results (NMS implementation)
    List<List<double>> results = [];
    
    // In standard YOLOv8, channels 4 onwards are class probabilities 
    // Usually no separate objectness score.
    for (var pred in transposed) {
      double maxClassProb = 0.0;
      int maxClassIndex = -1;
      
      // Calculate max probability
      for (int i = 4; i < numChannels; i++) {
          if (pred[i] > maxClassProb) {
              maxClassProb = pred[i];
              maxClassIndex = i - 4; // Assuming 0-indexed classes
          }
      }

      // Confidence threshold (adjustable)
      if (maxClassProb > 0.25) {
          // Add [x, y, w, h, classProb, classIndex]
          results.add([pred[0], pred[1], pred[2], pred[3], maxClassProb, maxClassIndex.toDouble()]);
      }
    }

    // Apply Non-Maximum Suppression (NMS)
    List<List<double>> nmsResults = _applyNMS(results, 0.45);

    return nmsResults;
  }

  // Very basic NMS implementation
  List<List<double>> _applyNMS(List<List<double>> boxes, double iouThreshold) {
      if (boxes.isEmpty) return [];

      // Sort by confidence (index 4)
      boxes.sort((a, b) => b[4].compareTo(a[4]));

      List<List<double>> selected = [];
      List<bool> active = List.filled(boxes.length, true);

      for (int i = 0; i < boxes.length; i++) {
          if (!active[i]) continue;
          
          final boxA = boxes[i];
          selected.add(boxA);

          for (int j = i + 1; j < boxes.length; j++) {
              if (!active[j]) continue;
              
              final boxB = boxes[j];
              
              // Only compare boxes of the same class (index 5)
              if (boxA[5] != boxB[5]) continue;

              final iou = _calculateIoU(
                  boxA[0], boxA[1], boxA[2], boxA[3],
                  boxB[0], boxB[1], boxB[2], boxB[3]
              );

              if (iou > iouThreshold) {
                  active[j] = false;
              }
          }
      }

      return selected;
  }

  double _calculateIoU(double x1, double y1, double w1, double h1, double x2, double y2, double w2, double h2) {
      final leftA = x1 - w1 / 2;
      final rightA = x1 + w1 / 2;
      final topA = y1 - h1 / 2;
      final bottomA = y1 + h1 / 2;

      final leftB = x2 - w2 / 2;
      final rightB = x2 + w2 / 2;
      final topB = y2 - h2 / 2;
      final bottomB = y2 + h2 / 2;

      final intersectionLeft = leftA > leftB ? leftA : leftB;
      final intersectionTop = topA > topB ? topA : topB;
      final intersectionRight = rightA < rightB ? rightA : rightB;
      final intersectionBottom = bottomA < bottomB ? bottomA : bottomB;

      if (intersectionLeft < intersectionRight && intersectionTop < intersectionBottom) {
          final intersectionArea = (intersectionRight - intersectionLeft) * (intersectionBottom - intersectionTop);
          final areaA = w1 * h1;
          final areaB = w2 * h2;
          return intersectionArea / (areaA + areaB - intersectionArea);
      }
      
      return 0.0;
  }
}
