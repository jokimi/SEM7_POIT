import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class DeviceService {
  static const platform = MethodChannel('device_info');
  static Future<String> getDeviceManufacturer() async {
    try {
      final String result = await platform.invokeMethod('getDeviceManufacturer');
      if (Platform.isAndroid) {
        return result;
      }
      return result;
    } catch (e) {
      return 'Неизвестное устройство';
    }
  }
}