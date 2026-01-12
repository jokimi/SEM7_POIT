// screens/message_detail_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import '../models/message.dart';
import '../database/databaseHelper.dart';
import 'messageEditScreen.dart';
import '../widgets/videoPlayerWidget.dart';
import '../widgets/audioPlayerWidget.dart';

class MessageDetailScreen extends StatefulWidget {
  final Message message;

  const MessageDetailScreen({Key? key, required this.message}) : super(key: key);

  @override
  _MessageDetailScreenState createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  late Message _message;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _message = widget.message;
  }

  Future<void> _toggleReadStatus() async {
    setState(() {
      _message.markAsRead(read: !_message.isRead);
    });

    await _databaseHelper.updateMessage(_message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Сообщение ${_message.isRead ? 'прочитано' : 'не прочитано'}'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (_message is MediaMessage) {
      final mediaMessage = _message as MediaMessage;

      if (mediaMessage.mediaType == 'image') {
        return Column(
          children: [
            Text(
              'Изображение:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _buildImageWidget(mediaMessage.mediaUrl),
            ),
            SizedBox(height: 10),
            Text(
              'URL: ${mediaMessage.mediaUrl}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }
      else if (mediaMessage.mediaType == 'video') {
        return Column(
          children: [
            Text(
              'Видео:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            VideoPlayerWidget(videoUrl: mediaMessage.mediaUrl),
          ],
        );
      }
      else if (mediaMessage.mediaType == 'audio') {
        return Column(
          children: [
            Text(
              'Аудио:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            SimpleAudioPlayerWidget(audioUrl: mediaMessage.mediaUrl),
          ],
        );
      }
    }

    return SizedBox.shrink();
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      // Интернет изображение
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget('Ошибка загрузки изображения', imageUrl);
        },
      );
    } else if (imageUrl.startsWith('assets/')) {
      // Локальный asset
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget('Ошибка загрузки локального файла', imageUrl);
        },
      );
    } else {
      // Локальный файл (путь к файлу)
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget('Ошибка загрузки локального файла', imageUrl);
        },
      );
    }
  }

  Widget _buildErrorWidget(String errorText, String url) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, color: Colors.red, size: 50),
        SizedBox(height: 10),
        Text(errorText, textAlign: TextAlign.center),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            url,
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            setState(() {}); // Попробовать перезагрузить
          },
          child: Text('Повторить'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Детали сообщения'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MessageEditScreen(message: _message)),
              );

              if (result == true) {
                // Загружаем обновленное сообщение из базы
                final messages = await _databaseHelper.getMessages();
                final updatedMessage = messages.firstWhere(
                      (msg) => msg.id == _message.id,
                  orElse: () => _message,
                );
                setState(() {
                  _message = updatedMessage;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Сообщение обновлено')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID:', _message.id),
            _buildDetailRow('Отправитель:', _message.sender),
            _buildDetailRow('Дата:', '${_message.timestamp.toLocal()}'),
            _buildDetailRow('Прочитано:', _message.isRead ? 'Да' : 'Нет'),

            if (_message is TextMessage) ...[
              _buildDetailRow('Тип:', 'Текстовое сообщение'),
              _buildDetailRow('Текст:', (_message as TextMessage).originalText),
              _buildDetailRow('Зашифровано:', (_message as TextMessage).isEncrypted ? 'Да' : 'Нет'),
              _buildDetailRow('Статус доставки:', _getDeliveryStatus((_message as TextMessage).deliveryStatus)),
              if ((_message as TextMessage).isEncrypted)
                _buildDetailRow('Отображаемый текст:', (_message as TextMessage).content),
            ],

            if (_message is MediaMessage) ...[
              _buildDetailRow('Тип:', 'Медиа сообщение'),
              _buildDetailRow('Тип медиа:', (_message as MediaMessage).mediaType),
              SizedBox(height: 20),
              _buildMediaContent(),
            ],

            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleReadStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _message.isRead ? Colors.orange : Colors.green,
                    ),
                    child: Text(
                      _message.isRead ? 'Пометить как непрочитанное' : 'Пометить как прочитанное',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            if (_message is TextMessage) ...[
              ElevatedButton(
                onPressed: () {
                  (_message as TextMessage).resendMessage(
                    newRecipient: 'Новый получатель',
                    onComplete: (result) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result)),
                      );
                      setState(() {});
                    },
                  );
                },
                child: Text('Переслать сообщение'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _getDeliveryStatus(int status) {
    switch (status) {
      case 0: return 'Не отправлено';
      case 1: return 'Отправлено';
      case 2: return 'Доставлено';
      default: return 'Неизвестно';
    }
  }
}