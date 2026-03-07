import 'dart:io';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

class SoilScanHistoryScreen extends StatefulWidget {
  const SoilScanHistoryScreen({super.key});

  @override
  State<SoilScanHistoryScreen> createState() => _SoilScanHistoryScreenState();
}

class _SoilScanHistoryScreenState extends State<SoilScanHistoryScreen> {
  List<Map<String, dynamic>> _scans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    final userId = AuthService.instance.currentUserId;
    if (userId != null) {
      final scans = await DatabaseService.instance.getSoilScans(userId);
      setState(() {
        _scans = scans;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteScan(int id) async {
    await DatabaseService.instance.deleteSoilScan(id);
    _loadScans();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Scaffold(
      backgroundColor: c.charcoal,
      appBar: AppBar(
        title: const Text('Soil Analysis History'),
        backgroundColor: c.leaf,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: c.lime))
          : _scans.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _scans.length,
                  itemBuilder: (context, index) {
                    final scan = _scans[index];
                    return _buildScanCard(scan, context);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    // We need context here - let's use a Builder
    return Builder(builder: (ctx) {
      final c = ctx.ac;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: c.cream.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No soil scans saved yet.',
              style: TextStyle(color: c.cream.withOpacity(0.5), fontSize: 16),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildScanCard(Map<String, dynamic> scan, BuildContext context) {
    final c = context.ac;
    final date = DateTime.fromMillisecondsSinceEpoch(scan['timestamp']);
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    
    final imagePath = scan['imagePath'];
    Widget imageWidget;
    if (imagePath != null && imagePath != 'placeholder') {
      final file = File(imagePath);
      if (file.existsSync()) {
        imageWidget = Image.file(file, width: 80, height: 80, fit: BoxFit.cover);
      } else {
        imageWidget = Container(
          width: 80, height: 80, color: Colors.grey.withOpacity(0.3),
          child: const Icon(Icons.broken_image, color: Colors.white54),
        );
      }
    } else {
      imageWidget = Container(
        width: 80, height: 80, color: Colors.grey.withOpacity(0.3),
        child: const Icon(Icons.image_not_supported, color: Colors.white54),
      );
    }

    final isSynced = scan['synced'] == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showScanDetails(scan),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageWidget,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: ${scan['soil_score']?.toStringAsFixed(1) ?? '--'}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: c.lime),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(color: c.cream.withOpacity(0.6), fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(isSynced ? Icons.cloud_done : Icons.cloud_upload_outlined, 
                          size: 14, color: isSynced ? c.lime : Colors.orange),
                        const SizedBox(width: 4),
                        Text(isSynced ? 'Synced' : 'Pending Sync',
                          style: TextStyle(color: isSynced ? c.lime : Colors.orange, fontSize: 12),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _deleteScan(scan['id']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScanDetails(Map<String, dynamic> scan) {
    final imagePath = scan['imagePath'];
    Widget expandedImageWidget;
    if (imagePath != null && imagePath != 'placeholder') {
      final file = File(imagePath);
      if (file.existsSync()) {
        expandedImageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: double.infinity, height: 200, fit: BoxFit.cover),
        );
      } else {
        expandedImageWidget = Container(
          width: double.infinity, height: 150,
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.broken_image, color: Colors.white54, size: 48),
        );
      }
    } else {
      expandedImageWidget = Container(
        width: double.infinity, height: 150,
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 48),
      );
    }

    final c = context.ac;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.charcoal,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final mc = ctx.ac;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Soil Parameters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mc.lime)),
                  Divider(color: mc.leaf.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  expandedImageWidget,
                  const SizedBox(height: 20),
                  _buildDetailRowWithContext(ctx, 'Moisture', '${scan['moisture'] ?? '--'} %'),
                  _buildDetailRowWithContext(ctx, 'Temperature', '${scan['temperature'] ?? '--'} °C'),
                  _buildDetailRowWithContext(ctx, 'EC', '${scan['ec'] ?? '--'} µS/cm'),
                  _buildDetailRowWithContext(ctx, 'pH', '${scan['ph'] ?? '--'}'),
                  _buildDetailRowWithContext(ctx, 'Nitrogen (N)', '${scan['nitrogen'] ?? '--'} mg/kg'),
                  _buildDetailRowWithContext(ctx, 'Phosphorus (P)', '${scan['phosphorus'] ?? '--'} mg/kg'),
                  _buildDetailRowWithContext(ctx, 'Potassium (K)', '${scan['potassium'] ?? '--'} mg/kg'),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Builder(builder: (ctx) {
      final c = ctx.ac;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: c.cream.withOpacity(0.7))),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: c.cream)),
          ],
        ),
      );
    });
  }

  Widget _buildDetailRowWithContext(BuildContext ctx, String label, String value) {
    final c = ctx.ac;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: c.cream.withOpacity(0.7))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: c.cream)),
        ],
      ),
    );
  }
}
