import 'package:flutter/material.dart';
import 'dart:io';
import '../services/soil_model_service.dart';
import '../widgets/common_widgets.dart';
import '../services/localization_service.dart';

const _charcoal = Color(0xFF1e2820);
const _moss     = Color(0xFF3d5a2e);
const _leaf     = Color(0xFF5c8a3c);
const _lime     = Color(0xFFa8c96e);
const _cream    = Color(0xFFf5f0e8);

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

  Future<void> _loadModel() async {
    try {
      debugPrint('⏳ Loading soil model...');
      await _model.loadModel();
      debugPrint('✅ Soil model loaded');
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint('❌ Model load failed: $e');
      if (mounted) setState(() {
        _loading = false;
        _error = 'Failed to load soil model';
      });
    }
  }

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
      setState(() => _result = prediction);
    } catch (e) {
      debugPrint('❌ Prediction failed: $e');
      setState(() => _error = 'Prediction failed');
    }
  }

  @override
  void dispose() {
    _model.close();
    super.dispose();
  }

  String _scoreLabel(double score) {
    if (score >= 0.7) return 'Excellent';
    if (score >= 0.5) return 'Moderate';
    return 'Poor';
  }

  Color _scoreColor(double score) {
    if (score >= 0.7) return _lime;
    if (score >= 0.5) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _charcoal,
      appBar: buildCashewAppBar(title: 'Soil Analysis'.tr(context)),
      body: Stack(
        children: [
          Positioned(
            top: -50, left: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _leaf.withOpacity(0.10),
              ),
            ),
          ),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header ────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_moss, _leaf],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.science_outlined, color: _lime, size: 36),
                              const SizedBox(height: 12),
                              Text('Soil Health Analysis',
                                  style: TextStyle(color: _cream, fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text('Run the model to evaluate your soil health score.',
                                  style: TextStyle(color: _cream.withOpacity(0.65), fontSize: 13, height: 1.5)),
                            ],
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(_error!,
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // ── Result Display ────────────────────────────────
                        if (_result != null) ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF243020),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _lime.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Text('SOIL HEALTH SCORE',
                                    style: TextStyle(color: _cream.withOpacity(0.35), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.8)),
                                const SizedBox(height: 16),
                                Text(
                                  _result!.toStringAsFixed(2),
                                  style: TextStyle(
                                    color: _scoreColor(_result!),
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _scoreColor(_result!).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(color: _scoreColor(_result!).withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    _scoreLabel(_result!),
                                    style: TextStyle(color: _scoreColor(_result!), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.grass_outlined, size: 80, color: _cream.withOpacity(0.1)),
                                const SizedBox(height: 16),
                                Text('No results yet', style: TextStyle(color: _cream.withOpacity(0.25), fontSize: 15)),
                              ],
                            ),
                          ),
                        ],

                        // ── Predict Button ────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [_moss, _leaf]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: _leaf.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _runPrediction,
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                            label: const Text('Predict Soil Health',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
