import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() async {
  try {
    // Assuming the script is run from project root, use absolute or relative path
    final interpreter = await Interpreter.fromFile('assets/pest_model.tflite');
    print('Input tensors: \${interpreter.getInputTensors()}');
    print('Output tensors: \${interpreter.getOutputTensors()}');
    interpreter.close();
  } catch (e) {
    print('Error: \$e');
  }
}
