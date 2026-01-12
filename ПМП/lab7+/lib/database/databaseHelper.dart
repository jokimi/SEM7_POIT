// database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'messages.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
    CREATE TABLE messages(
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      sender TEXT NOT NULL,
      text TEXT,
      isEncrypted INTEGER,
      isRead INTEGER,
      deliveryStatus INTEGER,
      mediaUrl TEXT,
      mediaType TEXT,
      timestamp INTEGER
    )
  ''');
  }

  // CREATE
  Future<int> insertMessage(Message message) async {
    final db = await database;
    return await db.insert('messages', message.toMap());
  }

  // READ
  Future<List<Message>> getMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('messages');
    return maps.map((map) {
      if (map['type'] == 'text') {
        return TextMessage.fromMap(map);
      } else {
        return MediaMessage.fromMap(map);
      }
    }).toList();
  }

  // UPDATE
  Future<int> updateMessage(Message message) async {
    final db = await database;
    return await db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  // DELETE
  Future<int> deleteMessage(String id) async {
    final db = await database;
    return await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // SEARCH
  Future<List<Message>> searchMessages(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'sender LIKE ? OR text LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return maps.map((map) {
      if (map['type'] == 'text') {
        return TextMessage.fromMap(map);
      } else {
        return MediaMessage.fromMap(map);
      }
    }).toList();
  }

  // SORT
  Future<List<Message>> getMessagesSorted(String sortBy) async {
    final db = await database;
    String orderBy;
    switch (sortBy) {
      case 'sender':
        orderBy = 'sender ASC';
        break;
      case 'timestamp':
        orderBy = 'timestamp DESC';
        break;
      case 'type':
        orderBy = 'type ASC';
        break;
      default:
        orderBy = 'timestamp DESC';
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      orderBy: orderBy,
    );
    return maps.map((map) {
      if (map['type'] == 'text') {
        return TextMessage.fromMap(map);
      } else {
        return MediaMessage.fromMap(map);
      }
    }).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}