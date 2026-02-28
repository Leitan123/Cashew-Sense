// File: lib/screens/ble_soil_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/soil_model_service.dart';
import '../widgets/common_widgets.dart';
import 'fertilizer_screen.dart';

class BleSoilScreen extends StatefulWidget {
  const BleSoilScreen({super.key});

  @override
  State<BleSoilScreen> createState() => _BleSoilScreenState();
}

class _BleSoilScreenState extends State<BleSoilScreen> {
  final SoilModelService _soilModel = SoilModelService();

  // BLE
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _soilCharacteristic;

  // Parsed sensor values
  double? moisture;
  double? temperature;
  int?    ec;
  double? ph;
  int?    nitrogen;
  int?    phosphorus;
  int?    potassium;
  double? _soilScore;

  bool   _connecting = false;
  String _statusMessage = 'Press button to scan for sensor';

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    try {
      await _soilModel.loadModel();
      setState(() => _statusMessage = 'Model loaded. Ready to scan.');
    } catch (e) {
      setState(() => _statusMessage = 'Model load failed. Tap to retry.');
    }
  }

  // ── Scan ──────────────────────────────────────────────────────────────────
  void _startScan() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();

    setState(() {
      _connecting = true;
      _statusMessage = 'Scanning for Soil Sensor BLE...';
    });

    _scanSubscription?.cancel();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        if (r.device.platformName == 'Soil Sensor BLE') {
          FlutterBluePlus.stopScan();
          _scanSubscription?.cancel();
          await _connectToDevice(r.device);
          return;
        }
      }
    });

    Future.delayed(const Duration(seconds: 9), () {
      if (mounted && _connecting && _device == null) {
        FlutterBluePlus.stopScan();
        _scanSubscription?.cancel();
        setState(() {
          _connecting = false;
          _statusMessage = 'Device not found. Tap to retry.';
        });
      }
    });
  }

  // ── Connect ───────────────────────────────────────────────────────────────
  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _device = device;
      _statusMessage = 'Connecting to ${device.platformName}...';
    });

    try {
      await device.connect(autoConnect: false);
      setState(() => _statusMessage = 'Discovering services...');

      final services = await device.discoverServices();
      bool found = false;

      for (var svc in services) {
        if (svc.uuid.toString().toLowerCase() ==
            '12345678-1234-1234-1234-1234567890ab') {
          for (var ch in svc.characteristics) {
            if (ch.uuid.toString().toLowerCase() ==
                'abcd1234-5678-90ab-cdef-1234567890ab') {
              _soilCharacteristic = ch;
              await ch.setNotifyValue(true);
              _notifySubscription = ch.lastValueStream.listen(_onDataReceived);
              found = true;
              setState(() => _statusMessage = 'Connected! Receiving live data...');
              break;
            }
          }
        }
      }

      if (!found) {
        await device.disconnect();
        setState(() {
          _device = null;
          _statusMessage = 'Service not found. Try again.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Connection failed. Tap to retry.';
        _device = null;
      });
    } finally {
      setState(() => _connecting = false);
    }
  }

  // ── Parse incoming CSV: moisture,temperature,ec,ph,nitrogen,phosphorus,potassium
  void _onDataReceived(List<int> raw) {
    if (raw.isEmpty) return;
    final csv   = utf8.decode(raw);
    final parts = csv.split(',');
    if (parts.length < 7) return;

    double tryDouble(String s) => double.tryParse(s.trim()) ?? 0.0;
    int    tryInt(String s)    => int.tryParse(s.trim())    ?? 0;

    final m  = tryDouble(parts[0]);
    final t  = tryDouble(parts[1]);
    final e  = tryInt(parts[2]);
    final p  = tryDouble(parts[3]);
    final n  = tryInt(parts[4]);
    final ph2= tryInt(parts[5]);
    final k  = tryInt(parts[6]);

    double? score;
    try {
      score = _soilModel.predict(
        f1: m, f2: t, f3: e.toDouble(),
        ph: p, f5: n.toDouble(), f6: ph2.toDouble(), f7: k.toDouble(),
      );
    } catch (_) {}

    setState(() {
      moisture    = m;
      temperature = t;
      ec          = e;
      ph          = p;
      nitrogen    = n;
      phosphorus  = ph2;
      potassium   = k;
      _soilScore  = score;
    });
  }

  // ── Disconnect ────────────────────────────────────────────────────────────
  Future<void> _disconnect() async {
    _notifySubscription?.cancel();
    await _device?.disconnect();
    setState(() {
      _device        = null;
      _soilCharacteristic = null;
      moisture = temperature = ph = _soilScore = null;
      ec = nitrogen = phosphorus = potassium = null;
      _statusMessage = 'Disconnected. Tap to scan again.';
    });
  }

  // ── Navigate to Fertilizer screen with all NPK values ────────────────────
  void _goToFertilizerAdvisor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FertilizerScreen(
          moisture:    moisture,
          temperature: temperature,
          ec:          ec,
          ph:          ph,
          nitrogen:    nitrogen,
          phosphorus:  phosphorus,
          potassium:   potassium,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _notifySubscription?.cancel();
    _device?.disconnect();
    _soilModel.close();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCashewAppBar(title: 'NPK Soil Sensor'),
      backgroundColor: const Color(0xFFF5F5DC),
      body: _connecting
          ? _buildLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatusBar(),
                  const SizedBox(height: 12),
                  if (_device == null) _buildScanButton(),
                  if (_device != null) ...[
                    _buildConnectedBadge(),
                    const SizedBox(height: 16),
                    _buildSensorGrid(),
                    const SizedBox(height: 16),
                    if (_soilScore != null) _buildScoreCard(),
                    const SizedBox(height: 16),
                    // ── Fertilizer Advisor Button ──────────────────────────
                    if (nitrogen != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _goToFertilizerAdvisor,
                          icon: const Icon(Icons.agriculture, color: Colors.white),
                          label: const Text(
                            'Get Fertilizer Advice',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _buildDisconnectButton(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF2E3A20)),
          const SizedBox(height: 20),
          Text(_statusMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_statusMessage,
                  style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _startScan,
        icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
        label: const Text('Scan for Soil Sensor BLE',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E3A20),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildConnectedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_connected, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connected: ${_device?.platformName ?? ''}',
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.circle, color: Colors.green, size: 10),
          const SizedBox(width: 4),
          const Text('Live',
              style: TextStyle(color: Colors.green, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSensorGrid() {
    final items = [
      _SItem('Moisture',    moisture?.toStringAsFixed(1) ?? '--',    '%',      Icons.water_drop,    Colors.blue),
      _SItem('Temperature', temperature?.toStringAsFixed(1) ?? '--', '°C',     Icons.thermostat,    Colors.orange),
      _SItem('EC',          ec?.toString() ?? '--',                  'µS/cm',  Icons.electric_bolt, Colors.purple),
      _SItem('pH',          ph?.toStringAsFixed(1) ?? '--',          '',       Icons.science,       Colors.teal),
      _SItem('Nitrogen',    nitrogen?.toString() ?? '--',            'mg/kg',  Icons.grass,         Colors.green),
      _SItem('Phosphorus',  phosphorus?.toString() ?? '--',          'mg/kg',  Icons.bubble_chart,  Colors.amber.shade700),
      _SItem('Potassium',   potassium?.toString() ?? '--',           'mg/kg',  Icons.grain,         Colors.red.shade400),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildSensorCard(items[i]),
    );
  }

  Widget _buildSensorCard(_SItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(item.icon, color: item.color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(item.label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: item.color)),
              const SizedBox(width: 3),
              if (item.unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(item.unit,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final score = _soilScore!;
    final color = score >= 75
        ? Colors.green
        : score >= 50
            ? Colors.orange
            : Colors.red;
    final label = score >= 75
        ? 'Healthy'
        : score >= 50
            ? 'Moderate'
            : 'Poor';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(children: [
        Text('Soil Health Score',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        Text(score.toStringAsFixed(1),
            style: TextStyle(
                fontSize: 52, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
      ]),
    );
  }

  Widget _buildDisconnectButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _disconnect,
        icon: const Icon(Icons.bluetooth_disabled, color: Colors.red),
        label: const Text('Disconnect',
            style: TextStyle(color: Colors.red, fontSize: 15)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _SItem {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _SItem(this.label, this.value, this.unit, this.icon, this.color);
}