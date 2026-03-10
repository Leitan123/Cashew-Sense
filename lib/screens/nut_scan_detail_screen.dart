import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

const _charcoal = Color(0xFF1e2820);
const _moss     = Color(0xFF3d5a2e);
const _leaf     = Color(0xFF5c8a3c);
const _lime     = Color(0xFFa8c96e);
const _cream    = Color(0xFFf5f0e8);

class NutScanDetailScreen extends StatelessWidget {
  final String imagePath;
  final String predictedClass;
  final double weight;
  final String finalGrade;

  const NutScanDetailScreen({
    super.key,
    required this.imagePath,
    required this.predictedClass,
    required this.weight,
    required this.finalGrade,
  });

  bool get _isGradeA => finalGrade == 'A';
  bool get _isGradeB => finalGrade == 'B';
  Color get _gradeColor => _isGradeA ? _lime : (_isGradeB ? Colors.orangeAccent : Colors.redAccent);

  @override
  Widget build(BuildContext context) {
    final currentLang = context.watch<LocalizationService>().currentLanguage;

    final titles = {
      'en': 'Scan Details',
      'si': 'පරීක්ෂණ විස්තර',
      'ta': 'ஸ்கேன் விவரங்கள்',
    };

    return Scaffold(
      backgroundColor: _charcoal,
      appBar: buildCashewAppBar(title: titles[currentLang] ?? 'Scan Details'),
      body: Stack(
        children: [
          // Background glows
          Positioned(
            top: -40, left: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _leaf.withOpacity(0.10)),
            ),
          ),
          Positioned(
            bottom: -50, right: -50,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _lime.withOpacity(0.07)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Nut Image ───────────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(imagePath),
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.white38, size: 60),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Result badge ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF243020),
                      border: Border.all(color: _lime.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResultRow(
                          Icons.document_scanner_outlined,
                          currentLang == 'si' ? 'හඳුනාගත් පන්තිය' : currentLang == 'ta' ? 'கண்டறியப்பட்ட வகுப்பு' : 'Detected Class',
                          predictedClass,
                          _lime,
                        ),
                        const Divider(height: 20, color: Color(0x1Af5f0e8)),
                        _buildResultRow(
                          Icons.scale_outlined,
                          currentLang == 'si' ? 'බර (g)' : currentLang == 'ta' ? 'எடை (g)' : 'Weight (g)',
                          '${weight.toStringAsFixed(2)}g',
                          Colors.lightBlueAccent,
                        ),
                        const Divider(height: 20, color: Color(0x1Af5f0e8)),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [_moss, _leaf]),
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              child: const Icon(Icons.verified_outlined, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentLang == 'si' ? 'අවසාන ශ්‍රේණිය' : currentLang == 'ta' ? 'இறுதி தரம்' : 'FINAL GRADE',
                                  style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Grade $finalGrade',
                                  style: TextStyle(color: _gradeColor, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Description panel ───────────────────────────────────────
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _gradeColor.withOpacity(0.08),
                      border: Border.all(color: _gradeColor.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Text('🌰', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isGradeA ? 'Premium Grade' : (_isGradeB ? 'Standard Grade' : 'Economy Grade'),
                                style: TextStyle(color: _gradeColor, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'The AI has analysed the visual properties of this nut and cross-referenced it with its physical weight to determine this final grade classification.',
                                style: TextStyle(color: _cream.withOpacity(0.6), fontSize: 13, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0x66f5f0e8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: Color(0xFFf5f0e8), fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
