import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  static const String _loggedInUserIdKey = 'logged_in_user_id';
  static const String _lastLogOutPhoneKey = 'last_log_out_phone';

  int? _currentUserId;
  Map<String, dynamic>? _currentUserData;

  /// Call this during app startup to load session
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt(_loggedInUserIdKey);
    if (_currentUserId != null) {
      _currentUserData = await DatabaseService.instance.getUserById(_currentUserId!);
      if (_currentUserData == null) {
        // User not found in DB but ID was saved (edge case)
        await logout();
      }
    }
  }

  bool get isLoggedIn => _currentUserId != null;
  int? get currentUserId => _currentUserId;
  Map<String, dynamic>? get currentUserData => _currentUserData;

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Register works offline normally, but requires internet if employeeCode is provided
  Future<bool> register({
    required String name,
    required String phone,
    required String pin,
    required String district,
    required double farmSize,
    String? employeeCode,
  }) async {
    try {
      if (employeeCode != null && employeeCode.trim().isNotEmpty) {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.contains(ConnectivityResult.none)) {
          throw Exception('Internet connection is required to register with an Employee Code.');
        }

        final String verifyUrl = 'https://powderblue-salamander-482455.hostingersite.com/api/verify-employee-code';
        final verifyRes = await http.post(
          Uri.parse(verifyUrl),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({'employee_code': employeeCode.trim()}),
        );

        if (verifyRes.statusCode != 200) {
          final body = jsonDecode(verifyRes.body);
          throw Exception(body['error'] ?? 'Invalid Employee Code.');
        }
      }

      // Check if phone already exists
      final existingUser = await DatabaseService.instance.getUserByPhone(phone);
      if (existingUser != null) {
        throw Exception('Phone number already registered on this device.');
      }

      final pinHash = _hashPin(pin);
      
      final userMap = {
        'name': name,
        'phone': phone,
        'pin_hash': pinHash,
        'district': district,
        'farm_size': farmSize,
        'employee_code': employeeCode?.trim(),
        'synced': 0,
      };

      final userId = await DatabaseService.instance.insertUser(userMap);
      
      // Auto login
      await _setLoggedIn(userId);
      
      // Attempt to sync immediately if internet is present
      syncData();
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Login requires internet. Validates via API and syncs DB.
  Future<bool> login({required String phone, required String pin}) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw Exception('Internet connection is required to login.');
    }

    final pinHash = _hashPin(pin);
    final String loginUrl = 'https://powderblue-salamander-482455.hostingersite.com/api/login';

    final response = await http.post(
      Uri.parse(loginUrl),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'pin_hash': pinHash,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Login failed. Please check credentials.');
    }

    final data = jsonDecode(response.body);
    final user = data['user'];
    final leafScans = data['leaf_scans'] as List;
    final pestScans = data['pest_scans'] as List;
    final soilScans = data['soil_scans'] as List? ?? [];

    final db = DatabaseService.instance;

    // 1. Insert or update user locally
    Map<String, dynamic>? localUser = await db.getUserByPhone(phone);
    int localUserId;
    if (localUser != null) {
      localUserId = localUser['id'];
    } else {
      localUserId = await db.insertUser({
        'name': user['name'],
        'phone': user['phone'],
        'pin_hash': pinHash,
        'district': user['district'],
        'farm_size': user['farm_size'],
        'employee_code': user['employee_code'],
        'synced': 1,
      });
    }

    // Login local session
    await _setLoggedIn(localUserId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLogOutPhoneKey, phone);

    // 2. Sync Scans from Cloud
    await _downloadAndSaveScans(localUserId, leafScans, type: 'leaf');
    await _downloadAndSaveScans(localUserId, pestScans, type: 'pest');
    await _downloadAndSaveScans(localUserId, soilScans, type: 'soil');

    // Sync any pending local data up to cloud just in case
    syncData();

    return true;
  }

  Future<void> _downloadAndSaveScans(int userId, List scans, {String type = 'leaf'}) async {
    final db = DatabaseService.instance;
    final appDir = await getApplicationDocumentsDirectory();

    for (var scan in scans) {
      // Find matching timestamp
      List<Map<String, dynamic>> existingScans;
      if (type == 'leaf') {
        existingScans = await db.getScans(userId, limit: 1000);
      } else if (type == 'pest') {
        existingScans = await db.getPestScans(userId, limit: 1000);
      } else {
        existingScans = await db.getSoilScans(userId, limit: 1000);
      }

      bool existsLocally = existingScans.any((s) => s['timestamp'] == scan['timestamp']);

      if (!existsLocally) {
        // Download Image
        String localImagePath = '';
        final remoteUrl = scan['imagePath'];
        if (remoteUrl != null && remoteUrl.toString().startsWith('http')) {
          try {
            final imgResponse = await http.get(Uri.parse(remoteUrl));
            if (imgResponse.statusCode == 200) {
              final fileName = '${type}_${scan['timestamp']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final file = File('${appDir.path}/$fileName');
              await file.writeAsBytes(imgResponse.bodyBytes);
              localImagePath = file.path;
            }
          } catch (e) {
            print('Error downloading image: $e');
            localImagePath = 'placeholder';
          }
        } else {
           localImagePath = 'placeholder';
        }

        // Insert to DB
        if (type == 'leaf') {
          await db.insertScan(userId, localImagePath, scan['diseaseName']);
        } else if (type == 'pest') {
          await db.insertPestScan(userId, localImagePath, scan['pestName']);
        } else {
          await db.insertSoilScan({
            'user_id': userId,
            'imagePath': localImagePath,
            'moisture': scan['moisture'],
            'temperature': scan['temperature'],
            'ec': scan['ec'],
            'ph': scan['ph'],
            'nitrogen': scan['nitrogen'],
            'phosphorus': scan['phosphorus'],
            'potassium': scan['potassium'],
            'soil_score': scan['soil_score'],
            'timestamp': scan['timestamp'],
            'synced': 1,
          });
        }
      }
    }
  }

  Future<void> logout() async {
    if (_currentUserData != null) {
      final phone = _currentUserData!['phone'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastLogOutPhoneKey, phone);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInUserIdKey);
    
    _currentUserId = null;
    _currentUserData = null;
  }

  Future<void> _setLoggedIn(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loggedInUserIdKey, userId);
    _currentUserId = userId;
    _currentUserData = await DatabaseService.instance.getUserById(userId);
  }

  /// Sync data to the cloud
  Future<void> syncData() async {
    print("AuthService: Starting background sync...");
    
    // Using live hosted API endpoint
    final String apiUrl = 'https://powderblue-salamander-482455.hostingersite.com/api/sync';

    try {
      final db = DatabaseService.instance;

      // 1. Get unsynced users
      final rawUnsyncedUsersList = await db.getUnsyncedUsers();

      // Make sure we carry over the employee_code because db returns what's exactly in the schema
      final unsyncedUsersList = rawUnsyncedUsersList.map((user) => {
        ...user,
        'employee_code': user['employee_code'],
      }).toList();

      if (unsyncedUsersList.isEmpty && _currentUserId == null) {
         print("AuthService: Nothing to sync or no user logged in.");
         return;
      }

      // Collect data to send
      Map<String, dynamic> payload = {
        'users': unsyncedUsersList,
      };

      if (_currentUserId != null) {
        final leafScans = await db.getScans(_currentUserId!, limit: 100);
        final pestScans = await db.getPestScans(_currentUserId!, limit: 100);
        
        final userPhone = _currentUserData!['phone'];
        
        Future<List<Map<String, dynamic>>> prepareScans(List<Map<String, dynamic>> localScans) async {
          List<Map<String, dynamic>> prepared = [];
          for (var scan in localScans) {
            String? base64Image;
            try {
              final file = File(scan['imagePath']);
              if (await file.exists()) {
                final bytes = await file.readAsBytes();
                base64Image = base64Encode(bytes);
              }
            } catch (e) {
              print("AuthService: Could not read image for scan");
            }
            
            prepared.add({
              ...scan,
              'user_phone': userPhone,
              'imageBase64': base64Image,
            });
          }
          return prepared;
        }

        payload['leaf_scans'] = await prepareScans(leafScans);
        payload['pest_scans'] = await prepareScans(pestScans);
      }

      // 4. Get unsynced soil scans
      final unsyncedSoilScans = await db.getUnsyncedSoilScans();
      final List<Map<String, dynamic>> soilScansPayload = [];
      
      for (var scan in unsyncedSoilScans) {
        String base64Image = '';
        if (scan['imagePath'] != 'placeholder') {
          final file = File(scan['imagePath']);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            base64Image = base64Encode(bytes);
          }
        }
        
        // Ensure user is looked up correctly
        final user = await db.getUserById(scan['user_id']);
        if (user != null) {
          soilScansPayload.add({
            'user_phone': user['phone'],
            'moisture': scan['moisture'],
            'temperature': scan['temperature'],
            'ec': scan['ec'],
            'ph': scan['ph'],
            'nitrogen': scan['nitrogen'],
            'phosphorus': scan['phosphorus'],
            'potassium': scan['potassium'],
            'soil_score': scan['soil_score'],
            'timestamp': scan['timestamp'],
            'imageBase64': base64Image,
          });
        }
      }

      payload['soil_scans'] = soilScansPayload;

      // 5. Get unsynced nut scans
      final unsyncedNutScans = await db.getUnsyncedNutScans();
      final List<Map<String, dynamic>> nutScansPayload = [];
      
      for (var scan in unsyncedNutScans) {
        String base64Image = '';
        if (scan['imagePath'] != 'placeholder') {
          final file = File(scan['imagePath']);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            base64Image = base64Encode(bytes);
          }
        }
        
        final user = await db.getUserById(scan['user_id']);
        if (user != null) {
          nutScansPayload.add({
            'user_phone': user['phone'],
            'predicted_class': scan['predicted_class'],
            'weight': scan['weight'],
            'final_grade': scan['final_grade'],
            'timestamp': scan['timestamp'],
            'imageBase64': base64Image,
          });
        }
      }

      payload['nut_scans'] = nutScansPayload;

      // Ensure we have something
      if (unsyncedUsersList.isEmpty && 
          (payload['leaf_scans'] == null || payload['leaf_scans'].isEmpty) && 
          (payload['pest_scans'] == null || payload['pest_scans'].isEmpty) && 
          soilScansPayload.isEmpty && 
          nutScansPayload.isEmpty) {
        print("AuthService: No new data to sync to cloud.");
        return; // Nothing to sync
      }

      print("AuthService: Sending sync payload: ${jsonEncode(payload).substring(0, 100)}...");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        // Mark as synced locally
        for (var u in unsyncedUsersList) {
          await db.markUserSynced(u['id']);
        }
        for (var s in unsyncedSoilScans) {
          await db.markSoilScanSynced(s['id']);
        }
        for (var s in unsyncedNutScans) {
          await db.markNutScanSynced(s['id']);
        }
        
        print("AuthService: Background sync completed successfully.");
      } else {
        print("AuthService: Sync failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("AuthService: Sync error: $e");
    }
  }

  /// Starts listening to connectivity changes and syncs if internet is restored
  void setupAutoSync() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!results.contains(ConnectivityResult.none)) {
        // Internet is available
        if (isLoggedIn) {
          print("Internet restored: Triggering auto-sync...");
          syncData();
        }
      }
    });
  }
}