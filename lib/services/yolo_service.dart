// // import 'dart:io';
// // import 'package:tflite_flutter/tflite_flutter.dart';
// // import 'package:image/image.dart' as img;

// // class YoloService {
// //   late Interpreter _interpreter;
// //   bool _isLoaded = false;
  
// //   // Assuming classes map to 0: Grade_A, 1: Grade_B, 2: Grade_C based on typical grading models.
// //   List<String> classNames = ["Grade_A", "Grade_B", "Grade_C"];

// //   bool get isLoaded => _isLoaded;

// //   Future<void> loadModel({
// //     String modelPath = 'assets/best_float_new.tflite',
// //     List<String>? classes,
// //   }) async {
// //     _interpreter = await Interpreter.fromAsset(modelPath);
// //     if (classes != null) {
// //       classNames = classes;
// //     }
// //     _isLoaded = true;
// //     print("✅ YOLO TFLite model loaded from $modelPath");
// //   }

// //   Future<List<List<double>>> predict(File imageFile) async {
// //     if (!_isLoaded) {
// //       throw Exception("YOLO model not loaded");
// //     }

// //     // Get expected input shape
// //     final inputShape = _interpreter.getInputTensor(0).shape; // e.g. [1, imgSize, imgSize, 3]
// //     int imgHeight = inputShape[1];
// //     int imgWidth = inputShape[2];

// //     // Decode and resize image
// //     final bytes = await imageFile.readAsBytes();
// //     img.Image? image = img.decodeImage(bytes);
// //     if (image == null) return [];
// //     image = img.copyResize(image, width: imgWidth, height: imgHeight);

// //     // Input shape [1, imgHeight, imgWidth, 3]
// //     var input = List.generate(
// //       1,
// //       (_) => List.generate(
// //         imgHeight,
// //         (_) => List.generate(imgWidth, (_) => List.filled(3, 0.0)),
// //       ),
// //     );

// //     for (int y = 0; y < imgHeight; y++) {
// //       for (int x = 0; x < imgWidth; x++) {
// //         final pixel = image.getPixel(x, y);
// //         input[0][y][x][0] = pixel.r / 255.0;
// //         input[0][y][x][1] = pixel.g / 255.0;
// //         input[0][y][x][2] = pixel.b / 255.0;
// //       }
// //     }

// //     final outputTensors = _interpreter.getOutputTensors();
// //     final outputShape = outputTensors[0].shape; // e.g. [1, 7, 8400] or [1, 8400, 7]
    
// //     // Check if the shape is [1, num_channels, num_boxes] (YOLOv8 standard)
// //     int numChannels = outputShape[1];
// //     int numBoxes = outputShape[2];
    
// //     // Model output: [1, numChannels, numBoxes]
// //     var output = List.generate(1, (_) => List.generate(numChannels, (_) => List.filled(numBoxes, 0.0)));

// //     // Run inference
// //     _interpreter.run(input, output);

// //     // Transpose output to [numBoxes, numChannels] 
// //     List<List<double>> transposed = List.generate(numBoxes, (_) => List.filled(numChannels, 0.0));
// //     for (int i = 0; i < numChannels; i++) {
// //         for (int j = 0; j < numBoxes; j++) {
// //             transposed[j][i] = output[0][i][j];
// //         }
// //     }
    
// //     // Process results (NMS implementation)
// //     List<List<double>> results = [];
    
// //     // In standard YOLOv8, channels 4 onwards are class probabilities 
// //     // Usually no separate objectness score.
// //     for (var pred in transposed) {
// //       double maxClassProb = 0.0;
// //       int maxClassIndex = -1;
      
// //       // Calculate max probability
// //       for (int i = 4; i < numChannels; i++) {
// //           if (pred[i] > maxClassProb) {
// //               maxClassProb = pred[i];
// //               maxClassIndex = i - 4; // Assuming 0-indexed classes
// //           }
// //       }

