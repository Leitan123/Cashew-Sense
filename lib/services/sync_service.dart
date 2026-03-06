import 'package:connectivity_plus/connectivity_plus.dart';
import 'auth_service.dart';

class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  bool _isInit = false;

  void init() {
    if (_isInit) return;
    _isInit = true;

    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // If at least one result shows internet connectivity
      if (!results.contains(ConnectivityResult.none)) {
        // Trigger background sync
        AuthService.instance.syncData();
      }
    });
  }
}
