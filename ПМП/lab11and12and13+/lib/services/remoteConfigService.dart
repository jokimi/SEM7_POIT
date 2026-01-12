import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults({
        'like_button_enabled': true,
        'block_color': '#FFAE1A',
        'app_version': '1.0.0',
        'feature_new_books': true,
      });

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(seconds: 0),
        ),
      );

      final activated = await _remoteConfig.fetchAndActivate();
      if (activated) {
        print('Remote Config загружен и активирован');
      } else {
        print('Remote Config загружен, но не активирован (используются значения по умолчанию)');
      }

      print('like_button_enabled: ${_remoteConfig.getBool('like_button_enabled')}');
      print('Источник значения: ${_remoteConfig.getValue('like_button_enabled').source}');
    } catch (e) {
      print('Ошибка инициализации Remote Config: $e');
    }
  }

  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Ошибка загрузки Remote Config: $e');
    }
  }

  bool getBool(String key) {
    return _remoteConfig.getBool(key);
  }

  String getString(String key) {
    return _remoteConfig.getString(key);
  }

  int getInt(String key) {
    return _remoteConfig.getInt(key);
  }

  double getDouble(String key) {
    return _remoteConfig.getDouble(key);
  }

  bool isLikeButtonEnabled() {
    try {
      final configValue = _remoteConfig.getValue('like_button_enabled');
      final source = configValue.source;

      if (source == ValueSource.valueDefault) {
        return true;
      }
      return configValue.asBool();
    } catch (e) {
      print('Ошибка получения значения like_button_enabled: $e');
      return true;
    }
  }

  Color getBlockColor() {
    try {
      final colorString = getString('block_color');
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return const Color(0xFFFFAE1A);
    }
  }

  Stream<RemoteConfigUpdate> get configUpdateStream => _remoteConfig.onConfigUpdated;
}