// //       // Confidence threshold (adjustable)
// //       if (maxClassProb > 0.25) {
// //           // Add [x, y, w, h, classProb, classIndex]
// //           results.add([pred[0], pred[1], pred[2], pred[3], maxClassProb, maxClassIndex.toDouble()]);
// //       }
// //     }

// //     // Apply Non-Maximum Suppression (NMS)
// //     List<List<double>> nmsResults = _applyNMS(results, 0.45);

// //     return nmsResults;
// //   }

// //   // Very basic NMS implementation
// //   List<List<double>> _applyNMS(List<List<double>> boxes, double iouThreshold) {
// //       if (boxes.isEmpty) return [];

// //       // Sort by confidence (index 4)
// //       boxes.sort((a, b) => b[4].compareTo(a[4]));

// //       List<List<double>> selected = [];
// //       List<bool> active = List.filled(boxes.length, true);

// //       for (int i = 0; i < boxes.length; i++) {
// //           if (!active[i]) continue;
          
// //           final boxA = boxes[i];
// //           selected.add(boxA);

// //           for (int j = i + 1; j < boxes.length; j++) {
// //               if (!active[j]) continue;
              
// //               final boxB = boxes[j];
              
// //               // Only compare boxes of the same class (index 5)
// //               if (boxA[5] != boxB[5]) continue;

// //               final iou = _calculateIoU(
// //                   boxA[0], boxA[1], boxA[2], boxA[3],
// //                   boxB[0], boxB[1], boxB[2], boxB[3]
// //               );

// //               if (iou > iouThreshold) {
// //                   active[j] = false;
// //               }
// //           }
// //       }

// //       return selected;
// //   }

// //   double _calculateIoU(double x1, double y1, double w1, double h1, double x2, double y2, double w2, double h2) {
// //       final leftA = x1 - w1 / 2;
// //       final rightA = x1 + w1 / 2;
// //       final topA = y1 - h1 / 2;
// //       final bottomA = y1 + h1 / 2;

// //       final leftB = x2 - w2 / 2;
// //       final rightB = x2 + w2 / 2;
// //       final topB = y2 - h2 / 2;
// //       final bottomB = y2 + h2 / 2;

// //       final intersectionLeft = leftA > leftB ? leftA : leftB;
// //       final intersectionTop = topA > topB ? topA : topB;
// //       final intersectionRight = rightA < rightB ? rightA : rightB;
// //       final intersectionBottom = bottomA < bottomB ? bottomA : bottomB;

// //       if (intersectionLeft < intersectionRight && intersectionTop < intersectionBottom) {
// //           final intersectionArea = (intersectionRight - intersectionLeft) * (intersectionBottom - intersectionTop);
// //           final areaA = w1 * h1;
// //           final areaB = w2 * h2;
// //           return intersectionArea / (areaA + areaB - intersectionArea);
// //       }
      
// //       return 0.0;
// //   }
// // }



// import 'dart:io';
// import 'dart:math';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;

// class NutDetection {
//   final double cx;
//   final double cy;
//   final double w;
//   final double h;
//   final double confidence;
//   final int    classId;
//   final List<List<bool>>? mask;
//   final int maskW;
//   final int maskH;

//   const NutDetection({
//     required this.cx, required this.cy,
//     required this.w,  required this.h,
//     required this.confidence, required this.classId,
//     this.mask, this.maskW = 160, this.maskH = 160,
//   });
// }

// class YoloService {
//   late Interpreter _interpreter;
//   bool _isLoaded   = false;
//   bool _isSegModel = false;

//   List<String> classNames = [
//     "W-180 (White WHoles)", "WW-180 (Extra White - Super White )",
//     "W-210", "WW-210", "W-240", "WW-240", "WWW320",
//     "W-320", "S-210", "S-240", "S-320",
//     "S 210 (Dull White - Like Yellow)", "A-320 (Off White)",
//     "A-240 (off White)", "SSW (Scrotch Whrinkles Wholes)",
//     "DW (Draught Whole)", "OW (oily Wholes)", "RW (Red Whole)",
//     "UW (Unpilled Photri Whole)", "PKW (Partial Wholes Always Black Knots)",
//     "KW (Knot Wholes) Single Knot Green",
//     "KW-1 (Multiple Black Green Mix Knot Wholes)",
//   ];

