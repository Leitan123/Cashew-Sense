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

class _BleSoilScreenState extends State<BleSoilScreen>
    with SingleTickerProviderStateMixin {
  final SoilModelService _soilModel = SoilModelService();
  TabController? _tabController;

  // BLE
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _soilCharacteristic;

  // Scanned soil sensors found
  List<ScanResult> _foundSensors = [];
  bool _isScanningSoil = false;

  // All nearby devices
  List<ScanResult> _allDevices = [];
  bool _isScanning = false;

  // Parsed sensor values
  double? moisture;
  double? temperature;
  int? ec;
  double? ph;
  int? nitrogen;
  int? phosphorus;
  int? potassium;
  double? _soilScore;

  bool _connecting = false;
  String _statusMessage = 'Tap below to scan for your soil sensor';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initModel();
  }

  Future<void> _initModel() async {
    try {
      await _soilModel.loadModel();
      setState(() => _statusMessage = 'Model loaded. Tap below to scan.');
    } catch (e) {
      setState(() => _statusMessage = 'Model load failed. Tap to retry.');
    }
  }

  // ── Request Permissions ───────────────────────────────────────────────────
  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();
  }

  // ── Scan for "Soil Sensor BLE" and show results ──────────────────────────
  void _startSoilScan() async {
    await _requestPermissions();

    setState(() {
      _foundSensors.clear();
      _isScanningSoil = true;
      _statusMessage = 'Scanning for Soil Sensor BLE...';
    });

    _scanSubscription?.cancel();

    // Listen and collect only "Soil Sensor BLE" devices
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final sensors = results
          .where((r) => r.device.platformName == 'Soil Sensor BLE')
          .toList();
      setState(() => _foundSensors = sensors);
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      withServices: [],
    );

    setState(() {
      _isScanningSoil = false;
      _statusMessage = _foundSensors.isEmpty
          ? 'No sensor found. Tap to retry.'
          : 'Found ${_foundSensors.length} sensor(s). Tap Connect.';
    });
  }

  // ── Scan ALL nearby devices ───────────────────────────────────────────────
  void _scanAllDevices() async {
    await _requestPermissions();

    setState(() {
      _allDevices.clear();
      _isScanning = true;
    });

    _scanSubscription?.cancel();

    FlutterBluePlus.scanResults.listen((results) {
      setState(() => _allDevices = results);
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      withServices: [],
    );

    setState(() => _isScanning = false);
  }

  // ── Connect to selected device ────────────────────────────────────────────
  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _connecting = true;
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
              setState(() {
                _foundSensors.clear();
                _statusMessage = 'Connected! Receiving live data...';
              });
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

  // ── Parse incoming CSV ────────────────────────────────────────────────────
  void _onDataReceived(List<int> raw) {
    if (raw.isEmpty) return;
    final csv = utf8.decode(raw);
    final parts = csv.split(',');
    if (parts.length < 7) return;

    double tryDouble(String s) => double.tryParse(s.trim()) ?? 0.0;
    int tryInt(String s) => int.tryParse(s.trim()) ?? 0;

    final m = tryDouble(parts[0]);
    final t = tryDouble(parts[1]);
    final e = tryInt(parts[2]);
    final p = tryDouble(parts[3]);
    final n = tryInt(parts[4]);
    final ph2 = tryInt(parts[5]);
    final k = tryInt(parts[6]);

    double? score;
    try {
      score = _soilModel.predict(
        f1: m, f2: t, f3: e.toDouble(),
        ph: p, f5: n.toDouble(), f6: ph2.toDouble(), f7: k.toDouble(),
      );
    } catch (_) {}

    setState(() {
      moisture = m;
      temperature = t;
      ec = e;
      ph = p;
      nitrogen = n;
      phosphorus = ph2;
      potassium = k;
      _soilScore = score;
    });
  }

  // ── Disconnect ────────────────────────────────────────────────────────────
  Future<void> _disconnect() async {
    _notifySubscription?.cancel();
    await _device?.disconnect();
    setState(() {
      _device = null;
      _soilCharacteristic = null;
      moisture = temperature = ph = _soilScore = null;
      ec = nitrogen = phosphorus = potassium = null;
      _foundSensors.clear();
      _statusMessage = 'Disconnected. Tap to scan again.';
    });
  }

  void _goToFertilizerAdvisor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FertilizerScreen(
          moisture: moisture,
          temperature: temperature,
          ec: ec,
          ph: ph,
          nitrogen: nitrogen,
          phosphorus: phosphorus,
          potassium: potassium,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
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
      appBar: AppBar(
        title: const Text('NPK Soil Sensor'),
        backgroundColor: const Color(0xFF2E3A20),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController!,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.sensors), text: 'Soil Sensor'),
            Tab(icon: Icon(Icons.bluetooth_searching), text: 'Nearby Devices'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF5F5DC),
      body: TabBarView(
        controller: _tabController!,
        children: [
          _buildSoilSensorTab(),
          _buildNearbyDevicesTab(),
        ],
      ),
    );
  }

  // ── TAB 1: Soil Sensor ────────────────────────────────────────────────────
  Widget _buildSoilSensorTab() {
    if (_connecting) return _buildLoading();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusBar(),
          const SizedBox(height: 16),

          // ── Not connected ──
          if (_device == null) ...[

            // Hero icon
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20)
                  ],
                ),
                child: Icon(
                  _isScanningSoil
                      ? Icons.bluetooth_searching
                      : Icons.bluetooth,
                  size: 64,
                  color: const Color(0xFF2E3A20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isScanningSoil
                  ? 'Searching for Soil Sensor BLE...'
                  : 'Soil Sensor Not Connected',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3A20)),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan to find your ESP32 soil sensor\nand tap Connect to pair it',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // Scan button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanningSoil ? null : _startSoilScan,
                icon: _isScanningSoil
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.bluetooth_searching,
                        color: Colors.white),
                label: Text(
                  _isScanningSoil ? 'Scanning...' : 'Scan for Soil Sensor',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanningSoil
                      ? Colors.grey
                      : const Color(0xFF2E3A20),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Found sensors list with Connect buttons ──
            if (_foundSensors.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Found Devices',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 8),
              ...(_foundSensors.map((result) {
                final rssi = result.rssi;
                final signalColor = rssi >= -60
                    ? Colors.green
                    : rssi >= -80
                        ? Colors.orange
                        : Colors.red;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.green.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              const Color(0xFF2E3A20).withOpacity(0.1),
                          child: const Icon(Icons.sensors,
                              color: Color(0xFF2E3A20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.device.platformName.isNotEmpty
                                    ? result.device.platformName
                                    : 'Unknown Device',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${result.device.remoteId}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500),
                              ),
                              Row(children: [
                                Icon(Icons.signal_cellular_alt,
                                    size: 13, color: signalColor),
                                const SizedBox(width: 3),
                                Text('$rssi dBm',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: signalColor)),
                              ]),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _connectToDevice(result.device),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Connect',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              })),
            ],

            // Tips box
            if (_foundSensors.isEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.tips_and_updates,
                          size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 6),
                      Text('Before connecting',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700)),
                    ]),
                    const SizedBox(height: 8),
                    _buildTip('Make sure ESP32 sensor is powered on'),
                    _buildTip('Keep sensor within 10 meters'),
                    _buildTip('Enable Bluetooth and Location'),
                    _buildTip('ESP32 device name must be "Soil Sensor BLE"'),
                  ],
                ),
              ),
            ],
          ],

          // ── Connected: show sensor data ──
          if (_device != null) ...[
            _buildConnectedBadge(),
            const SizedBox(height: 16),
            _buildSensorGrid(),
            const SizedBox(height: 16),
            if (_soilScore != null) _buildScoreCard(),
            const SizedBox(height: 16),
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
    );
  }

  // ── TAB 2: Nearby Devices ─────────────────────────────────────────────────
  Widget _buildNearbyDevicesTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: _isScanning ? Colors.blue.shade50 : Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Text(
            _isScanning
                ? '🔍 Scanning for all nearby devices...'
                : '✅ Found ${_allDevices.length} device(s)',
            style: TextStyle(
              color:
                  _isScanning ? Colors.blue.shade700 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: _allDevices.isEmpty
              ? Center(
                  child: _isScanning
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                                color: Color(0xFF2E3A20)),
                            const SizedBox(height: 16),
                            Text('Looking for nearby devices...',
                                style:
                                    TextStyle(color: Colors.grey.shade600)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth_disabled,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No devices found',
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Scan All" to discover\nnearby Bluetooth devices',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                )
              : ListView.builder(
                  itemCount: _allDevices.length,
                  itemBuilder: (context, index) {
                    final result = _allDevices[index];
                    final name = result.device.platformName.isNotEmpty
                        ? result.device.platformName
                        : 'Unknown Device';
                    final rssi = result.rssi;
                    final signalColor = rssi >= -60
                        ? Colors.green
                        : rssi >= -80
                            ? Colors.orange
                            : Colors.red;
                    final signalLabel = rssi >= -60
                        ? 'Strong'
                        : rssi >= -80
                            ? 'Medium'
                            : 'Weak';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF2E3A20).withOpacity(0.1),
                          child: const Icon(Icons.bluetooth,
                              color: Color(0xFF2E3A20)),
                        ),
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${result.device.remoteId}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600)),
                            Row(children: [
                              Icon(Icons.signal_cellular_alt,
                                  size: 14, color: signalColor),
                              const SizedBox(width: 4),
                              Text('$rssi dBm ($signalLabel)',
                                  style: TextStyle(
                                      fontSize: 11, color: signalColor)),
                            ]),
                          ],
                        ),
                        trailing: result.device.platformName.isNotEmpty
                            ? const Icon(Icons.circle,
                                color: Colors.green, size: 10)
                            : const Icon(Icons.circle,
                                color: Colors.grey, size: 10),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _scanAllDevices,
              icon: Icon(
                  _isScanning
                      ? Icons.hourglass_top
                      : Icons.bluetooth_searching,
                  color: Colors.white),
              label: Text(
                _isScanning ? 'Scanning...' : 'Scan All Nearby Devices',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isScanning ? Colors.grey : const Color(0xFF2E3A20),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Reusable Widgets ──────────────────────────────────────────────────────
  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 14, color: Colors.amber.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, color: Colors.amber.shade800)),
          ),
        ],
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
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black87))),
        ],
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
      _SItem('Moisture', moisture?.toStringAsFixed(1) ?? '--', '%',
          Icons.water_drop, Colors.blue),
      _SItem('Temperature', temperature?.toStringAsFixed(1) ?? '--',
          '°C', Icons.thermostat, Colors.orange),
      _SItem('EC', ec?.toString() ?? '--', 'µS/cm',
          Icons.electric_bolt, Colors.purple),
      _SItem('pH', ph?.toStringAsFixed(1) ?? '--', '', Icons.science,
          Colors.teal),
      _SItem('Nitrogen', nitrogen?.toString() ?? '--', 'mg/kg',
          Icons.grass, Colors.green),
      _SItem('Phosphorus', phosphorus?.toString() ?? '--', 'mg/kg',
          Icons.bubble_chart, Colors.amber.shade700),
      _SItem('Potassium', potassium?.toString() ?? '--', 'mg/kg',
          Icons.grain, Colors.red.shade400),
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
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 6)
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
    final label =
        score >= 75 ? 'Healthy' : score >= 50 ? 'Moderate' : 'Poor';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withOpacity(0.15),
          color.withOpacity(0.05)
        ]),
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
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: color)),
        const SizedBox(height: 4),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
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