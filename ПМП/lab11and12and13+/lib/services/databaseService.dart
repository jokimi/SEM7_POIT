import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseReference? _userStatusRef;
  DatabaseReference? _lastSeenRef;
  DatabaseReference? _connectedRef;
  StreamSubscription<DatabaseEvent>? _connectedSubscription;

  Future<void> setUserOnline(String userId) async {
    try {
      final userStatusRef = _database.child('users/$userId/status');
      final lastSeenRef = _database.child('users/$userId/lastSeen');

      await userStatusRef.set('online');

      _userStatusRef = userStatusRef;
      _lastSeenRef = lastSeenRef;

      _userStatusRef!.onDisconnect().set('offline');
      _lastSeenRef!.onDisconnect().set(ServerValue.timestamp);
    } catch (e) {
      print('Ошибка установки статуса онлайн: $e');
    }
  }

  Future<void> setUserOffline(String userId) async {
    try {
      await _database.child('users/$userId/status').set('offline');
      await _database
          .child('users/$userId/lastSeen')
          .set(ServerValue.timestamp);
    } catch (e) {
      print('Ошибка установки статуса офлайн: $e');
    }
  }

  Stream<Map<String, dynamic>?> getUserStatusStream(String userId) {
    return _database.child('users/$userId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        return {
          'status': data['status'] ?? 'offline',
          'lastSeen': data['lastSeen'],
        };
      }
      return null;
    });
  }

  Future<Map<String, dynamic>?> getUserStatus(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return {
          'status': data['status'] ?? 'offline',
          'lastSeen': data['lastSeen'],
        };
      }
      return null;
    } catch (e) {
      print('Ошибка получения статуса: $e');
      return null;
    }
  }

  // Инициализация отслеживания статуса текущего пользователя
  Future<void> initializeUserStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userId = user.uid;

      _connectedRef ??= FirebaseDatabase.instance.ref('.info/connected');
      _connectedSubscription ??= _connectedRef!.onValue.listen((event) {
        final connected = event.snapshot.value == true;
        if (connected) {
          setUserOnline(userId);
        }
      });
    }
  }

  Future<void> cleanup() async {
    final user = _auth.currentUser;
    if (user != null) {
      await setUserOffline(user.uid);
    }

    await _connectedSubscription?.cancel();
    _connectedSubscription = null;
    _connectedRef = null;

    _userStatusRef = null;
    _lastSeenRef = null;
  }
}