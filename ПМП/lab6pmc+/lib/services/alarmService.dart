import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class AlarmService {
  static const platform = MethodChannel('alarm_service');

  static Future<bool> setAlarm(int hour, int minute) async {
    try {
      final Map<String, dynamic> params = {
        'hour': hour,
        'minute': minute,
      };
      final bool result = await platform.invokeMethod('setAlarm', params);
      if (Platform.isIOS) {
        print("На iOS будильник устанавливается через системное приложение 'Часы'");
      }

      return result;
    } catch (e) {
      return false;
    }
  }
}