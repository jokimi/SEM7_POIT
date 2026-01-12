package com.example.lab6pmc;

import android.content.Intent;
import android.net.Uri;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Bundle;
import android.provider.AlarmClock; // Добавьте этот импорт
import android.util.Log; // Добавьте этот импорт

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String DEVICE_INFO_CHANNEL = "device_info";
    private static final String ALARM_SERVICE_CHANNEL = "alarm_service";
    private static final String BATTERY_SERVICE_CHANNEL = "battery_service";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Device Info Channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), DEVICE_INFO_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("getDeviceManufacturer")) {
                        String manufacturer = getDeviceManufacturer();
                        result.success(manufacturer);
                    } else {
                        result.notImplemented();
                    }
                });

        // Alarm Service Channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), ALARM_SERVICE_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("setAlarm")) {
                        try {
                            Integer hour = call.argument("hour");
                            Integer minute = call.argument("minute");
                            boolean success = setAlarm(hour, minute);
                            result.success(success);
                        } catch (Exception e) {
                            result.error("ALARM_ERROR", "Failed to set alarm", e.getMessage());
                        }
                    } else {
                        result.notImplemented();
                    }
                });

        // Battery Service Channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), BATTERY_SERVICE_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("getBatteryLevel")) {
                        String batteryInfo = getBatteryInfo();
                        result.success(batteryInfo);
                    } else {
                        result.notImplemented();
                    }
                });
    }

    private String getDeviceManufacturer() {
        return Build.MANUFACTURER;
    }

    private boolean setAlarm(Integer hour, Integer minute) {
        try {
            // Валидация входных данных
            if (hour == null || minute == null) {
                Log.e("AlarmError", "Hour or minute is null");
                return false;
            }

            if (hour < 0 || hour > 23) {
                Log.e("AlarmError", "Invalid hour: " + hour);
                return false;
            }

            if (minute < 0 || minute > 59) {
                Log.e("AlarmError", "Invalid minute: " + minute);
                return false;
            }

            Intent intent = new Intent(AlarmClock.ACTION_SET_ALARM);

            // Обязательные параметры
            intent.putExtra(AlarmClock.EXTRA_HOUR, hour);
            intent.putExtra(AlarmClock.EXTRA_MINUTES, minute);

            // Рекомендуемые параметры для лучшей совместимости
            intent.putExtra(AlarmClock.EXTRA_MESSAGE, "Alarm from Flutter App");
            intent.putExtra(AlarmClock.EXTRA_SKIP_UI, false); // Показать UI для подтверждения
            intent.putExtra(AlarmClock.EXTRA_VIBRATE, true);

            // Добавьте флаг для новой задачи
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

            if (intent.resolveActivity(getPackageManager()) != null) {
                startActivity(intent);
                Log.i("AlarmSuccess", "Alarm set for " + hour + ":" + minute);
                return true;
            } else {
                Log.e("AlarmError", "No alarm app found");
                return false;
            }
        } catch (Exception e) {
            Log.e("AlarmError", "Failed to set alarm: " + e.getMessage());
            return false;
        }
    }

    private String getBatteryInfo() {
        BatteryManager batteryManager = (BatteryManager) getSystemService(BATTERY_SERVICE);

        if (batteryManager != null) {
            int batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY);
            return "Android: " + batteryLevel + "%";
        }

        return "Android: Unknown";
    }
}