//   bool get isLoaded   => _isLoaded;
//   bool get isSegModel => _isSegModel;

//   Future<void> loadModel({
//     String modelPath = 'assets/best_seg_float32.tflite',
//     List<String>? classes,
//   }) async {
//     _interpreter = await Interpreter.fromAsset(modelPath);
//     if (classes != null) classNames = classes;
//     final outputs = _interpreter.getOutputTensors();
//     _isSegModel = outputs.length >= 2;
//     _isLoaded   = true;
//     print("YoloService loaded: $modelPath | seg=$_isSegModel | outputs=${outputs.length}");
//     for (int i = 0; i < outputs.length; i++) {
//       print("  Output[$i] shape: ${outputs[i].shape}");
//     }
//   }

//   Future<List<NutDetection>> predict(File imageFile) async {
//     if (!_isLoaded) throw Exception("YOLO model not loaded");

//     final inputShape  = _interpreter.getInputTensor(0).shape;
//     final int imgH    = inputShape[1];
//     final int imgW    = inputShape[2];

//     final bytes = await imageFile.readAsBytes();
//     img.Image? image = img.decodeImage(bytes);
//     if (image == null) return [];
//     image = img.copyResize(image, width: imgW, height: imgH);

//     var input = List.generate(1, (_) =>
//       List.generate(imgH, (y) =>
//         List.generate(imgW, (x) {
//           final pixel = image!.getPixel(x, y);
//           return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
//         })
//       )
//     );

//     final outputTensors   = _interpreter.getOutputTensors();
//     final out0Shape       = outputTensors[0].shape;
//     final int numChannels = out0Shape[1];
//     final int numBoxes    = out0Shape[2];

//     var output0 = List.generate(1, (_) =>
//       List.generate(numChannels, (_) => List.filled(numBoxes, 0.0))
//     );

//     int numProtos = 32, mH = 160, mW = 160;
//     List<List<List<List<double>>>> output1 = [];

//     if (_isSegModel) {
//       final s = outputTensors[1].shape;
//       numProtos = s[1]; mH = s[2]; mW = s[3];
//       output1 = List.generate(1, (_) =>
//         List.generate(numProtos, (_) =>
//           List.generate(mH, (_) => List.filled(mW, 0.0))
//         )
//       );
//       _interpreter.runForMultipleInputs([input], {0: output0, 1: output1});
//     } else {
//       _interpreter.run(input, output0);
//     }

//     final int numClasses = _isSegModel
//         ? numChannels - 4 - numProtos
//         : numChannels - 4;

//     List<List<double>> transposed = List.generate(
//       numBoxes, (_) => List.filled(numChannels, 0.0),
//     );
//     for (int c = 0; c < numChannels; c++) {
//       for (int b = 0; b < numBoxes; b++) {
//         transposed[b][c] = output0[0][c][b];
//       }
//     }

//     final List<NutDetection> raw = [];
//     for (final pred in transposed) {
//       double maxClassProb  = 0.0;
//       int    maxClassIndex = -1;
//       for (int i = 4; i < 4 + numClasses; i++) {
//         if (pred[i] > maxClassProb) {
//           maxClassProb  = pred[i];
//           maxClassIndex = i - 4;
//         }
//       }
//       if (maxClassProb < 0.25) continue;

//       List<List<bool>>? mask;
//       if (_isSegModel && output1.isNotEmpty) {
//         final int coeffStart = 4 + numClasses;
//         final coeffs = pred.sublist(coeffStart, coeffStart + numProtos);
//         mask = _computeMask(coeffs, output1[0], mH, mW,
//             pred[0], pred[1], pred[2], pred[3]);
//       }

