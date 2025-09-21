abstract class MessageSender {
  void sendMessage(String text, {required String recipient});
  Future<void> sendBroadcast(List<String> recipients, String message);
}

abstract class Message {
  final String id;
  final DateTime timestamp;
  final String sender;

  Message(this.id, this.sender, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  String get content;

  void markAsRead({bool read = true});

  static int messageCount = 0;

  static String generateId() => 'msg_${DateTime.now().millisecondsSinceEpoch}';
}

class TextMessage extends Message implements MessageSender {
  final String _text;
  final bool _isEncrypted;
  bool _isRead = false;

  static final int maxLength = 1000;

  int _deliveryStatus = 0;

  int get deliveryStatus => _deliveryStatus;

  set deliveryStatus(int status) {
    if (status >= 0 && status <= 2) {
      _deliveryStatus = status;
    } else {
      throw ArgumentError('Значение статуса должно быть от 0 до 2');
    }
  }

  TextMessage(String text, String sender, {bool isEncrypted = false})
      : _text = text,
        _isEncrypted = isEncrypted,
        super(Message.generateId(), sender) {
    Message.messageCount++;
  }

  TextMessage.encrypted(String text, String sender)
      : this(text, sender, isEncrypted: true);

  @override
  String get content => _isEncrypted ? _encrypt(_text) : _text;

  @override
  void markAsRead({bool read = true}) {
    _isRead = read;
    print('Сообщение $id ${read ? 'просмотрено' : 'не просмотрено'}');
  }

  bool get isRead => _isRead;

  String _encrypt(String text) => String.fromCharCodes(
      text.codeUnits.map((char) => char + 1));

  void resendMessage({
    required String newRecipient,
    bool encrypt = false,
    Function(String)? onComplete,
  }) {
    print('Пересылка сообщения $newRecipient (encrypted: $encrypt)');
    onComplete?.call('Сообщение переслано успешно');
  }

  void editMessage(String newText, [String? editNote]) {
    print('Редактирование сообщения: $newText ${editNote != null ? '($editNote)' : ''}');
  }

  @override
  void sendMessage(String text, {required String recipient}) {
    print('Отправка сообщения $recipient: $text');
    _deliveryStatus = 1;
  }

  @override
  Future<void> sendBroadcast(List<String> recipients, String message) async {
    print('Рассылка сообщения ${recipients.length} получателям');
    for (var recipient in recipients) {
      await Future.delayed(Duration(milliseconds: 100));
      print('Отправлено получателю $recipient');
    }
    _deliveryStatus = 2;
  }

  void processMessage(
      String text, {
        required String Function(String) transformer,
        void Function(String)? onProcessed,
      }) {
    final processed = transformer(text);
    print('Обработано сообщение: $processed');
    onProcessed?.call(processed);
  }

  @override
  String toString() => 'Текстовое сообщение от $sender: ${
      content.length > 20 ? content.substring(0, 20) + '...' : content
  }';
}

class MediaMessage extends Message {
  final String mediaUrl;
  final String mediaType;
  final int fileSize;
  bool _isRead = false;

  MediaMessage(
      this.mediaUrl,
      this.mediaType,
      String sender, {
        this.fileSize = 0,
      }) : super(Message.generateId(), sender);

  @override
  String get content => '[$mediaType] $mediaUrl';

  // Переопределение абстрактного метода для MediaMessage
  @override
  void markAsRead({bool read = true}) {
    _isRead = read;
    print('Медиа-сообщение $id ${read ? 'просмотрено' : 'не просмотрено'}');
  }

  bool get isRead => _isRead;

  void downloadMedia({
    String savePath = '/downloads/',
    void Function(double progress)? onProgress,
  }) {
    print('Скачивание $mediaUrl в $savePath');
    onProgress?.call(75.5);
  }
}

class MessengerDemo {
  void runDemo() {
    _demoCollections();
    _demoLoops();
    _demoExceptionHandling();
  }

  void _demoCollections() {
    print('\n1. Работа с коллекциями:\n');

    List<Message> messages = [
      TextMessage('Hello!', 'Alice'),
      TextMessage('How are you?', 'Bob'),
      TextMessage.encrypted('Here\'s my secret', 'Eve'),
      MediaMessage('https://example.com/photo.jpg', 'image', 'Charlie'),
    ];

    print('Сообщений: ${messages.length}');
    messages.forEach((msg) {
      print('  - $msg');
      msg.markAsRead(); // Демонстрация переопределенного метода
    });
  }

  void _demoLoops() {
    print('\n2. Работа с break/continue:\n');

    final messages = List.generate(5, (i) => TextMessage('Сообщение $i', 'User$i'));

    for (var i = 0; i < messages.length; i++) {
      if (i == 2) {
        continue;
      }
      if (i == 4) {
        break;
      }

      print('  Обработка сообщения $i: ${messages[i].content}');
      messages[i].markAsRead(read: i % 2 == 0);
    }
  }

  void _demoExceptionHandling() {
    print('\n3. Обработка исключений:\n');

    try {
      final message = TextMessage('Тест', 'User1');
      message.deliveryStatus = 5;
    } on ArgumentError catch (e) {
      print('  Поймано ArgumentError: ${e.message}');
    } catch (e) {
      print('  Поймано исключение: $e');
    } finally {
      print('  Блок finally выполнен');
    }
  }
}

void main() {
  final demo = MessengerDemo();
  demo.runDemo();
}