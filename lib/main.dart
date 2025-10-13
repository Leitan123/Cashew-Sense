import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const LeafDetectorApp());
}

class LeafDetectorApp extends StatelessWidget {
  const LeafDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashew Leaf Detector',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Interpreter? _interpreter;
  File? _image;
  String _result = '';

  final List<String> classNames = ['Anthracnose', 'Healthy'];

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      print('🟡 Loading model...');
      _interpreter = await Interpreter.fromAsset(
        'assets/cashew_classifier.tflite',
      );
      print('✅ Model loaded successfully!');
      setState(() {});
    } catch (e) {
      print('❌ Failed to load model: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = '';
      });
      _runModel(File(pickedFile.path));
    }
  }

  /*void _runModel(File imageFile) async {
    if (_interpreter == null) return;

    // 1. Load image
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return;

    // 2. Resize to 128x128
    img.Image resizedImage = img.copyResize(image, width: 128, height: 128);

    // 3. Convert image to Float32List [1,128,128,3]
    var input = Float32List(1 * 128 * 128 * 3);
    int pixelIndex = 0;
    for (int y = 0; y < 128; y++) {
      for (int x = 0; x < 128; x++) {
        img.Pixel pixel = resizedImage.getPixel(x, y); // <-- Pixel object
        input[pixelIndex++] = pixel.r / 255.0; // Red channel
        input[pixelIndex++] = pixel.g / 255.0; // Green channel
        input[pixelIndex++] = pixel.b / 255.0; // Blue channel
      }
    }

    // 4. Reshape to 4D tensor
    var inputTensor = input.reshape([1, 128, 128, 3]);

    // 5. Prepare output tensor
    var output = List.filled(
      classNames.length,
      0.0,
    ).reshape([1, classNames.length]);

    // 6. Run the model
    //_interpreter!.run(inputTensor, output);

    print('Running inference...');
    _interpreter!.run(inputTensor, output);
    print('Output: $output');

    // 7. Get highest probability class
    int maxIndex = output[0].indexOf(output[0].reduce((a, b) => a > b ? a : b));

    setState(() {
      _result =
          '${classNames[maxIndex]} (${(output[0][maxIndex] * 100).toStringAsFixed(2)}%)';
    });
  }*/

  void _runModel(File imageFile) async {
    print("🟢 Starting _runModel...");

    if (_interpreter == null) {
      print("❌ Interpreter not loaded!");
      return;
    }

    try {
      // 1️⃣ Load image bytes
      print("📂 Loading image...");
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        print("❌ Could not decode image");
        return;
      }

      // 2️⃣ Resize image
      print("📏 Resizing image...");
      final resizedImage = img.copyResize(image, width: 128, height: 128);

      // 3️⃣ Prepare input tensor as Float32List [1, 128, 128, 3]
      print("🧮 Preparing input tensor...");
      final input = Float32List(1 * 128 * 128 * 3);
      int pixelIndex = 0;

      for (int y = 0; y < 128; y++) {
        for (int x = 0; x < 128; x++) {
          final pixel = resizedImage.getPixel(x, y); // Pixel object
          input[pixelIndex++] = pixel.r / 255.0; // R
          input[pixelIndex++] = pixel.g / 255.0; // G
          input[pixelIndex++] = pixel.b / 255.0; // B
        }
      }

      // 4️⃣ Reshape input to 4D tensor
      final inputTensor = input.reshape([1, 128, 128, 3]);

      // 5️⃣ Prepare output tensor
      final output = List.generate(
        1,
        (_) => List.filled(classNames.length, 0.0),
      );

      // 6️⃣ Run inference
      print("🚀 Running inference...");
      _interpreter!.run(inputTensor, output);
      print("✅ Output tensor: $output");

      // 7️⃣ Find the class with highest probability
      final maxIndex = output[0].indexOf(
        output[0].reduce((a, b) => a > b ? a : b),
      );

      setState(() {
        _result =
            '${classNames[maxIndex]} (${(output[0][maxIndex] * 100).toStringAsFixed(2)}%)';
      });

      print("🏁 Prediction complete → $_result");
    } catch (e) {
      print("❌ Error while running model: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cashew Leaf Detector')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, height: 200)
                : const Icon(Icons.image, size: 150, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              _result,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
          ],
        ),
      ),
    );
  }
}