//       raw.add(NutDetection(
//         cx: pred[0], cy: pred[1], w: pred[2], h: pred[3],
//         confidence: maxClassProb, classId: maxClassIndex,
//         mask: mask, maskW: mW, maskH: mH,
//       ));
//     }

//     return _applyNMS(raw, 0.45);
//   }

//   List<List<bool>> _computeMask(
//     List<double> coeffs, List<List<List<double>>> protos,
//     int mH, int mW, double cx, double cy, double bw, double bh,
//   ) {
//     final int x1 = ((cx - bw/2) * mW).clamp(0.0, mW-1.0).toInt();
//     final int y1 = ((cy - bh/2) * mH).clamp(0.0, mH-1.0).toInt();
//     final int x2 = ((cx + bw/2) * mW).clamp(0.0, mW-1.0).toInt();
//     final int y2 = ((cy + bh/2) * mH).clamp(0.0, mH-1.0).toInt();
//     final int k  = min(coeffs.length, protos.length);

//     final mask = List.generate(mH, (_) => List.filled(mW, false));
//     for (int y = y1; y <= y2; y++) {
//       for (int x = x1; x <= x2; x++) {
//         double val = 0.0;
//         for (int i = 0; i < k; i++) val += coeffs[i] * protos[i][y][x];
//         mask[y][x] = (1.0 / (1.0 + exp(-val))) > 0.5;
//       }
//     }
//     return mask;
//   }

//   List<NutDetection> _applyNMS(List<NutDetection> boxes, double iouThreshold) {
//     if (boxes.isEmpty) return [];
//     boxes.sort((a, b) => b.confidence.compareTo(a.confidence));
//     final active   = List.filled(boxes.length, true);
//     final selected = <NutDetection>[];
//     for (int i = 0; i < boxes.length; i++) {
//       if (!active[i]) continue;
//       selected.add(boxes[i]);
//       for (int j = i + 1; j < boxes.length; j++) {
//         if (!active[j]) continue;
//         if (boxes[i].classId != boxes[j].classId) continue;
//         if (_calculateIoU(boxes[i], boxes[j]) > iouThreshold) active[j] = false;
//       }
//     }
//     return selected;
//   }

//   double _calculateIoU(NutDetection a, NutDetection b) {
//     final iLeft   = max(a.cx - a.w/2, b.cx - b.w/2);
//     final iRight  = min(a.cx + a.w/2, b.cx + b.w/2);
//     final iTop    = max(a.cy - a.h/2, b.cy - b.h/2);
//     final iBottom = min(a.cy + a.h/2, b.cy + b.h/2);
//     if (iLeft >= iRight || iTop >= iBottom) return 0.0;
//     final inter = (iRight - iLeft) * (iBottom - iTop);
//     return inter / (a.w * a.h + b.w * b.h - inter);
//   }
// }




import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// ─────────────────────────────────────────────────────────────────────────────
// NutDetection
// ─────────────────────────────────────────────────────────────────────────────
class NutDetection {
  final double cx, cy, w, h, confidence;
  final int    classId;
  final List<List<bool>>? mask;
  final int maskW, maskH;

