import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
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

  /// Register works completely offline
  Future<bool> register({
    required String name,
    required String phone,
    required String pin,
    required String district,
    required double farmSize,
  }) async {
    try {
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

  /// Login requires internet UNLESS the phone matches the last logged out phone
  Future<bool> login({required String phone, required String pin}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogOutPhone = prefs.getString(_lastLogOutPhoneKey);

    bool isOfflineAllowed = (phone == lastLogOutPhone);

    if (!isOfflineAllowed) {
      // Must check internet connection
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        throw Exception('Internet connection required for new users to log in on this device.');
      }
    }

    // Since we don't have a real cloud API yet, we verify against local DB for now.
    // In the future: if (!isOfflineAllowed), we would make an API call to fetch user data and insert it locally.
    final user = await DatabaseService.instance.getUserByPhone(phone);
    
    if (user == null) {
      throw Exception('User not found. Check phone number.');
    }

    final pinHash = _hashPin(pin);
    if (user['pin_hash'] != pinHash) {
      throw Exception('Incorrect PIN.');
    }

    // Success
    await _setLoggedIn(user['id'] as int);
    await prefs.setString(_lastLogOutPhoneKey, phone); // They are now the last potential logout phone
    
    // Attempt to sync immediately if internet is present
    syncData();
    
    return true;
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
    final String apiUrl = 'https://dimgrey-fly-458602.hostingersite.com/api/sync';

    try {
      final db = DatabaseService.instance;

      // 1. Get unsynced users
      final unsyncedUsersList = await db.getUnsyncedUsers();
      
      // We also need unsynced leaf and pest scans. Right now, our local schema doesn't have a 
      // 'synced' column for scans, so we should either add one or just upload everything temporarily.
      // To prevent duplicate uploads and bandwidth waste, we should ideally add 'synced' to scans too.
      // Assuming we just send all for the currently logged in users for now (Laravel Handles duplicates via firstOrCreate).

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
        
        // Add phone number to scans so backend can link them to the right customer
        final userPhone = _currentUserData!['phone'];
        
        // Helper to convert scans list to payload with base64
        Future<List<Map<String, dynamic>>> prepareScansWithImages(List<Map<String, dynamic>> localScans) async {
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
              print("AuthService: Could not read image for scan: $e");
            }
            
            prepared.add({
              ...scan,
              'user_phone': userPhone,
              'imageBase64': base64Image,
            });
          }
          return prepared;
        }

        payload['leaf_scans'] = await prepareScansWithImages(leafScans);
        payload['pest_scans'] = await prepareScansWithImages(pestScans);
      }

      // Call API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("AuthService: Sync successful.");
        // Mark users as synced locally
        for (var user in unsyncedUsersList) {
          await db.markUserSynced(user['id']);
        }
      } else {
        print("AuthService: Sync failed with status: ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      print("AuthService: Sync error - $e");
    }
  }
}
