import 'dart:async';
import 'dart:convert';

mixin TimestampMixin {
  DateTime get timestamp => DateTime.now();
  String get formattedTime => '${timestamp.hour}:${timestamp.minute}';
}

mixin EncryptionMixin {
  String encrypt(String text, {int shift = 1}) {
    return String.fromCharCodes(text.codeUnits.map((char) => char + shift));
  }

  String decrypt(String text, {int shift = 1}) {
    return String.fromCharCodes(text.codeUnits.map((char) => char - shift));
  }
}

abstract class Message with TimestampMixin implements Comparable<Message> {
  final String id;
  final String sender;

  Message(this.id, this.sender);

  String get content;

  @override
  int compareTo(Message other) => timestamp.compareTo(other.timestamp);

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'timestamp': timestamp.toIso8601String(),
    'type': runtimeType.toString(),
  };
}

class TextMessage extends Message with EncryptionMixin {
  final String text;
  final bool isEncrypted;

  TextMessage(this.text, String sender, {this.isEncrypted = false})
      : super('msg_${DateTime.now().millisecondsSinceEpoch}', sender);

  @override
  String get content => isEncrypted ? decrypt(text) : text;

  String get encryptedContent => isEncrypted ? text : encrypt(text);

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'text': text,
    'isEncrypted': isEncrypted,
    'content': content,
  };

  @override
  String toString() {
    final preview = content.length > 20 ? '${content.substring(0, 20)}...' : content;
    return 'TextMessage from $sender: $preview';
  }
}

class MessageIterator implements Iterator<Message> {
  final List<Message> _messages;
  int _currentIndex = -1;

  MessageIterator(this._messages);

  @override
  Message get current => _messages[_currentIndex];

  @override
  bool moveNext() {
    if (_currentIndex < _messages.length - 1) {
      _currentIndex++;
      return true;
    }
    return false;
  }
}

class MessageCollection extends Iterable<Message> {
  final List<Message> _messages = [];

  void add(Message message) => _messages.add(message);
  void remove(String id) => _messages.removeWhere((m) => m.id == id);

  @override
  Iterator<Message> get iterator => MessageIterator(_messages);

  void sortByTimestamp() => _messages.sort();

  String toJson() => jsonEncode(_messages.map((m) => m.toJson()).toList());

  static MessageCollection fromJson(String jsonString) {
    final collection = MessageCollection();
    final List<dynamic> data = jsonDecode(jsonString);

    for (var item in data) {
      if (item['type'] == 'TextMessage') {
        collection.add(TextMessage(
          item['text'],
          item['sender'],
          isEncrypted: item['isEncrypted'],
        ));
      }
    }

    return collection;
  }
}

class MessageService {
  final StreamController<Message> _singleController = StreamController<Message>();
  final StreamController<Message> _broadcastController = StreamController<Message>.broadcast();

  Stream<Message> get messageStream => _singleController.stream;
  Stream<Message> get broadcastStream => _broadcastController.stream;

  Future<void> sendMessageAsync(Message message) async {
    print('Начало отправки: ${message.content}');

    await Future.delayed(Duration(seconds: 1));
    await _processMessage(message);

    _singleController.add(message);
    _broadcastController.add(message);

    print('Сообщение отправлено: ${message.content}');
  }

  Future<void> _processMessage(Message message) async {
    await Future.delayed(Duration(milliseconds: 500));
    print('Сообщение обработано: ${message.id}');
  }

  Future<MessageCollection> loadMessagesAsync() async {
    print('Загрузка сообщений...');

    return await Future.delayed(Duration(seconds: 2), () {
      final collection = MessageCollection();
      collection.add(TextMessage('Привет!', 'Alice'));
      collection.add(TextMessage('Как дела?', 'Bob'));
      collection.add(TextMessage('Секретное сообщение', 'Eve', isEncrypted: true));
      return collection;
    });
  }

  void dispose() {
    _singleController.close();
    _broadcastController.close();
  }
}

class MessengerDemo {
  final MessageService _service = MessageService();

  Future<void> runDemo() async {
    await _demoAsyncMethods();
    await _demoStreams();
    _service.dispose();
  }

  Future<void> _demoAsyncMethods() async {
    print('\nАсинхронные методы и Future:');

    try {
      final messages = await _service.loadMessagesAsync();
      print('* Await: ${messages.length} сообщений');
    } catch (e) {
      print('* Ошибка: $e');
    }

    final futures = [
      _service.sendMessageAsync(TextMessage('Сообщение 1', 'User1')),
      _service.sendMessageAsync(TextMessage('Сообщение 2', 'User2')),
      _service.sendMessageAsync(TextMessage('Сообщение 3', 'User3')),
    ];

    await Future.wait(futures);
  }

  Future<void> _demoStreams() async {
    print('\nДемонстрация Streams:');

    final subscription = _service.messageStream.listen(
          (message) => print('* Single Stream: ${message.content}'),
      onError: (error) => print('* Stream error: $error'),
      onDone: () => print('* Single stream closed'),
    );

    final broadcastSub = _service.broadcastStream.listen(
          (message) => print('* Broadcast: ${message.sender}'),
    );

    await _service.sendMessageAsync(TextMessage('Stream test 1', 'Streamer'));
    await Future.delayed(Duration(seconds: 1));
    await _service.sendMessageAsync(TextMessage('Stream test 2', 'Streamer'));

    await Future.delayed(Duration(seconds: 1));
    await subscription.cancel();
    await broadcastSub.cancel();
  }
}

void main() async {
  final demo = MessengerDemo();
  await demo.runDemo();
}