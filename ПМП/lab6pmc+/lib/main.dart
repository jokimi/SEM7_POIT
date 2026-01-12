import 'dart:io';
import 'package:flutter/material.dart';
import 'services/deviceService.dart';
import 'services/alarmService.dart';
import 'services/batteryService.dart';
import 'services/cameraService.dart';

void main() {
  runApp(MyApp());
}

/*
void main() {
  runApp(
      DevicePreview(builder: (context) => MyApp())
  );
}
*/

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platform Channels',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PlatformChannelsDemo(),
    );
  }
}

class PlatformChannelsDemo extends StatefulWidget {
  @override
  _PlatformChannelsDemoState createState() => _PlatformChannelsDemoState();
}

class _PlatformChannelsDemoState extends State<PlatformChannelsDemo> {
  String _deviceManufacturer = 'Unknown';
  String _batteryLevel = 'Unknown';
  File? _imageFile;

  final TextEditingController _alarmHourController = TextEditingController(text: '08');
  final TextEditingController _alarmMinuteController = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _loadBatteryLevel();
  }

  void _loadDeviceInfo() async {
    String manufacturer = await DeviceService.getDeviceManufacturer();
    setState(() {
      _deviceManufacturer = manufacturer;
    });
  }

  void _loadBatteryLevel() async {
    String level = await BatteryService.getBatteryLevel();
    setState(() {
      _batteryLevel = level;
    });
  }

  void _setAlarm() async {
    int hour = int.tryParse(_alarmHourController.text) ?? 8;
    int minute = int.tryParse(_alarmMinuteController.text) ?? 30;

    bool success = await AlarmService.setAlarm(hour, minute);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Будильник установлен на $hour:$minute' : 'Ошибка установки будильника'),
      ),
    );
  }

  void _takePhoto() async {
    String? imagePath = await CameraService.takePhoto();
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        _imageFile = File(imagePath);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Фото сделано'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка получения фото или нет разрешения'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Лабораторная работа №6'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 1. Device Manufacturer
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Производитель',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('$_deviceManufacturer'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadDeviceInfo,
                      child: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // 2. Alarm Setting
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Установка будильника',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _alarmHourController,
                            decoration: InputDecoration(
                              labelText: 'Часы (24h)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _alarmMinuteController,
                            decoration: InputDecoration(
                              labelText: 'Минуты',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _setAlarm,
                      child: Icon(Icons.check_rounded),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // 3. Battery Level
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Заряд батареи',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('$_batteryLevel'),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadBatteryLevel,
                      child: Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // 4. Camera
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Фото с камеры',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _takePhoto,
                      child: Icon(Icons.photo_camera_outlined),
                    ),
                    if (_imageFile != null) ...[
                      SizedBox(height: 16),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error, color: Colors.red, size: 40),
                                      SizedBox(height: 8),
                                      Text('Ошибка загрузки изображения'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: 16),
                      Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_outlined, size: 50, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}