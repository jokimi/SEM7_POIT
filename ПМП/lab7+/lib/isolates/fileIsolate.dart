// isolates/file_isolate.dart
import 'dart:isolate';
import 'dart:io';
import 'dart:convert';
import '../models/message.dart';

typedef IsolateFunction = void Function(Map<String, dynamic>);

void saveMessageIsolate(Map<String, dynamic> params) {
  final receivePort = ReceivePort();

  Isolate.run(() async {
    final directoryPath = params['directoryPath'] as String;
    final filename = params['filename'] as String;
    final messageType = params['messageType'] as String;
    final sendPort = params['sendPort'] as SendPort;

    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Разные сообщения в зависимости от типа директории
      final message = _createMessageForDirectory(messageType, filename);
      final file = File('$directoryPath/$filename.json');
      final data = _createDifferentDataForIsolate(message, filename, messageType);

      await file.writeAsString(jsonEncode(data));
      sendPort.send({'success': true, 'filePath': file.path});
    } catch (e) {
      sendPort.send({'success': false, 'error': e.toString()});
    }
  });
}

void readFilesIsolate(Map<String, dynamic> params) {
  final receivePort = ReceivePort();

  Isolate.run(() async {
    final directoryPath = params['directoryPath'] as String;
    final sendPort = params['sendPort'] as SendPort;

    try {
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        final files = await directory.list().toList();
        final jsonFiles = files
            .where((entity) => entity is File && entity.path.endsWith('.json'))
            .map((entity) => entity.path)
            .toList();

        final results = <Map<String, dynamic>>[];
        for (final filePath in jsonFiles) {
          try {
            final file = File(filePath);
            final contents = await file.readAsString();
            final data = jsonDecode(contents);
            results.add({
              'filePath': filePath,
              'data': data,
              'fileName': filePath.split('/').last,
            });
          } catch (e) {
            results.add({
              'filePath': filePath,
              'error': e.toString(),
            });
          }
        }

        sendPort.send({'success': true, 'files': results});
      } else {
        sendPort.send({'success': true, 'files': []});
      }
    } catch (e) {
      sendPort.send({'success': false, 'error': e.toString()});
    }
  });
}

Message _createMessageForDirectory(String directoryType, String filename) {
  final now = DateTime.now();
  final id = '${directoryType.toLowerCase()}_${now.millisecondsSinceEpoch}';

  switch (directoryType) {
    case 'Temporary':
      return TextMessage('Временное сообщение из $directoryType - будет автоматически удалено системой', 'System',
          isEncrypted: true, id: id);
    case 'Application Support':
      return TextMessage('Сообщение поддержки приложения из $directoryType - содержит важные данные для работы приложения', 'Support', id: id);
    case 'Application Library':
      return MediaMessage('https://picsum.photos/400/300', 'image', 'Library', id: id);
    case 'Application Documents':
      return TextMessage('Важный документ из $directoryType - постоянное хранение пользовательских данных', 'Documents', id: id);
    case 'Application Cache':
      return TextMessage('Кэшированное сообщение из $directoryType - может быть очищено для освобождения места', 'Cache', id: id);
    case 'External Storage':
      return MediaMessage('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          'video', 'External', id: id);
    case 'External Cache':
      return TextMessage('Внешнее кэшированное сообщение из $directoryType - данные на внешнем хранилище', 'ExtCache', id: id);
    case 'External Storage Dirs':
      return MediaMessage('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          'audio', 'ExtStorage', id: id);
    case 'Downloads':
      return TextMessage('Загруженное сообщение из $directoryType - пользовательские данные из папки загрузок', 'Downloads', isEncrypted: true, id: id);
    default:
      return TextMessage('Стандартное сообщение из $directoryType', 'Default', id: id);
  }
}

Map<String, dynamic> _createDifferentDataForIsolate(Message message, String filename, String directoryType) {
  final now = DateTime.now();

  // Базовые данные
  final baseData = {
    'message': message.toMap(),
    'savedAt': now.toIso8601String(),
    'filename': filename,
    'directoryType': directoryType,
  };

  // Добавляем разные дополнительные поля в зависимости от типа директории
  switch (directoryType) {
    case 'Temporary':
      return {
        ...baseData,
        'type': 'temporary',
        'autoDelete': true,
        'priority': 'low',
        'description': 'Временные данные, подлежащие автоматическому удалению системой',
        'lifetime': 'short',
        'cleanupPolicy': 'automatic',
      };
    case 'Application Support':
      return {
        ...baseData,
        'type': 'support',
        'autoDelete': false,
        'priority': 'high',
        'description': 'Критически важные данные поддержки приложения',
        'version': '1.0.0',
        'essential': true,
        'backupRequired': true,
      };
    case 'Application Library':
      return {
        ...baseData,
        'type': 'library',
        'autoDelete': false,
        'priority': 'medium',
        'description': 'Ресурсы библиотеки приложения',
        'category': 'media',
        'resourceType': 'image',
        'optimized': true,
      };
    case 'Application Documents':
      return {
        ...baseData,
        'type': 'documents',
        'autoDelete': false,
        'priority': 'high',
        'description': 'Постоянные документы пользователя',
        'backup': true,
        'sync': true,
        'userData': true,
      };
    case 'Application Cache':
      return {
        ...baseData,
        'type': 'cache',
        'autoDelete': true,
        'priority': 'low',
        'description': 'Временные кэшированные данные для ускорения работы',
        'maxAge': '7 days',
        'reloadable': true,
        'performance': true,
      };
    case 'External Storage':
      return {
        ...baseData,
        'type': 'external',
        'autoDelete': false,
        'priority': 'medium',
        'description': 'Данные на внешнем хранилище устройства',
        'storageType': 'removable',
        'portable': true,
        'largeFile': true,
      };
    case 'External Cache':
      return {
        ...baseData,
        'type': 'external_cache',
        'autoDelete': true,
        'priority': 'low',
        'description': 'Кэш на внешнем хранилище',
        'maxAge': '30 days',
        'external': true,
        'optional': true,
      };
    case 'External Storage Dirs':
      return {
        ...baseData,
        'type': 'external_dirs',
        'autoDelete': false,
        'priority': 'medium',
        'description': 'Данные в дополнительных внешних директориях',
        'storageType': 'shared',
        'accessible': true,
        'multiUser': true,
      };
    case 'Downloads':
      return {
        ...baseData,
        'type': 'downloads',
        'autoDelete': false,
        'priority': 'medium',
        'description': 'Пользовательские загруженные данные',
        'userGenerated': true,
        'source': 'external',
        'verification': 'required',
      };
    default:
      return baseData;
  }
}

class FileIsolateService {
  static Future<dynamic> executeInIsolate(
      IsolateFunction isolateFunction,
      Map<String, dynamic> params) async {
    final receivePort = ReceivePort();
    final modifiedParams = Map<String, dynamic>.from(params)
      ..['sendPort'] = receivePort.sendPort;

    // Используем Isolate.spawn с правильной типизацией
    await Isolate.spawn<Map<String, dynamic>>(
          (Map<String, dynamic> message) {
        isolateFunction(message);
      },
      modifiedParams,
    );

    return await receivePort.first;
  }
}