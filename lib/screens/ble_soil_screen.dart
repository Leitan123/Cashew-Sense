// File: lib/screens/ble_soil_screen.dart
//
// Shows:
//  • Available BLE devices list (scan)
//  • Connect to "Soil Sensor BLE"
//  • Real-time NPK + sensor values (updated every notify / 2 s)
//  • TFLite soil-health score

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/soil_model_service.dart';
import '../widgets/common_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

class BleSoilScreen extends StatefulWidget {
  const BleSoilScreen({super.key});

  @override
  State<BleSoilScreen> createState() => _BleSoilScreenState();
}

class _BleSoilScreenState extends State<BleSoilScreen> {
  // ── Services ─────────────────────────────────────────────────────────────
  final SoilModelService _soilModel = SoilModelService();

  // ── BLE state ────────────────────────────────────────────────────────────
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _notifySub;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _dataChar;

  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _modelReady = false;

  // ── Sensor data ──────────────────────────────────────────────────────────
  double? moisture;
  double? temperature;
  int? ec;
  double? ph;
  int? nitrogen;
  int? phosphorus;
  int? potassium;
  double? soilScore;

  String _status = 'Initialising…';

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    try {
      await _soilModel.loadModel();
      setState(() {
        _modelReady = true;
        _status = 'Ready — tap Scan to find your sensor';
      });
    } catch (e) {
      setState(() => _status = 'Model load failed: $e');
    }
  }

  @override
  void dispose() {
    _stopScan();
    _notifySub?.cancel();
    _connectedDevice?.disconnect();
    _soilModel.close();
    super.dispose();
  }

  // ── Scan ─────────────────────────────────────────────────────────────────
  void _startScan() async {
    await Permission.bluetoothScan.request();
  await Permission.bluetoothConnect.request();
  await Permission.locationWhenInUse.request();
    setState(() {
      _scanResults.clear();
      _isScanning = true;
      _status = 'Scanning…';
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      // Deduplicate by device id
      final seen = <String>{};
      final unique = results.where((r) => seen.add(r.device.remoteId.str)).toList();
      setState(() => _scanResults = unique);
    });

    // Auto-stop
    Future.delayed(const Duration(seconds: 9), () {
      if (mounted && _isScanning) _stopScan();
    });
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    if (mounted) setState(() => _isScanning = false);
  }

  // ── Connect ───────────────────────────────────────────────────────────────
  Future<void> _connectTo(BluetoothDevice device) async {
    _stopScan();
    setState(() {
      _isConnecting = true;
      _status = 'Connecting to ${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str}…';
    });

    try {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 10));

      setState(() => _status = 'Discovering services…');
      final services = await device.discoverServices();

      BluetoothCharacteristic? found;
      for (final svc in services) {
        if (svc.uuid.toString().toLowerCase() ==
            '12345678-1234-1234-1234-1234567890ab') {
          for (final ch in svc.characteristics) {
            if (ch.uuid.toString().toLowerCase() ==
                'abcd1234-5678-90ab-cdef-1234567890ab') {
              found = ch;
              break;
            }
          }
        }
      }

      if (found == null) {
        await device.disconnect();
        setState(() {
          _isConnecting = false;
          _status = 'Compatible service not found on this device.';
        });
        return;
      }

      _dataChar = found;
      await found.setNotifyValue(true);
      _notifySub = found.lastValueStream.listen(_onData);

      setState(() {
        _connectedDevice = device;
        _isConnecting = false;
        _status = 'Connected — receiving live data…';
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _status = 'Connection failed: $e';
      });
    }
  }

  // ── Disconnect ────────────────────────────────────────────────────────────
  Future<void> _disconnect() async {
    _notifySub?.cancel();
    await _connectedDevice?.disconnect();
    setState(() {
      _connectedDevice = null;
      _dataChar = null;
      moisture = temperature = ph = soilScore = null;
      ec = nitrogen = phosphorus = potassium = null;
      _status = 'Disconnected. Tap Scan to reconnect.';
    });
  }

  // ── Parse incoming CSV ────────────────────────────────────────────────────
  void _onData(List<int> raw) {
    if (raw.isEmpty) return;
    final csv = utf8.decode(raw);
    final parts = csv.split(',');
    if (parts.length < 7) return;

    double parse(String s) => double.tryParse(s.trim()) ?? 0.0;
    int parseInt(String s) => int.tryParse(s.trim()) ?? 0;

    final m  = parse(parts[0]);
    final t  = parse(parts[1]);
    final e  = parseInt(parts[2]);
    final p  = parse(parts[3]);
    final n  = parseInt(parts[4]);
    final ph2= parseInt(parts[5]);
    final k  = parseInt(parts[6]);

    double? score;
    if (_modelReady) {
      try {
        score = _soilModel.predict(
          f1: m,
          f2: t,
          f3: e.toDouble(),
          ph: p,
          f5: n.toDouble(),
          f6: ph2.toDouble(),
          f7: k.toDouble(),
        );
      } catch (_) {}
    }

    setState(() {
      moisture    = m;
      temperature = t;
      ec          = e;
      ph          = p;
      nitrogen    = n;
      phosphorus  = ph2;
      potassium   = k;
      soilScore   = score;
    });
  }

  // ── UI helpers ────────────────────────────────────────────────────────────
  Color _scoreColor(double s) {
    if (s >= 75) return Colors.green;
    if (s >= 50) return Colors.orange;
    return Colors.red;
  }

  String _scoreLabel(double s) {
    if (s >= 75) return 'Healthy';
    if (s >= 50) return 'Moderate';
    return 'Poor';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCashewAppBar(title: 'NPK Soil Sensor'),
      backgroundColor: const Color(0xFFF5F5DC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusBar(),
            const SizedBox(height: 12),
            if (_connectedDevice == null) ...[
              _buildScanButton(),
              const SizedBox(height: 12),
              if (_scanResults.isNotEmpty) _buildDeviceList(),
            ] else ...[
              _buildConnectedBadge(),
              const SizedBox(height: 16),
              _buildSensorGrid(),
              const SizedBox(height: 16),
              if (soilScore != null) _buildScoreCard(),
              const SizedBox(height: 20),
              _buildDisconnectButton(),
            ],
          ],
        ),
      ),
    );
  }

  // Status banner
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
            child: Text(_status,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
          if (_isScanning || _isConnecting)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  // Scan button
  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isScanning ? _stopScan : _startScan,
        icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching,
            color: Colors.white),
        label: Text(_isScanning ? 'Stop Scan' : 'Scan for Devices',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E3A20),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // Scanned device list
  Widget _buildDeviceList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Text('Available Devices',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const Divider(height: 1),
          ..._scanResults.map((r) {
            final name = r.device.platformName.isNotEmpty
                ? r.device.platformName
                : 'Unknown (${r.device.remoteId.str})';
            final isSoil = r.device.platformName == 'Soil Sensor BLE';
            return ListTile(
              leading: Icon(Icons.bluetooth,
                  color: isSoil ? Colors.green : Colors.grey),
              title: Text(name,
                  style: TextStyle(
                      fontWeight: isSoil
                          ? FontWeight.bold
                          : FontWeight.normal)),
              subtitle: Text('RSSI: ${r.rssi} dBm  •  ${r.device.remoteId.str}',
                  style: const TextStyle(fontSize: 11)),
              trailing: isSoil
                  ? ElevatedButton(
                      onPressed: _isConnecting
                          ? null
                          : () => _connectTo(r.device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Connect',
                          style: TextStyle(color: Colors.white)),
                    )
                  : TextButton(
                      onPressed: _isConnecting
                          ? null
                          : () => _connectTo(r.device),
                      child: const Text('Connect'),
                    ),
            );
          }),
        ],
      ),
    );
  }

  // Connected badge
  Widget _buildConnectedBadge() {
    final name = _connectedDevice?.platformName.isNotEmpty == true
        ? _connectedDevice!.platformName
        : _connectedDevice?.remoteId.str ?? '';
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
            child: Text('Connected to $name',
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          const Icon(Icons.circle, color: Colors.green, size: 10),
          const SizedBox(width: 4),
          const Text('Live', style: TextStyle(color: Colors.green, fontSize: 12)),
        ],
      ),
    );
  }

  // 7-value sensor grid
  Widget _buildSensorGrid() {
    final items = [
      _SensorItem('Moisture', moisture?.toStringAsFixed(1) ?? '--', '%', Icons.water_drop, Colors.blue),
      _SensorItem('Temperature', temperature?.toStringAsFixed(1) ?? '--', '°C', Icons.thermostat, Colors.orange),
      _SensorItem('EC', ec?.toString() ?? '--', 'µS/cm', Icons.electric_bolt, Colors.purple),
      _SensorItem('pH', ph?.toStringAsFixed(1) ?? '--', '', Icons.science, Colors.teal),
      _SensorItem('Nitrogen', nitrogen?.toString() ?? '--', 'mg/kg', Icons.grass, Colors.green),
      _SensorItem('Phosphorus', phosphorus?.toString() ?? '--', 'mg/kg', Icons.bubble_chart, Colors.amber.shade700),
      _SensorItem('Potassium', potassium?.toString() ?? '--', 'mg/kg', Icons.grain, Colors.red.shade400),
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

  Widget _buildSensorCard(_SensorItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(item.icon, color: item.color, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(item.label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.value,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: item.color)),
              const SizedBox(width: 4),
              if (item.unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(item.unit,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Score card
  Widget _buildScoreCard() {
    final score = soilScore!;
    final color = _scoreColor(score);
    final label = _scoreLabel(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text('Soil Health Score',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text(score.toStringAsFixed(1),
              style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: color)),
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
        ],
      ),
    );
  }

  // Disconnect button
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

// ── Data class ─────────────────────────────────────────────────────────────
class _SensorItem {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  const _SensorItem(this.label, this.value, this.unit, this.icon, this.color);
}