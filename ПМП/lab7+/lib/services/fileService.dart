import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/message.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  Future<String?> _getDirectory(Future<Directory?> getDirFunction, List<String> unsupportedPlatforms) async {
    try {
      final directory = await getDirFunction;
      return directory?.path;
    } catch (e) {
      throw Exception('Директория не поддерживается на: ${unsupportedPlatforms.join(', ')}');
    }
  }

  Future<Map<String, String?>> getAllDirectories() async {
    return {
      'Temporary': await getTemporaryDirectoryPath(),
      'Application Support': await getApplicationSupportDirectoryPath(),
      'Application Library': await getApplicationLibraryDirectoryPath(),
      'Application Documents': await getApplicationDocumentsDirectoryPath(),
      'Application Cache': await getApplicationCacheDirectoryPath(),
      'External Storage': await getExternalStorageDirectoryPath(),
      'External Cache': await getExternalCacheDirectoriesPath(),
      'External Storage Dirs': await getExternalStorageDirectoriesPath(),
      'Downloads': await getDownloadsDirectoryPath(),
    };
  }

  Future<String?> getTemporaryDirectoryPath() async {
    try {
      final directory = await getTemporaryDirectory();
      return directory.path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getApplicationSupportDirectoryPath() async {
    try {
      final directory = await getApplicationSupportDirectory();
      return directory.path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getApplicationLibraryDirectoryPath() async {
    try {
      final directory = await getLibraryDirectory();
      return directory.path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getApplicationDocumentsDirectoryPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getApplicationCacheDirectoryPath() async {
    try {
      final directory = await getApplicationCacheDirectory();
      return directory.path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getExternalStorageDirectoryPath() async {
    try {
      final directory = await getExternalStorageDirectory();
      return directory?.path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getExternalCacheDirectoriesPath() async {
    try {
      final directories = await getExternalCacheDirectories();
      if (directories != null && directories.isNotEmpty) {
        return directories.first.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getExternalStorageDirectoriesPath() async {
    try {
      final directories = await getExternalStorageDirectories();
      if (directories != null && directories.isNotEmpty) {
        return directories.first.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getDownloadsDirectoryPath() async {
    try {
      final directory = await getDownloadsDirectory();
      return directory?.path;
    } catch (e) {
      return null;
    }
  }

  // Создание разных сообщений для разных директорий
  Map<String, Message> _generateDifferentMessages() {
    final now = DateTime.now();
    return {
      'Temporary': TextMessage('Временное сообщение - будет автоматически удалено', 'System',
          isEncrypted: true, id: 'temp_${now.millisecondsSinceEpoch}'),

      'Application Support': TextMessage('Сообщение поддержки приложения - содержит важные данные', 'Support',
          id: 'support_${now.millisecondsSinceEpoch}'),

      'Application Library': MediaMessage('https://picsum.photos/300/200', 'image', 'Library',
          id: 'library_${now.millisecondsSinceEpoch}'),

      'Application Documents': TextMessage('Документальное сообщение - постоянное хранение', 'Documents',
          isEncrypted: false, id: 'docs_${now.millisecondsSinceEpoch}'),

      'Application Cache': TextMessage('Кэшированное сообщение - может быть очищено', 'Cache',
          id: 'cache_${now.millisecondsSinceEpoch}'),

      'External Storage': MediaMessage('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          'video', 'External', id: 'external_${now.millisecondsSinceEpoch}'),

      'External Cache': TextMessage('Внешнее кэшированное сообщение', 'ExtCache',
          id: 'ext_cache_${now.millisecondsSinceEpoch}'),

      'External Storage Dirs': MediaMessage('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          'audio', 'ExtStorage', id: 'ext_storage_${now.millisecondsSinceEpoch}'),

      'Downloads': TextMessage('Сообщение в папке загрузок', 'Downloads',
          isEncrypted: true, id: 'downloads_${now.millisecondsSinceEpoch}'),
    };
  }

  Future<void> saveDifferentMessagesToDirectories() async {
    final directories = await getAllDirectories();
    final messages = _generateDifferentMessages();

    for (final entry in directories.entries) {
      if (entry.value != null) {
        final message = messages[entry.key];
        if (message != null) {
          await saveMessageToDirectory(message, entry.value!, '${entry.key.toLowerCase()}_message');
        }
      }
    }
  }

  Future<void> saveMessageToDirectory(Message message, String directoryPath, String filename) async {
    try {
      await createDirectoryIfNotExists(directoryPath);
      final file = File('$directoryPath/$filename.json');

      final data = _createDifferentDataStructure(message, filename);

      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Ошибка сохранения файла: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _createDifferentDataStructure(Message message, String filename) {
    final now = DateTime.now();

    final baseData = {
      'message': message.toMap(),
      'savedAt': now.toIso8601String(),
      'filename': filename,
    };

    if (filename.contains('temporary')) {
      return {
        ...baseData,
        'type': 'temporary',
        'autoDelete': true,
        'priority': 'low',
        'description': 'Временные данные, подлежащие автоматическому удалению',
      };
    } else if (filename.contains('support')) {
      return {
        ...baseData,
        'type': 'support',
        'autoDelete': false,
        'priority': 'high',
        'description': 'Данные поддержки приложения',
        'version': '1.0.0',
      };
    } else if (filename.contains('library')) {
      return {
        ...baseData,
        'type': 'library',
        'autoDelete': false,
        'priority': 'medium',
        'description': 'Библиотечные ресурсы',
        'category': 'media',
      };
    } else if (filename.contains('documents')) {
      return {
        ...baseData,
        'type': 'documents',
        'autoDelete': false,
        'priority': 'high',
        'description': 'Постоянные документы приложения',
        'backup': true,
      };
    } else if (filename.contains('cache')) {
      return {
        ...baseData,
        'type': 'cache',
        'autoDelete': true,
        'priority': 'low',
        'description': 'Кэшированные данные для улучшения производительности',
        'maxAge': '7 days',
      };
    } else if (filename.contains('external')) {
      return {
        ...baseData,
        'type': 'external',
        'autoDelete': false,
        'priority': 'medium',
        'description': 'Данные внешнего хранилища',
        'storageType': 'removable',
      };
    } else if (filename.contains('downloads')) {
      return {
        ...baseData,
        'type': 'downloads',
        'autoDelete': false,
        'priority': 'medium',
        'description': 'Загруженные пользователем данные',
        'userGenerated': true,
      };
    } else {
      return baseData;
    }
  }

  // Чтение сообщения из файла
  Future<Map<String, dynamic>?> readMessageFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents);
      }
      return null;
    } catch (e) {
      print('Ошибка чтения файла: $e');
      return null;
    }
  }

  // Получение списка файлов в директории
  Future<List<String>> getFilesInDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        final files = await directory.list().toList();
        return files
            .where((entity) => entity is File && entity.path.endsWith('.json'))
            .map((entity) => entity.path)
            .toList();
      }
      return [];
    } catch (e) {
      print('Ошибка получения файлов из директории: $e');
      return [];
    }
  }

  // Создание директории если не существует
  Future<void> createDirectoryIfNotExists(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } catch (e) {
      print('Ошибка создания директории: $e');
      rethrow;
    }
  }

  // Проверка доступности директории
  Future<bool> isDirectoryAccessible(String path) async {
    try {
      final directory = Directory(path);
      return await directory.exists();
    } catch (e) {
      return false;
    }
  }

  // Получение информации о файле
  Future<Map<String, dynamic>?> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return {
          'path': filePath,
          'size': stat.size,
          'modified': stat.modified,
          'accessed': stat.accessed,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}