  const NutDetection({
    required this.cx, required this.cy,
    required this.w,  required this.h,
    required this.confidence, required this.classId,
    this.mask, this.maskW = 160, this.maskH = 160,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Isolate helpers — must be top-level
// ─────────────────────────────────────────────────────────────────────────────
class _PreprocessInput {
  final Uint8List bytes;
  final int w, h;
  const _PreprocessInput(this.bytes, this.w, this.h);
}

class _MaskInput {
  final List<double> coeffs;
  final List<List<List<double>>> protos; // [32][mH][mW]
  final int mH, mW;
  final double cx, cy, bw, bh;
  const _MaskInput(this.coeffs, this.protos, this.mH, this.mW,
      this.cx, this.cy, this.bw, this.bh);
}

List<List<List<List<double>>>> _preprocessImage(_PreprocessInput input) {
  img.Image? image = img.decodeImage(input.bytes);
  if (image == null) return [];
  image = img.copyResize(image, width: input.w, height: input.h);
  return List.generate(1, (_) =>
    List.generate(input.h, (y) =>
      List.generate(input.w, (x) {
        final p = image!.getPixel(x, y);
        return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
      })
    )
  );
}

List<List<bool>> _computeMaskIsolate(_MaskInput input) {
  final x1 = ((input.cx - input.bw/2) * input.mW).clamp(0.0, input.mW-1.0).toInt();
  final y1 = ((input.cy - input.bh/2) * input.mH).clamp(0.0, input.mH-1.0).toInt();
  final x2 = ((input.cx + input.bw/2) * input.mW).clamp(0.0, input.mW-1.0).toInt();
  final y2 = ((input.cy + input.bh/2) * input.mH).clamp(0.0, input.mH-1.0).toInt();
  final int k = min(input.coeffs.length, input.protos.length);
  final mask = List.generate(input.mH, (_) => List.filled(input.mW, false));
  for (int y = y1; y <= y2; y++) {
    for (int x = x1; x <= x2; x++) {
      double val = 0.0;
      for (int i = 0; i < k; i++) val += input.coeffs[i] * input.protos[i][y][x];
      mask[y][x] = (1.0 / (1.0 + exp(-val))) > 0.5;
    }
  }
  return mask;
}

class _RawDetection {
  final double cx, cy, w, h, confidence;
  final int classId;
  final List<double>? coeffs;
  const _RawDetection({
    required this.cx, required this.cy,
    required this.w,  required this.h,
    required this.confidence, required this.classId,
    this.coeffs,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// YoloService
// ─────────────────────────────────────────────────────────────────────────────
class YoloService {
  late Interpreter _interpreter;
  bool _isLoaded   = false;
  bool _isSegModel = false;

  // ── Class names (must match data.yaml order from training) ────────────────
  List<String> classNames = [
    "W-180 (White WHoles)",
    "WW-180 (Extra White - Super White )",
    "W-210", "WW-210", "W-240", "WW-240", "WWW320",
    "W-320", "S-210", "S-240", "S-320",
    "S 210 (Dull White - Like Yellow)",
    "A-320 (Off White)", "A-240 (off White)",
    "SSW (Scrotch Whrinkles Wholes)",
    "DW (Draught Whole)", "OW (oily Wholes)", "RW (Red Whole)",
    "UW (Unpilled Photri Whole)",
    "PKW (Partial Wholes Always Black Knots)",
    "KW (Knot Wholes) Single Knot Green",
    "KW-1 (Multiple Black Green Mix Knot Wholes)",
  ];

  bool get isLoaded   => _isLoaded;
  bool get isSegModel => _isSegModel;

  // ── loadModel ──────────────────────────────────────────────────────────────
  Future<void> loadModel({String? modelPath, List<String>? classes}) async {
    if (classes != null) classNames = classes;

    final List<String> candidates = [
      if (modelPath != null) modelPath,
      'assets/best_seg_float32.tflite',
      'assets/best_new_float32.tflite',
      'assets/best_float_new.tflite',
      'assets/best.tflite',
    ];

    String? loaded;
    Object? lastErr;
    for (final path in candidates) {
      try {
        _interpreter = await Interpreter.fromAsset(
          path, options: InterpreterOptions()..threads = 4,
        );
        loaded = path;
        break;
      } catch (e) {
        lastErr = e;
        print("⚠️  $path not found, trying next...");
      }
    }
    if (loaded == null) {
      throw Exception("No model found. Last error: $lastErr");
    }

    final outputs    = _interpreter.getOutputTensors();
    final s0         = outputs[0].shape; // e.g. [1, 58, 8400]

    // Detect layout: smaller dim = channels
    final bool layoutCB = s0[1] <= s0[2];
    final int  numCh    = layoutCB ? s0[1] : s0[2];

    // If channels = 4 + 22 + 32 = 58 → this is a seg model
    // even if TFLite only reports 1 output tensor
    const int kNumClasses = 22;
    const int kNumProtos  = 32;
    _isSegModel = (outputs.length >= 2) ||
                  (numCh == kNumClasses + 4 + kNumProtos);

    _isLoaded = true;

    print("✅ Loaded: $loaded");
    print("   seg=$_isSegModel  outputs=${outputs.length}  shape=$s0");
    for (int i = 0; i < outputs.length; i++) {
      print("   Output[$i] shape=${outputs[i].shape}");
    }
    print("   Input shape=${_interpreter.getInputTensor(0).shape}");
  }

  // ── predict ────────────────────────────────────────────────────────────────
  Future<List<NutDetection>> predict(File imageFile) async {
    if (!_isLoaded) throw Exception("YOLO model not loaded");

    final inputShape = _interpreter.getInputTensor(0).shape;
    final int imgH   = inputShape[1];
    final int imgW   = inputShape[2];

    // 1. Preprocess off main thread
    final input = await compute(
      _preprocessImage,
      _PreprocessInput(await imageFile.readAsBytes(), imgW, imgH),
    );
    if (input.isEmpty) return [];

    // 2. Output tensor shape
    final outputTensors = _interpreter.getOutputTensors();
    final List<int> s0  = outputTensors[0].shape;

    // Layout detection: smaller dim is always channels
    final bool layoutCB = s0[1] <= s0[2];  // [1,C,B] vs [1,B,C]
    final int numCh     = layoutCB ? s0[1] : s0[2];
    final int numBoxes  = layoutCB ? s0[2] : s0[1];

    // Hard-code known constants for this 22-class seg model
    const int numClasses = 22;
    const int numProtos  = 32;

    print("[YOLO] shape=$s0  layout=${layoutCB ? 'CB' : 'BC'}  ch=$numCh  boxes=$numBoxes  seg=$_isSegModel");
    print("[YOLO] numClasses=$numClasses  numProtos=$numProtos  check=${4+numClasses+numProtos}==$numCh");

    // Allocate output0 in exact raw shape
    var output0 = List.generate(1, (_) =>
      List.generate(s0[1], (_) => List.filled(s0[2], 0.0))
    );

    // Prototype mask tensor — only if 2 output tensors
    int mH = 160, mW = 160;
    List<List<List<List<double>>>> output1 = [];

    if (outputTensors.length >= 2) {
      final s1 = outputTensors[1].shape;
      print("[YOLO] proto tensor shape=$s1");

      // Handle both BCHW [1,32,160,160] and BHWC [1,160,160,32]
      // The proto dim (32) is always the smallest non-batch dimension
      if (s1.length == 4) {
        if (s1[1] == numProtos) {
          // BCHW layout  [1, 32, H, W]
          mH = s1[2]; mW = s1[3];
          output1 = List.generate(1, (_) =>
            List.generate(s1[1], (_) =>
              List.generate(mH, (_) => List.filled(mW, 0.0))
            )
          );
        } else if (s1[3] == numProtos) {
          // BHWC layout  [1, H, W, 32]  ← your model's format
          mH = s1[1]; mW = s1[2];
          // Allocate in BHWC, then transpose after inference
          var rawOutput1 = List.generate(1, (_) =>
            List.generate(mH, (_) =>
              List.generate(mW, (_) => List.filled(numProtos, 0.0))
            )
          );
          _interpreter.runForMultipleInputs([input], {0: output0, 1: rawOutput1});

          // Transpose BHWC → BCHW so rest of code is consistent
          output1 = List.generate(1, (_) =>
            List.generate(numProtos, (p) =>
              List.generate(mH, (y) =>
                List.generate(mW, (x) => rawOutput1[0][y][x][p])
              )
            )
          );
          print("[YOLO] proto transposed BHWC→BCHW  mH=$mH  mW=$mW");
        } else {
          // Unknown layout — try s1[1] as numProtos anyway
          mH = s1[2]; mW = s1[3];
          output1 = List.generate(1, (_) =>
            List.generate(s1[1], (_) =>
              List.generate(mH, (_) => List.filled(mW, 0.0))
            )
          );
          _interpreter.runForMultipleInputs([input], {0: output0, 1: output1});
        }
      } else {
        _interpreter.run(input, output0);
      }
    } else {
      // Single output — coefficients are embedded in output0 rows 4+22 onward
      _interpreter.run(input, output0);
      print("[YOLO] single-output model — masks unavailable");
    }

    // 3. Normalise output0 → [numBoxes][numCh]
    final List<List<double>> rows = layoutCB
        ? List.generate(numBoxes, (b) =>
            List.generate(numCh, (c) => output0[0][c][b]))
        : List.generate(numBoxes, (b) =>
            List.generate(numCh, (c) => output0[0][b][c]));

    // 4. Filter — conf=0.10 matches app.py
    final List<_RawDetection> rawBoxes = [];
    double dbgMaxConf = 0.0;

    for (final row in rows) {
      double maxProb = 0.0;
      int    maxIdx  = -1;
      // Class scores are at indices 4 … 4+numClasses-1
      for (int i = 4; i < 4 + numClasses; i++) {
        if (row[i] > maxProb) { maxProb = row[i]; maxIdx = i - 4; }
      }
      if (maxProb > dbgMaxConf) dbgMaxConf = maxProb;
      if (maxProb < 0.10) continue;

      // Mask coefficients follow the class scores
      List<double>? coeffs;
      if (_isSegModel && row.length >= 4 + numClasses + numProtos) {
        coeffs = row.sublist(4 + numClasses, 4 + numClasses + numProtos);
      }

      rawBoxes.add(_RawDetection(
        cx: row[0], cy: row[1], w: row[2], h: row[3],
        confidence: maxProb, classId: maxIdx,
        coeffs: coeffs,
      ));
    }

    print("[YOLO] maxConf=$dbgMaxConf  raw=${rawBoxes.length}");

    // 5. NMS
    final nmsed = _applyNMS(rawBoxes, 0.45);
    print("[YOLO] afterNMS=${nmsed.length}");

    // 6. Compute masks
    final List<NutDetection> detections = [];
    for (final raw in nmsed) {
      List<List<bool>>? mask;
      if (output1.isNotEmpty && raw.coeffs != null) {
        mask = await compute(
          _computeMaskIsolate,
          _MaskInput(raw.coeffs!, output1[0], mH, mW,
              raw.cx, raw.cy, raw.w, raw.h),
        );
      }
      detections.add(NutDetection(
        cx: raw.cx, cy: raw.cy, w: raw.w, h: raw.h,
        confidence: raw.confidence, classId: raw.classId,
        mask: mask, maskW: mW, maskH: mH,
      ));
    }

    return detections;
  }

  // ── NMS ───────────────────────────────────────────────────────────────────
  List<_RawDetection> _applyNMS(List<_RawDetection> boxes, double iouThr) {
    if (boxes.isEmpty) return [];
    boxes.sort((a, b) => b.confidence.compareTo(a.confidence));
    final active = List.filled(boxes.length, true);
    final out    = <_RawDetection>[];
    for (int i = 0; i < boxes.length; i++) {
      if (!active[i]) continue;
      out.add(boxes[i]);
      for (int j = i+1; j < boxes.length; j++) {
        if (!active[j] || boxes[i].classId != boxes[j].classId) continue;
        if (_iou(boxes[i], boxes[j]) > iouThr) active[j] = false;
      }
    }
    return out;
  }

  double _iou(_RawDetection a, _RawDetection b) {
    final il = max(a.cx-a.w/2, b.cx-b.w/2);
    final ir = min(a.cx+a.w/2, b.cx+b.w/2);
    final it = max(a.cy-a.h/2, b.cy-b.h/2);
    final ib = min(a.cy+a.h/2, b.cy+b.h/2);
    if (il >= ir || it >= ib) return 0.0;
    final inter = (ir-il)*(ib-it);
    return inter / (a.w*a.h + b.w*b.h - inter);
  }
}