import 'package:flutter/material.dart';
import '../services/soil_model_service.dart';
import '../widgets/common_widgets.dart';

class SoilAnalysisScreen extends StatefulWidget {
  const SoilAnalysisScreen({super.key});

  @override
  State<SoilAnalysisScreen> createState() => _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState extends State<SoilAnalysisScreen> {
  final SoilModelService _model = SoilModelService();

  double? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  /// Load TFLite model safely
  Future<void> _loadModel() async {
    try {
      debugPrint('⏳ Loading soil model...');
      await _model.loadModel();
      debugPrint('✅ Soil model loaded');

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Model load failed: $e');

      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load soil model';
        });
      }
    }
  }

  /// Run prediction
  void _runPrediction() {
    try {
      final prediction = _model.predict(
       f1: 32.67,
f2: 1.99,
f3: 76.93,
ph: 4.09,
f5: 5.13,
f6: 14.58,
f7: 25.13,

      );

      debugPrint('📊 Prediction result: $prediction');

      setState(() {
        _result = prediction;
      });
    } catch (e) {
      debugPrint('❌ Prediction failed: $e');

      setState(() {
        _error = 'Prediction failed';
      });
    }
  }

  @override
  void dispose() {
    _model.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCashewAppBar(title: 'Soil Analysis'),
      backgroundColor: const Color(0xFFF5F5DC),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ),

                  ElevatedButton(
                    onPressed: _runPrediction,
                    child: const Text('Predict Soil Health'),
                  ),

                  const SizedBox(height: 20),

                  if (_result != null)
                    Text(
                      'Soil Health Score: ${_result!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
