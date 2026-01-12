import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectivityController;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Stream<bool> get connectivityStream => _connectivityController!.stream;

  ConnectivityService() {
    _connectivityController = StreamController<bool>.broadcast();
    _init();
  }

  Future<void> _init() async {
    final initialResult = await _connectivity.checkConnectivity();
    _updateStatus(initialResult);

    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateStatus,
      onError: (error) {
        print('Ошибка отслеживания подключения: $error');
      },
    );
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final isConnected = results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
    _connectivityController?.add(isConnected);
  }

  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController?.close();
  }
}

