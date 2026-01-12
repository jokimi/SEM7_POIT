import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/userModel.dart';
import '../models/bookModel.dart';
import '../models/favoriteModel.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String _encryptionKeyPref = 'hive_encryption_key';
  static const String _secondKeyPref = 'hive_second_key';
  late Box _userBox;
  late Box _bookBox;
  late Box _favoriteBox;

  // Ключи для шифрования
  late List<int> _encryptionKey;
  late List<int> _secondKey;

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(BookAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(FavoriteAdapter());
    }

    // Генерация/загрузка ключей шифрования
    await _initializeEncryptionKeys();

    // Открытие боксов с шифрованием
    _userBox = await Hive.openBox('users',
        encryptionCipher: HiveAesCipher(_encryptionKey));

    _bookBox = await Hive.openBox('books',
        encryptionCipher: HiveAesCipher(_encryptionKey));

    _favoriteBox = await Hive.openBox('favorites',
        encryptionCipher: HiveAesCipher(_encryptionKey));

    await _initializeDemoData();
  }

  // Метод для полной очистки всех боксов Hive
  Future<void> _clearAllBoxes() async {
    try {
      if (Hive.isBoxOpen('users')) {
        await Hive.box('users').close();
      }
      if (Hive.isBoxOpen('books')) {
        await Hive.box('books').close();
      }
      if (Hive.isBoxOpen('favorites')) {
        await Hive.box('favorites').close();
      }
      await Hive.deleteBoxFromDisk('users');
      await Hive.deleteBoxFromDisk('books');
      await Hive.deleteBoxFromDisk('favorites');
    } catch (e) { }
  }

  Future<void> _initializeEncryptionKeys() async {
    final prefs = await SharedPreferences.getInstance();

    // Генерация основного ключа
    if (prefs.containsKey(_encryptionKeyPref)) {
      final keyString = prefs.getString(_encryptionKeyPref)!;
      _encryptionKey = base64.decode(keyString);
    } else {
      _encryptionKey = Hive.generateSecureKey();
      await prefs.setString(
        _encryptionKeyPref,
        base64.encode(_encryptionKey),
      );
    }

    // Генерация второго ключа для демонстрации
    if (prefs.containsKey(_secondKeyPref)) {
      final keyString = prefs.getString(_secondKeyPref)!;
      _secondKey = base64.decode(keyString);
    } else {
      _secondKey = Hive.generateSecureKey();
      await prefs.setString(
        _secondKeyPref,
        base64.encode(_secondKey),
      );
    }
  }

  Future<void> _initializeDemoData() async {
    final adminUser = User(
      id: '1',
      name: 'jokimi',
      email: 'jokimims@gmail.com',
      role: 1,
      createdAt: DateTime.now(),
      avatarPath: 'assets/avatar.jpg',
    );

    final regularUser = User(
      id: '2',
      name: 'Anna Lawrence',
      email: 'alawrence@gmail.com',
      role: 0,
      createdAt: DateTime.now(),
      avatarPath: 'assets/anna.jpg',
    );

    await _userBox.put(adminUser.id, adminUser);
    await _userBox.put(regularUser.id, regularUser);

    if (_bookBox.isEmpty) {
      final demoBooks = [
        Book(
          id: '1',
          title: 'Timber',
          author: 'Peter Dauvergne',
          description: 'A comprehensive study of timber industry and sustainability.',
          imagePath: 'assets/timber.jpg',
          rating: 8.5,
          reviewsCount: 89,
          categories: ['Nature', 'Science'],
          isLiked: false,
          createdAt: DateTime.now(),
          createdBy: '1',
        ),
        Book(
          id: '2',
          title: 'Sweet Bird of Youth',
          author: 'Tennessee Williams',
          description: 'A powerful drama about aging and lost opportunities.',
          imagePath: 'assets/sweetbirdofyouth.jpg',
          rating: 9.1,
          reviewsCount: 156,
          categories: ['Drama', 'Classic'],
          isLiked: false,
          createdAt: DateTime.now(),
          createdBy: '1',
        ),
        Book(
          id: '3',
          title: 'Early Bird',
          author: 'Rodney Rothman',
          description: 'A humorous take on early retirement and new beginnings.',
          imagePath: 'assets/earlybird.jpg',
          rating: 7.8,
          reviewsCount: 67,
          categories: ['Humor', 'Biography'],
          isLiked: false,
          createdAt: DateTime.now(),
          createdBy: '1',
        ),
        Book(
          id: '4',
          title: 'The Crow\'s Vow',
          author: 'Susan Briscoe',
          description: 'An extraordinarily moving book-length sequence that follows the story of a marriage come undone.',
          imagePath: 'assets/thecrowsvow.jpg',
          rating: 9.2,
          reviewsCount: 203,
          categories: ['Travelers', 'Literature'],
          isLiked: false,
          createdAt: DateTime.now(),
          createdBy: '1',
        ),
        Book(
          id: '5',
          title: 'Sea of Poppies',
          author: 'Amitav Ghosh',
          description: 'The first in an epic trilogy, Sea of Poppies is a stunningly vibrant work that brings alive the nineteenth-century opium trade.',
          imagePath: 'assets/seaofpoppies.jpg',
          rating: 8.7,
          reviewsCount: 145,
          categories: ['Fiction', 'Adventure'],
          isLiked: false,
          createdAt: DateTime.now(),
          createdBy: '1',
        ),
      ];

      for (final book in demoBooks) {
        await _bookBox.put(book.id, book);
      }
    }
  }

  // Методы для пользователей

  List<User> getUsers() {
    return _userBox.values.cast<User>().toList();
  }

  User? getUser(String id) {
    return _userBox.get(id);
  }

  Future<void> addUser(User user) async {
    await _userBox.put(user.id, user);
  }

  Future<void> deleteUser(String id) async {
    await _userBox.delete(id);
  }

  // Методы для книг

  List<Book> getBooks() {
    return _bookBox.values.cast<Book>().toList();
  }

  Book? getBook(String id) {
    return _bookBox.get(id);
  }

  Future<void> addBook(Book book) async {
    await _bookBox.put(book.id, book);
  }

  Future<void> updateBook(Book book) async {
    await _bookBox.put(book.id, book);
  }

  Future<void> deleteBook(String id) async {
    await _bookBox.delete(id);
  }

  // Методы для избранного

  List<Favorite> getFavorites(String userId) {
    return _favoriteBox.values
        .cast<Favorite>()
        .where((fav) => fav.userId == userId)
        .toList();
  }

  Future<void> addToFavorites(String userId, String bookId) async {
    final favorite = Favorite(
      id: '${userId}_$bookId',
      userId: userId,
      bookId: bookId,
      addedAt: DateTime.now(),
    );
    await _favoriteBox.put(favorite.id, favorite);
  }

  Future<void> removeFromFavorites(String userId, String bookId) async {
    await _favoriteBox.delete('${userId}_$bookId');
  }

  bool isBookInFavorites(String userId, String bookId) {
    return _favoriteBox.containsKey('${userId}_$bookId');
  }

  // Методы для демонстрации шифрования

  Future<String> demonstrateWrongKey() async {
    try {
      final wrongBox = await Hive.openBox('wrong_demo',
          encryptionCipher: HiveAesCipher(_secondKey));
      await wrongBox.put('test', 'data');
      await wrongBox.close();

      final booksCount = _bookBox.length;

      return 'Демонстрация шифрования: Успешно! Книг в базе: $booksCount';
    } catch (e) {
      return 'Ошибка при демонстрации шифрования: $e';
    }
  }

  Future<String> demonstrateWrongKeyOnBooks() async {
    try {
      if (_bookBox.isEmpty) {
        await _initializeDemoData();
      }

      // Сохраняем все данные из бокса для восстановления
      final originalCount = _bookBox.length;
      final originalBooks = <String, Book>{};
      for (final key in _bookBox.keys) {
        final book = _bookBox.get(key);
        if (book != null) {
          originalBooks[key.toString()] = book as Book;
        }
      }
      
      // Получаем путь к файлу бокса ДО закрытия
      String? boxFilePath;
      try {
        boxFilePath = _bookBox.path;
      } catch (_) {
        // Игнорируем ошибки
      }
      
      // Закрываем текущий бокс с правильным ключом
      await _bookBox.close();

      String outcome;
      String errorDetails = '';
      
      try {
        if (Hive.isBoxOpen('books')) {
          await Hive.box('books').close();
        }
        
        final wrongBox = await Hive.openBox(
          'books',
          encryptionCipher: HiveAesCipher(_secondKey),
        );
        
        // Количество книг с неправильным ключом
        final wrongKeyCount = wrongBox.length;

        try {
          if (wrongBox.isEmpty) {
            errorDetails = 'Бокс открыт, но данные недоступны (бокс пустой)';
            outcome = 'ДЕМОНСТРАЦИЯ ЗАЩИТЫ:\n\nБокс открыт с НЕВЕРНЫМ ключом!\n\nИсходное количество книг: $originalCount\nКоличество с неверным ключом: $wrongKeyCount\n\n$errorDetails\n\nЭто подтверждает, что зашифрованные данные защищены неправильным ключом.';
          } else {
            final testKey = wrongBox.keys.first;
            try {
              final value = wrongBox.get(testKey);
              if (value == null) {
                errorDetails = 'Данные не могут быть расшифрованы';
                outcome = 'ДЕМОНСТРАЦИЯ ЗАЩИТЫ:\n\nИсходное количество книг: $originalCount\nКоличество с неверным ключом: $wrongKeyCount\n\nПри чтении с неверным ключом данные недоступны!\n\n$errorDetails';
              } else {
                // Это не должно происходить, но если произошло - показываем предупреждение
                outcome = 'ВНИМАНИЕ: Бокс вернул данные с неверным ключом. Это может означать проблему с шифрованием.';
              }
            } catch (readError) {
              errorDetails = readError.toString();
              outcome = 'ОШИБКА ПРИ ЧТЕНИИ С НЕВЕРНЫМ КЛЮЧОМ (ожидаемо):\n\nИсходное количество книг: $originalCount\nКоличество с неверным ключом: $wrongKeyCount\n\n$errorDetails\n\nЭто подтверждает, что данные зашифрованы и защищены!';
            }
          }
        } catch (checkError) {
          errorDetails = checkError.toString();
          outcome = '✓ ОШИБКА ПРИ ПРОВЕРКЕ ДАННЫХ С НЕВЕРНЫМ КЛЮЧОМ:\n\nИсходное количество книг: $originalCount\nКоличество с неверным ключом: $wrongKeyCount\n\n$errorDetails\n\nЭто подтверждает, что данные зашифрованы и защищены!';
        }
        
        await wrongBox.close();
        
        // Удаляем поврежденный бокс (если он был создан с неправильным ключом)
        try {
          if (Hive.isBoxOpen('books')) {
            await Hive.box('books').close();
          }
          await Hive.deleteBoxFromDisk('books');
        } catch (_) {
        }
        
      } catch (openError) {
        errorDetails = openError.toString();
        outcome = 'ОШИБКА ПРИ ОТКРЫТИИ С НЕВЕРНЫМ КЛЮЧОМ:\n\n$errorDetails\n\nДанные зашифрованы и защищены!';
      }

      // Восстанавливаем рабочее состояние: открываем с правильным ключом
      _bookBox = await Hive.openBox(
        'books',
        encryptionCipher: HiveAesCipher(_encryptionKey),
      );
      
      // Восстанавливаем данные, если они были потеряны
      if (_bookBox.isEmpty && originalBooks.isNotEmpty) {
        for (final entry in originalBooks.entries) {
          await _bookBox.put(entry.key, entry.value);
        }
      }
      
      // Проверяем, что данные восстановились
      final restoredCount = _bookBox.length;
      
      // Формируем сообщение о восстановлении
      if (restoredCount == originalCount) {
        outcome += '\n\nВОССТАНОВЛЕНИЕ УСПЕШНО:\nБокс открыт с правильным ключом.\nКниг в базе: $restoredCount';
      } else if (restoredCount == 0 && originalBooks.isNotEmpty) {
        // Данные были потеряны, восстанавливаем их
        for (final entry in originalBooks.entries) {
          await _bookBox.put(entry.key, entry.value);
        }
        final finalCount = _bookBox.length;
        outcome += '\n\nВОССТАНОВЛЕНИЕ УСПЕШНО:\nБокс открыт с правильным ключом.\nДанные восстановлены из резервной копии.\nКниг в базе: $finalCount (было: $originalCount)';
      } else {
        outcome += '\n\nВОССТАНОВЛЕНИЕ:\nБокс открыт с правильным ключом.\nКниг в базе: $restoredCount (было: $originalCount)\n\n' +
                   (restoredCount < originalCount ? 'Некоторые данные могли быть потеряны.' : 'Количество книг восстановлено.');
      }

      return outcome;
    } catch (e) {
      // Пытаемся восстановиться на случай сбоев
      if (!Hive.isBoxOpen('books')) {
        try {
          _bookBox = await Hive.openBox(
            'books',
            encryptionCipher: HiveAesCipher(_encryptionKey),
          );
        } catch (_) {
          // Если не удалось восстановить, попробуем пересоздать
        }
      }
      return 'Сбой демонстрации неверного ключа: $e';
    }
  }

  // Метод для сжатия данных
  Future<void> compressData() async {
    await _bookBox.compact();
    await _userBox.compact();
    await _favoriteBox.compact();
  }

  // Получение статистики
  Map<String, int> getStats() {
    return {
      'users': _userBox.length,
      'books': _bookBox.length,
      'favorites': _favoriteBox.length,
    };
  }
}