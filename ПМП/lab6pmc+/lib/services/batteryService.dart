import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class BatteryService {
  static const platform = MethodChannel('battery_service');

  static Future<String> getBatteryLevel() async {
    try {
      final String result = await platform.invokeMethod('getBatteryLevel');

      // Демонстрация разницы между платформами
      if (Platform.isAndroid) {
        return "Android Battery: $result";
      } else if (Platform.isIOS) {
        return "iOS Battery: $result";
      }

      return result;
    } catch (e) {
      return 'Unknown battery level';
    }
  }
}