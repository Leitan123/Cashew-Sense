// File: lib/screens/ble_soil_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/soil_model_service.dart';
import '../widgets/common_widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleSoilScreen extends StatefulWidget {
  const BleSoilScreen({super.key});

  @override
  State<BleSoilScreen> createState() => _BleSoilScreenState();
}

class _BleSoilScreenState extends State<BleSoilScreen> {
  final SoilModelService _soilModel = SoilModelService();

  // BLE
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _soilCharacteristic;

  // Data
  String _rawData = '';
  double? _soilScore;
  bool _connecting = false;
  String _statusMessage = 'Press button to scan for sensor';

  @override
  void initState() {
    super.initState();
    _initModelAndScan();
  }

  Future<void> _initModelAndScan() async {
    try {
      await _soilModel.loadModel();
      print("✅ Soil model loaded");
      setState(() => _statusMessage = 'Model loaded. Ready to scan.');
    } catch (e) {
      print("❌ Soil model load failed: $e");
      setState(() => _statusMessage = 'Model load failed. Tap to retry.');
    }
  }

  void _startScan() {
    setState(() {
      _connecting = true;
      _statusMessage = 'Scanning for Soil Sensor BLE...';
    });

    _scanSubscription?.cancel();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        if (r.device.name == "Soil Sensor BLE") {
          FlutterBluePlus.stopScan();
          await _connectToDevice(r.device);
          return;
        }
      }
    });

    // Timeout handling
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _connecting && _device == null) {
        FlutterBluePlus.stopScan();
        _scanSubscription?.cancel();
        setState(() {
          _connecting = false;
          _statusMessage = 'Device not found. Tap to retry.';
        });
        print("⚠️ Scan timeout - device not found");
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _device = device;
      _statusMessage = 'Connecting to ${device.name}...';
    });

    try {
      await device.connect(autoConnect: false);
      print("✅ Connected to ${device.name}");

      setState(() => _statusMessage = 'Discovering services...');
      List<BluetoothService> services = await device.discoverServices();
      bool foundCharacteristic = false;

      for (var service in services) {
        if (service.uuid.toString() == "12345678-1234-1234-1234-1234567890ab") {
          for (var char in service.characteristics) {
            if (char.uuid.toString() == "abcd1234-5678-90ab-cdef-1234567890ab") {
              _soilCharacteristic = char;

              // Enable notifications
              await char.setNotifyValue(true);
              char.value.listen(_onDataReceived);

              foundCharacteristic = true;
              setState(() => _statusMessage = 'Connected! Waiting for data...');
              print("✅ Subscribed to soil data notifications");
              break;
            }
          }
        }
      }

      if (!foundCharacteristic) {
        setState(() => _statusMessage = 'Service not found. Disconnecting...');
        await device.disconnect();
        _device = null;
      }
    } catch (e) {
      print("❌ Connection failed: $e");
      setState(() => _statusMessage = 'Connection failed. Tap to retry.');
      _device = null;
    } finally {
      setState(() => _connecting = false);
    }
  }

  // Notification listener
  void _onDataReceived(List<int> value) {
    final csv = utf8.decode(value);
    setState(() => _rawData = csv);
  }

  // ✅ Read latest value on button click
  Future<void> _readCurrentData() async {
    if (_soilCharacteristic == null) return;

    try {
      List<int> value = await _soilCharacteristic!.read();
      final csv = utf8.decode(value);

      final parts = csv.split(',');
      List<double> parsed = parts.map((p) {
        try {
          return double.parse(p);
        } catch (_) {
          return 0.0;
        }
      }).toList();

      // Fill missing values for model
      double f1 = parsed.length > 0 ? parsed[0] : 0.0;
      double f2 = parsed.length > 1 ? parsed[1] : 0.0;
      double f3 = parsed.length > 2 ? parsed[2] : 0.0;
      double ph = parsed.length > 3 ? parsed[3] : 0.0;
      double f5 = parsed.length > 4 ? parsed[4] : 0.0;
      double f6 = parsed.length > 5 ? parsed[5] : 0.0;
      double f7 = parsed.length > 6 ? parsed[6] : 0.0;

      double result = _soilModel.predict(
        f1: f1, f2: f2, f3: f3, ph: ph, f5: f5, f6: f6, f7: f7,
      );

      setState(() {
        _soilScore = result;
        _rawData = parts.join(',');
        _statusMessage = 'Soil data updated';
      });

      print("📊 Soil Health Score: $result");
      print("Raw CSV: $csv");
    } catch (e) {
      print("❌ Error reading BLE data: $e");
      setState(() => _statusMessage = 'Read failed');
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _device?.disconnect();
    _soilModel.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCashewAppBar(title: 'Soil Health BLE'),
      backgroundColor: const Color(0xFFF5F5DC),
      body: Center(
        child: _connecting
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.thermostat, size: 100, color: Colors.brown),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (_device != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bluetooth_connected,
                                color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Connected: ${_device!.name}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (_rawData.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Raw Sensor Data:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _rawData,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 30),
                    Text(
                      _soilScore != null
                          ? 'Soil Health Score: ${_soilScore!.toStringAsFixed(2)}'
                          : 'Soil Health Score: --',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _soilScore != null ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              _device == null ? _startScan : _readCurrentData,
                          icon: Icon(
                              _device == null
                                  ? Icons.bluetooth_searching
                                  : Icons.refresh,
                              color: Colors.white),
                          label: Text(
                              _device == null
                                  ? 'Scan for Soil Sensor'
                                  : 'Read Current Data',
                              style: const TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            backgroundColor: Colors.brown,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (_device != null)
                          TextButton.icon(
                            onPressed: () async {
                              await _device?.disconnect();
                              setState(() {
                                _device = null;
                                _soilScore = null;
                                _rawData = '';
                                _statusMessage =
                                    'Disconnected. Tap to scan again.';
                              });
                            },
                            icon: const Icon(Icons.bluetooth_disabled,
                                color: Colors.red),
                            label: const Text(
                              'Disconnect',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
