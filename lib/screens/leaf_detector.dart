/*import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class LeafDetector extends StatefulWidget {
  const LeafDetector({super.key});

  @override
  State<LeafDetector> createState() => _LeafDetectorState();
}

class _LeafDetectorState extends State<LeafDetector> {
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

  void _runModel(File imageFile) async {
    if (_interpreter == null) return;

    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;

    final resizedImage = img.copyResize(image, width: 128, height: 128);

    final input = Float32List(1 * 128 * 128 * 3);
    int pixelIndex = 0;
    for (int y = 0; y < 128; y++) {
      for (int x = 0; x < 128; x++) {
        final pixel = resizedImage.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    final inputTensor = input.reshape([1, 128, 128, 3]);
    final output = List.generate(1, (_) => List.filled(classNames.length, 0.0));

    _interpreter!.run(inputTensor, output);

    final maxIndex = output[0].indexOf(
      output[0].reduce((a, b) => a > b ? a : b),
    );

    setState(() {
      _result =
          '${classNames[maxIndex]} (${(output[0][maxIndex] * 100).toStringAsFixed(2)}%)';
    });
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
*/
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '/widgets/common_widgets.dart'; // import your reusable widgets

class LeafDetector extends StatefulWidget {
  const LeafDetector({super.key});

  @override
  State<LeafDetector> createState() => _LeafDetectorState();
}

class _LeafDetectorState extends State<LeafDetector> {
  Interpreter? _interpreter;
  File? _image;
  String _result = '';
  final List<String> classNames = ['Anthracnose', 'Healthy'];
  final List<File> _recentScans = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      debugPrint('🟡 Loading model...');
      _interpreter = await Interpreter.fromAsset(
        'assets/cashew_classifier.tflite',
      );
      debugPrint('✅ Model loaded successfully!');
      setState(() {});
    } catch (e) {
      debugPrint('❌ Failed to load model: $e');
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
      _recentScans.insert(0, File(pickedFile.path));
    }
  }

  void _runModel(File imageFile) async {
    if (_interpreter == null) return;

    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;

    final resizedImage = img.copyResize(image, width: 128, height: 128);

    final input = Float32List(1 * 128 * 128 * 3);
    int pixelIndex = 0;
    for (int y = 0; y < 128; y++) {
      for (int x = 0; x < 128; x++) {
        final pixel = resizedImage.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    final inputTensor = input.reshape([1, 128, 128, 3]);
    final output = List.generate(1, (_) => List.filled(classNames.length, 0.0));

    _interpreter!.run(inputTensor, output);

    final maxIndex = output[0].indexOf(
      output[0].reduce((a, b) => a > b ? a : b),
    );

    setState(() {
      _result =
          '${classNames[maxIndex]} (${(output[0][maxIndex] * 100).toStringAsFixed(2)}%)';
    });
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigation handling can be added later
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: buildCashewAppBar(title: 'CashewSense'),
      bottomNavigationBar: buildCashewBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner Section with Camera Button Overlapping
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage('assets/leaf_banner.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Identify Leaf Disease',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E3A20),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            const Text(
              'Take Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E3A20),
              ),
            ),
            const SizedBox(height: 20),

            if (_image != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_image!, height: 200),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _result,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3A20),
                    ),
                  ),
                ],
              )
            else
              const Icon(Icons.image_outlined, size: 150, color: Colors.grey),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Scans',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: _recentScans.isEmpty
                  ? const Center(child: Text('No recent scans yet.'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentScans.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _recentScans[index],
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
