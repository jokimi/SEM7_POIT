// models/message.dart
abstract class MessageSender {
  void sendMessage(String text, {required String recipient});
  Future<void> sendBroadcast(List<String> recipients, String message);
}

abstract class Message {
  final String id;
  final DateTime timestamp;
  final String sender;
  bool get isRead;
  void markAsRead({bool read = true});

  Message(this.id, this.sender, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  String get content;

  static int messageCount = 0;

  static String generateId() => 'msg_${DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> toMap();
  factory Message.fromMap(Map<String, dynamic> map) {
    // TODO: implement Message.fromMap
    throw UnimplementedError();
  }
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

  TextMessage(String text, String sender, {bool isEncrypted = false, String? id})
      : _text = text,
        _isEncrypted = isEncrypted,
        super(id ?? Message.generateId(), sender, timestamp: id == null ? null : DateTime.now()) {
    Message.messageCount++;
  }

  TextMessage.encrypted(String text, String sender, {String? id})
      : this(text, sender, isEncrypted: true, id: id);

  @override
  String get content => _isEncrypted ? _encrypt(_text) : _text;

  String get originalText => _text;
  bool get isEncrypted => _isEncrypted;

  @override
  bool get isRead => _isRead;

  @override
  void markAsRead({bool read = true}) {
    _isRead = read;
  }

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

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': 'text',
      'sender': sender,
      'text': _text,
      'isEncrypted': _isEncrypted ? 1 : 0,
      'isRead': _isRead ? 1 : 0,
      'deliveryStatus': _deliveryStatus,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  static TextMessage fromMap(Map<String, dynamic> map) {
    return TextMessage(
      map['text'],
      map['sender'],
      isEncrypted: map['isEncrypted'] == 1,
      id: map['id'],
    )
      .._isRead = map['isRead'] == 1
      .._deliveryStatus = map['deliveryStatus'];
  }
}

class MediaMessage extends Message {
  final String mediaUrl;
  final String mediaType;
  bool _isRead = false;

  MediaMessage(
      this.mediaUrl,
      this.mediaType,
      String sender, {
        String? id,
      }) : super(id ?? Message.generateId(), sender, timestamp: id == null ? null : DateTime.now());

  @override
  String get content => '[$mediaType] $mediaUrl';

  @override
  bool get isRead => _isRead;

  @override
  void markAsRead({bool read = true}) {
    _isRead = read;
  }

  void downloadMedia({
    String savePath = '/downloads/',
    void Function(double progress)? onProgress,
  }) {
    print('Скачивание $mediaUrl в $savePath');
    onProgress?.call(75.5);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': 'media',
      'sender': sender,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'isRead': _isRead ? 1 : 0,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  static MediaMessage fromMap(Map<String, dynamic> map) {
    return MediaMessage(
      map['mediaUrl'],
      map['mediaType'],
      map['sender'],
      id: map['id'],
    ).._isRead = map['isRead'] == 1;
  }
}