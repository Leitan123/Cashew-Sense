import 'dart:io';
import 'package:flutter/material.dart';
import '/data/pest_database.dart';
import '/widgets/common_widgets.dart';
import 'package:provider/provider.dart';
import '/services/localization_service.dart';

const _charcoal = Color(0xFF1e2820);
const _moss     = Color(0xFF3d5a2e);
const _leaf     = Color(0xFF5c8a3c);
const _lime     = Color(0xFFa8c96e);
const _cream    = Color(0xFFf5f0e8);

class PestScanDetailScreen extends StatelessWidget {
  final String imagePath;
  final String pestName;

  const PestScanDetailScreen({
    super.key,
    required this.imagePath,
    required this.pestName,
  });

  @override
  Widget build(BuildContext context) {
    final currentLang = context.watch<LocalizationService>().currentLanguage;
    final Map<String, dynamic> langDb = localizedPestDatabase[currentLang] ?? localizedPestDatabase['en']!;
    final db = langDb[pestName];

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
                  // ── Leaf Image ───────────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(imagePath),
                      height: 230,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 230,
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
                  const SizedBox(height: 16),

                  // ── Result badge ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.withOpacity(0.15), Colors.red.withOpacity(0.05)],
                      ),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            db != null ? pestName.replaceAll('_', ' ') : pestName.replaceAll('_', ' '),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Disease panel ─────────────────────────────────────────
                  if (db != null) ...[
                    const SizedBox(height: 20),
                    _PestPanel(db: db, currentLang: currentLang, pestName: pestName),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pest Panel ─────────────────────────────────────────────────────────────

class _PestPanel extends StatelessWidget {
  final Map<String, dynamic> db;
  final String currentLang;
  final String pestName;
  const _PestPanel({required this.db, required this.currentLang, required this.pestName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1e2820).withOpacity(0.9),
        border: Border.all(color: _lime.withOpacity(0.18)),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_moss, _leaf]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bug_report_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pestName.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(color: _lime, fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(db['scientific_name'] ?? '',
                        style: TextStyle(color: _cream.withOpacity(0.5), fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              if (db['severity'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text((db['severity'] as String).toUpperCase(),
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.7)),
                ),
            ],
          ),

          const SizedBox(height: 16),
          if (db['description'] != null)
            Text(db['description'],
                style: TextStyle(color: _cream.withOpacity(0.65), fontSize: 13, height: 1.6)),

          if (db['symptoms'] != null) ...[
            const SizedBox(height: 20),
            _sectionTitle(currentLang == 'si' ? 'රෝග ලක්ෂණ' : currentLang == 'ta' ? 'அறிகுறிகள்' : 'Symptoms'),
            ...(db['symptoms'] as List<dynamic>).map((s) => _symptomRow(s.toString())),
          ],

          if (db['treatments'] != null) ...[
            const SizedBox(height: 20),
            _sectionTitle(currentLang == 'si' ? 'ප්‍රතිකාර' : currentLang == 'ta' ? 'சிகிச்சை' : 'Remedies & Treatment'),
            ...(db['treatments'] as List<dynamic>).map((t) => _treatmentCard(t as Map<String, dynamic>, currentLang)),
          ],

          if (db['prevention'] != null) ...[
            const SizedBox(height: 20),
            _sectionTitle(currentLang == 'si' ? 'වැළැක්වීම' : currentLang == 'ta' ? 'தடுப்பு' : 'Prevention'),
            ...(db['prevention'] as List<dynamic>).map((p) => _preventionCard(p as Map<String, dynamic>)),
          ],

          if (db['additional_info'] != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _lime.withOpacity(0.05),
                border: Border.all(color: _lime.withOpacity(0.12)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(db['additional_info'],
                          style: TextStyle(color: _cream.withOpacity(0.6), fontSize: 12, height: 1.6))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  color: _cream.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.07))),
        ],
      ),
    );
  }

  Widget _symptomRow(String sym) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.025), borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠', style: TextStyle(color: Colors.orange, fontSize: 11)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(sym,
                  style: TextStyle(color: _cream.withOpacity(0.7), fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }

  Widget _treatmentCard(Map<String, dynamic> t, String currentLang) {
    final bool isEco = t['type'] != 'chemical';
    Color typeColor = Colors.redAccent;
    Color typeBg = Colors.redAccent.withOpacity(0.12);
    
    final labels = {
      'chemical': {'en': 'Chemical', 'si': 'රසායනික', 'ta': 'இரசாயனம்'},
      'organic': {'en': 'Organic', 'si': 'කාබනික', 'ta': 'கரிம'},
      'biological': {'en': 'Biological', 'si': 'ජීව විද්‍යාත්මක', 'ta': 'உயிரியல்'},
      'mechanical': {'en': 'Mechanical', 'si': 'යාන්ත්‍රික', 'ta': 'இயந்திர'},
    };

    String tType = t['type'] ?? 'chemical';
    String typeLabel = labels[tType]?[currentLang] ?? 'Chemical';

    if (tType == 'organic') {
      typeColor = _lime; typeBg = _lime.withOpacity(0.15);
    } else if (tType == 'biological') {
      typeColor = Colors.lightBlue; typeBg = Colors.lightBlue.withOpacity(0.12);
    } else if (tType == 'mechanical') {
      typeColor = Colors.grey; typeBg = Colors.grey.withOpacity(0.12);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEco ? _leaf.withOpacity(0.07) : Colors.redAccent.withOpacity(0.05),
        border: Border.all(
            color: isEco ? _lime.withOpacity(0.14) : Colors.redAccent.withOpacity(0.14)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(t['name'],
                      style: TextStyle(color: _cream, fontSize: 13, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration:
                    BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(50)),
                child: Text(typeLabel.toUpperCase(),
                    style: TextStyle(
                        color: typeColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(t['description'],
              style: TextStyle(color: _cream.withOpacity(0.65), fontSize: 12, height: 1.5)),
          if (t['timing'] != null || t['note'] != null) ...[
            const SizedBox(height: 8),
            if (t['timing'] != null)
              Text('🕐 ${t['timing']}',
                  style: TextStyle(color: _cream.withOpacity(0.4), fontSize: 11)),
            if (t['note'] != null)
              Text('⚠️ ${t['note']}',
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _preventionCard(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p['measure'],
              style: TextStyle(color: _cream, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(p['description'],
              style: TextStyle(color: _cream.withOpacity(0.6), fontSize: 12, height: 1.5)),
          if (p['frequency'] != null) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _lime.withOpacity(0.1), borderRadius: BorderRadius.circular(50)),
              child: Text('🔁 ${p['frequency']}', style: TextStyle(color: _lime, fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }
}
