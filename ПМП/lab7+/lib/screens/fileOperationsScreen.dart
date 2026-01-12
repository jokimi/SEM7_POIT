// screens/file_operations_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import '../services/fileService.dart';
import '../models/message.dart';
import '../isolates/fileIsolate.dart';

class FileOperationsScreen extends StatefulWidget {
  @override
  _FileOperationsScreenState createState() => _FileOperationsScreenState();
}

class _FileOperationsScreenState extends State<FileOperationsScreen> {
  final FileService _fileService = FileService();
  final TextMessage _demoMessage = TextMessage(
      'Демонстрационное сообщение для тестирования файловой системы',
      'FileSystemUser'
  );
  Map<String, String?> _directories = {};
  Map<String, List<String>> _directoryFiles = {};
  Map<String, String> _directoryErrors = {};
  bool _isLoading = true;
  String _selectedFileContent = '';

  @override
  void initState() {
    super.initState();
    _loadDirectories();
  }

  Future<void> _loadDirectories() async {
    setState(() => _isLoading = true);
    try {
      _directories = await _fileService.getAllDirectories();
      await _loadFilesForDirectories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки директорий: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFilesForDirectories() async {
    _directoryFiles.clear();
    _directoryErrors.clear();

    for (final entry in _directories.entries) {
      if (entry.value != null) {
        try {
          final result = await FileIsolateService.executeInIsolate(
            readFilesIsolate,
            {'directoryPath': entry.value!},
          );

          if (result['success'] == true) {
            final files = List<String>.from(
                (result['files'] as List).map((file) => file['filePath'] as String)
            );
            _directoryFiles[entry.key] = files;
          } else {
            _directoryErrors[entry.key] = result['error'] ?? 'Неизвестная ошибка';
          }
        } catch (e) {
          _directoryErrors[entry.key] = e.toString();
        }
      } else {
        _directoryErrors[entry.key] = 'Директория не доступна на данной платформе';
      }
    }
    setState(() {});
  }

  Future<void> _saveToDirectory(String directoryName, String path) async {
    try {
      // Создаем директорию если не существует
      await _fileService.createDirectoryIfNotExists(path);

      final result = await FileIsolateService.executeInIsolate(
        saveMessageIsolate,
        {
          'directoryPath': path,
          'filename': '${directoryName.toLowerCase()}_message_${DateTime.now().millisecondsSinceEpoch}',
          'messageType': directoryName,
        },
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Сохранено в $directoryName: ${result['filePath']}')),
        );
        await _loadFilesForDirectories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения в $directoryName: ${result['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка изолята: $e')),
      );
    }
  }

  Future<void> _saveDifferentMessagesToAllDirectories() async {
    try {
      await _fileService.saveDifferentMessagesToDirectories();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Разные сообщения сохранены во все доступные директории')),
      );
      await _loadFilesForDirectories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения во все директории: $e')),
      );
    }
  }

  Future<void> _readFile(String filePath) async {
    final content = await _fileService.readMessageFromFile(filePath);
    setState(() {
      _selectedFileContent = content != null ?
      'Содержимое файла $filePath:\n\n${_formatFileContent(content)}' :
      'Не удалось прочитать файл $filePath';
    });
  }

  String _formatFileContent(Map<String, dynamic> content) {
    final buffer = StringBuffer();

    void addSection(String title, dynamic data, [int indent = 0]) {
      final indentStr = '  ' * indent;
      buffer.writeln('$indentStr$title:');
      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            addSection(key.toString(), value, indent + 1);
          } else {
            buffer.writeln('${'  ' * (indent + 1)}$key: $value');
          }
        });
      } else {
        buffer.writeln('${'  ' * (indent + 1)}$data');
      }
      buffer.writeln('');
    }

    // Основная информация о файле
    addSection('Основная информация', {
      'Тип файла': content['type'] ?? 'unknown',
      'Имя файла': content['filename'] ?? 'unknown',
      'Время сохранения': content['savedAt'] ?? 'unknown',
      'Описание': content['description'] ?? 'нет описания',
    });

    // Информация о сообщении
    if (content['message'] != null) {
      addSection('Сообщение', content['message']);
    }

    // Дополнительные метаданные
    final metadata = <String, dynamic>{};
    if (content['autoDelete'] != null) {
      metadata['Автоудаление'] = content['autoDelete'];
    }
    if (content['priority'] != null) {
      metadata['Приоритет'] = content['priority'];
    }
    if (content['version'] != null) {
      metadata['Версия'] = content['version'];
    }
    if (content['category'] != null) {
      metadata['Категория'] = content['category'];
    }
    if (content['backup'] != null) {
      metadata['Резервное копирование'] = content['backup'];
    }
    if (content['maxAge'] != null) {
      metadata['Макс. возраст'] = content['maxAge'];
    }
    if (content['storageType'] != null) {
      metadata['Тип хранилища'] = content['storageType'];
    }
    if (content['userGenerated'] != null) {
      metadata['Пользовательские данные'] = content['userGenerated'];
    }

    if (metadata.isNotEmpty) {
      addSection('Метаданные', metadata);
    }

    return buffer.toString();
  }

  Future<void> _deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл удален: ${filePath.split('/').last}')),
        );
        await _loadFilesForDirectories();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления файла: $e')),
      );
    }
  }

  Future<void> _getFileInfo(String filePath) async {
    final info = await _fileService.getFileInfo(filePath);
    if (info != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Информация о файле'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Путь: ${info['path']}'),
                Text('Размер: ${info['size']} байт'),
                Text('Изменен: ${info['modified']}'),
                Text('Последний доступ: ${info['accessed']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Закрыть'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Работа с файловой системой'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDirectories,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          // Демонстрационное сообщение
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Демонстрационное сообщение для сохранения:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Отправитель: ${_demoMessage.sender}'),
                  Text('Текст: ${_demoMessage.originalText}'),
                  Text('ID: ${_demoMessage.id}'),
                  Text('Зашифровано: ${_demoMessage.isEncrypted ? "Да" : "Нет"}'),
                  Text('Дата: ${_demoMessage.timestamp.toLocal()}'),
                ],
              ),
            ),
          ),

          // Кнопка сохранения во все директории
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _saveDifferentMessagesToAllDirectories,
              icon: Icon(Icons.save_alt),
              label: Text('Сохранить разные сообщения во все директории'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Эта функция сохранит разные сообщения с разными данными в каждую доступную директорию',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),

          // Список директорий
          ..._directories.entries.map((entry) => _buildDirectoryCard(entry)),

          // Содержимое выбранного файла
          if (_selectedFileContent.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Содержимое файла:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => setState(() => _selectedFileContent = ''),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _selectedFileContent,
                            style: TextStyle(fontFamily: 'Monospace', fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDirectoryCard(MapEntry<String, String?> entry) {
    final files = _directoryFiles[entry.key] ?? [];
    final error = _directoryErrors[entry.key];

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок директории
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (entry.value != null) ...[
                        Text(
                          entry.value!,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (error != null) ...[
                        SizedBox(height: 4),
                        Text(
                          error,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (entry.value != null && error == null)
                  ElevatedButton(
                    onPressed: () => _saveToDirectory(entry.key, entry.value!),
                    child: Text('Сохранить'),
                  ),
              ],
            ),

            // Файлы в директории
            if (files.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Файлы в директории (${files.length}):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              ...files.map((file) => _buildFileItem(file)),
              if (files.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '... и ещё ${files.length - 3} файлов',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
            ] else if (entry.value != null && error == null) ...[
              SizedBox(height: 12),
              Text(
                'Нет файлов в директории',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(String filePath) {
    final fileName = filePath.split('/').last;
    final fileExtension = fileName.split('.').last;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: Colors.grey[50],
      child: ListTile(
        dense: true,
        leading: Icon(
          _getFileIcon(fileExtension),
          color: _getFileColor(fileExtension),
          size: 24,
        ),
        title: Text(
          fileName,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          filePath,
          style: TextStyle(fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.info_outline, size: 18),
              onPressed: () => _getFileInfo(filePath),
              tooltip: 'Информация о файле',
            ),
            IconButton(
              icon: Icon(Icons.read_more, size: 18),
              onPressed: () => _readFile(filePath),
              tooltip: 'Прочитать файл',
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => _deleteFile(filePath),
              tooltip: 'Удалить файл',
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'json':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension) {
      case 'json':
        return Colors.orange;
      case 'txt':
        return Colors.blue;
      case 'jpg':
      case 'png':
      case 'gif':
        return Colors.green;
      case 'mp4':
      case 'avi':
        return Colors.purple;
      case 'mp3':
      case 'wav':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}