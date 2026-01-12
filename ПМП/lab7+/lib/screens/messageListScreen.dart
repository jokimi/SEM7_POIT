// screens/message_list_screen.dart
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../database/databaseHelper.dart';
import 'messageDetailScreen.dart';
import 'messageEditScreen.dart';

class MessageListScreen extends StatefulWidget {
  @override
  _MessageListScreenState createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Message> _messages = [];
  List<Message> _filteredMessages = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'timestamp_new';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final messages = await _databaseHelper.getMessages();
    setState(() {
      _messages = messages;
      _applySortingAndSearch();
      _isLoading = false;
    });
  }

  List<Message> _applySearch(List<Message> messages) {
    if (_searchQuery.isEmpty) return messages;
    return messages.where((message) {
      if (message is TextMessage) {
        return message.originalText.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            message.sender.toLowerCase().contains(_searchQuery.toLowerCase());
      } else if (message is MediaMessage) {
        return message.sender.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            message.mediaType.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return false;
    }).toList();
  }

  void _applySortingAndSearch() {
    // Сначала применяем поиск
    List<Message> result = _applySearch(_messages);

    // Затем применяем сортировку
    switch (_sortBy) {
      case 'timestamp_new':
        result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case 'timestamp_old':
        result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case 'sender_asc':
        result.sort((a, b) => a.sender.toLowerCase().compareTo(b.sender.toLowerCase()));
        break;
      case 'sender_desc':
        result.sort((a, b) => b.sender.toLowerCase().compareTo(a.sender.toLowerCase()));
        break;
      case 'type':
        result.sort((a, b) {
          final aType = a is TextMessage ? 'text' : 'media';
          final bType = b is TextMessage ? 'text' : 'media';
          return aType.compareTo(bType);
        });
        break;
      case 'read_status':
        result.sort((a, b) => a.isRead == b.isRead ? 0 : a.isRead ? 1 : -1);
        break;
    }

    setState(() {
      _filteredMessages = result;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applySortingAndSearch();
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() {
        _sortBy = value;
      });
      _applySortingAndSearch();
    }
  }

  String _getSortButtonText() {
    switch (_sortBy) {
      case 'sender_asc':
        return 'По отправителю ▲';
      case 'sender_desc':
        return 'По отправителю ▼';
      case 'type':
        return 'По типу';
      case 'read_status':
        return 'По статусу';
      default:
        return 'Сортировка';
    }
  }

  Future<void> _deleteMessage(String id) async {
    await _databaseHelper.deleteMessage(id);
    _loadMessages();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Сообщение удалено')),
    );
  }

  Future<void> _markAsRead(Message message) async {
    message.markAsRead(read: !message.isRead);
    await _databaseHelper.updateMessage(message);
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сообщения'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MessageEditScreen()),
            ).then((_) => _loadMessages()),
          ),
          PopupMenuButton<String>(
            onSelected: _onSortChanged,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'sender_asc', child: Text('По отправителю (А-Я)')),
              PopupMenuItem(value: 'sender_desc', child: Text('По отправителю (Я-А)')),
              PopupMenuItem(value: 'type', child: Text('По типу сообщения')),
              PopupMenuItem(value: 'read_status', child: Text('По статусу прочтения')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск и сортировка
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Поиск по отправителю или содержимому',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearchChanged,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Найдено: ${_filteredMessages.length} сообщений',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Text(
                        _getSortButtonText(),
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredMessages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Нет сообщений'
                        : 'Сообщения не найдены',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  if (_searchQuery.isNotEmpty)
                    Text(
                      'По запросу "$_searchQuery" ничего не найдено',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredMessages.length,
              itemExtent: 96.0,
              itemBuilder: (context, index) {
                final message = _filteredMessages[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageDetailScreen(message: message),
                      ),
                    ).then((_) {
                      _loadMessages();
                    });
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Иконка типа сообщения
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: message is TextMessage ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              message is TextMessage ? Icons.text_snippet : Icons.photo,
                              color: message is TextMessage ? Colors.blue : Colors.green,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),

                          // Основной контент
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Первая строка: отправитель и время
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        message.sender,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      _formatTime(message.timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),

                                // Содержимое сообщения
                                Text(
                                  message is TextMessage
                                      ? (message as TextMessage).originalText
                                      : '[${(message as MediaMessage).mediaType}] ${(message as MediaMessage).mediaUrl}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 6),

                                // Статус прочтения и дата
                                Row(
                                  children: [
                                    // Статус прочтения
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: message.isRead ? Colors.green : Colors.grey,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          message.isRead ? 'Прочитано' : 'Не прочитано',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: message.isRead ? Colors.green : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 12),

                                    // Полная дата
                                    Text(
                                      _formatDate(message.timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),

                          // Кнопки действий в одном ряду
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Кнопка статуса прочтения
                              Container(
                                width: 36,
                                height: 36,
                                child: IconButton(
                                  icon: Icon(
                                    message.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                                    color: message.isRead ? Colors.green : Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => _markAsRead(message),
                                  padding: EdgeInsets.zero,
                                ),
                              ),

                              // Кнопка удаления
                              Container(
                                width: 36,
                                height: 36,
                                child: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _deleteMessage(message.id),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Сегодня';
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return 'Вчера';
    } else {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}