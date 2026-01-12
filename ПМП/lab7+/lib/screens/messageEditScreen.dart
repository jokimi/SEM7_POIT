// screens/message_edit_screen.dart
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../database/databaseHelper.dart';

class MessageEditScreen extends StatefulWidget {
  final Message? message;

  const MessageEditScreen({Key? key, this.message}) : super(key: key);

  @override
  _MessageEditScreenState createState() => _MessageEditScreenState();
}

class _MessageEditScreenState extends State<MessageEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _databaseHelper = DatabaseHelper();

  late String _type;
  late String _sender;
  late String _text;
  late String _mediaUrl;
  late String _mediaType;
  late bool _isEncrypted;

  @override
  void initState() {
    super.initState();
    final message = widget.message;
    if (message != null) {
      _type = message is TextMessage ? 'text' : 'media';
      _sender = message.sender;
      if (message is TextMessage) {
        _text = message.originalText;
        _isEncrypted = message.isEncrypted;
      } else if (message is MediaMessage) {
        _mediaUrl = message.mediaUrl;
        _mediaType = message.mediaType;
      }
    } else {
      _type = 'text';
      _sender = '';
      _text = '';
      _mediaUrl = '';
      _mediaType = 'image';
      _isEncrypted = false;
    }
  }

  Future<void> _saveMessage() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        Message message;

        if (_type == 'text') {
          if (widget.message != null) {
            message = TextMessage(_text, _sender,
                isEncrypted: _isEncrypted,
                id: widget.message!.id
            );
          } else {
            message = TextMessage(_text, _sender, isEncrypted: _isEncrypted);
          }
        } else {
          if (widget.message != null) {
            message = MediaMessage(_mediaUrl, _mediaType, _sender,
                id: widget.message!.id
            );
          } else {
            message = MediaMessage(_mediaUrl, _mediaType, _sender);
          }
        }

        if (widget.message != null) {
          await _databaseHelper.updateMessage(message);
        } else {
          await _databaseHelper.insertMessage(message);
        }

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  Widget _buildExampleChip(String label, String url, String type) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _mediaUrl = url;
          _mediaType = type;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.message != null ? 'Редактировать сообщение' : 'Новое сообщение'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(labelText: 'Тип сообщения'),
                items: [
                  DropdownMenuItem(value: 'text', child: Text('Текстовое')),
                  DropdownMenuItem(value: 'media', child: Text('Медиа')),
                ],
                onChanged: (value) {
                  setState(() => _type = value!);
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _sender,
                decoration: InputDecoration(
                  labelText: 'Отправитель',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Введите отправителя' : null,
                onSaved: (value) => _sender = value!,
              ),
              SizedBox(height: 16),
              if (_type == 'text') ...[
                TextFormField(
                  initialValue: _text,
                  decoration: InputDecoration(
                    labelText: 'Текст сообщения',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Введите текст сообщения' : null,
                  onSaved: (value) => _text = value!,
                ),
                SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Зашифровать сообщение'),
                  value: _isEncrypted,
                  onChanged: (value) => setState(() => _isEncrypted = value),
                ),
              ],
              if (_type == 'media') ...[
                TextFormField(
                  initialValue: _mediaUrl,
                  decoration: InputDecoration(
                    labelText: 'URL медиа или путь к файлу',
                    border: OutlineInputBorder(),
                    hintText: 'Введите URL или путь к локальному файлу',
                  ),
                  validator: (value) => value!.isEmpty ? 'Введите URL или путь' : null,
                  onSaved: (value) => _mediaUrl = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  initialValue: _mediaType,
                  decoration: InputDecoration(
                    labelText: 'Тип медиа',
                    border: OutlineInputBorder(),
                    hintText: 'image, video, audio',
                  ),
                  validator: (value) => value!.isEmpty ? 'Введите тип медиа' : null,
                  onSaved: (value) => _mediaType = value!,
                ),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveMessage,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Сохранить',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}