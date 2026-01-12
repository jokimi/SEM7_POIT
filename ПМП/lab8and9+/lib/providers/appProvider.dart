import 'package:flutter/foundation.dart';
import '../models/userModel.dart';
import '../models/bookModel.dart';
import '../services/hiveService.dart';

class AppProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();

  User? _currentUser;
  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  String _searchQuery = '';
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  List<Book> get books => _filteredBooks;
  List<Book> get allBooks => _books;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  bool get isAdmin => _currentUser?.role == 1;
  bool get canManageBooks => isAdmin;

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _hiveService.init();
      _loadUsers();
      final users = getUsers();
      if (users.isNotEmpty) {
        _currentUser = users.first;
      }
      _loadBooks();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> switchUser(String userId) async {
    _currentUser = _hiveService.getUser(userId);
    _loadBooks();
    notifyListeners();
  }

  List<User> getUsers() {
    return _hiveService.getUsers();
  }

  void _loadUsers() {
  }

  void _loadBooks() async {
    _books = _hiveService.getBooks();
    
    // Синхронизируем поле isLiked с favorites текущего пользователя
    if (_currentUser != null) {
      final favoriteIds = _hiveService
          .getFavorites(_currentUser!.id)
          .map((fav) => fav.bookId)
          .toSet();
      for (int i = 0; i < _books.length; i++) {
        final book = _books[i];
        final shouldBeLiked = favoriteIds.contains(book.id);
        if (book.isLiked != shouldBeLiked) {
          final updatedBook = book.copyWith(isLiked: shouldBeLiked);
          _books[i] = updatedBook;
          await _hiveService.updateBook(updatedBook);
        }
      }
    } else {
      for (int i = 0; i < _books.length; i++) {
        if (_books[i].isLiked) {
          final updatedBook = _books[i].copyWith(isLiked: false);
          _books[i] = updatedBook;
          await _hiveService.updateBook(updatedBook);
        }
      }
    }
    
    _filteredBooks = _books;
    notifyListeners();
  }

  void searchBooks(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredBooks = _books;
    } else {
      _filteredBooks = _books.where((book) {
        return book.title.toLowerCase().contains(query.toLowerCase()) ||
            book.author.toLowerCase().contains(query.toLowerCase()) ||
            book.categories.any((category) =>
                category.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    }
    notifyListeners();
  }

  Future<void> addBook(Book book) async {
    _setLoading(true);
    try {
      await _hiveService.addBook(book);
      _loadBooks();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateBook(Book book) async {
    _setLoading(true);
    try {
      await _hiveService.updateBook(book);
      _loadBooks();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteBook(String bookId) async {
    _setLoading(true);
    try {
      await _hiveService.deleteBook(bookId);
      _loadBooks();
    } finally {
      _setLoading(false);
    }
  }

  bool isBookInFavorites(String bookId) {
    if (_currentUser == null) return false;
    return _hiveService.isBookInFavorites(_currentUser!.id, bookId);
  }

  Future<void> toggleFavorite(String bookId) async {
    if (_currentUser == null) return;

    try {
      if (_hiveService.isBookInFavorites(_currentUser!.id, bookId)) {
        await _hiveService.removeFromFavorites(_currentUser!.id, bookId);
      } else {
        await _hiveService.addToFavorites(_currentUser!.id, bookId);
      }

      final bookIndex = _books.indexWhere((b) => b.id == bookId);
      if (bookIndex != -1) {
        final book = _books[bookIndex];
        final updatedBook = book.copyWith(
          isLiked: !book.isLiked,
        );
        _books[bookIndex] = updatedBook;
        await _hiveService.updateBook(updatedBook);
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  List<Book> getFavoriteBooks() {
    if (_currentUser == null) return [];

    final favoriteIds = _hiveService
        .getFavorites(_currentUser!.id)
        .map((fav) => fav.bookId)
        .toList();

    return _books.where((book) => favoriteIds.contains(book.id)).toList();
  }

  Future<String> demonstrateEncryption() async {
    return await _hiveService.demonstrateWrongKeyOnBooks();
  }

  Future<void> compressData() async {
    _setLoading(true);
    try {
      await _hiveService.compressData();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Map<String, int> getStats() {
    return _hiveService.getStats();
  }

  Book createDemoBook({
    required String title,
    required String author,
    String description = '',
    String imagePath = 'assets/default_book.jpg',
    double rating = 0.0,
    int reviewsCount = 0,
    List<String> categories = const [''],
    bool isLiked = false,
  }) {
    return Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      author: author,
      description: description,
      imagePath: imagePath,
      rating: rating,
      reviewsCount: reviewsCount,
      categories: categories,
      isLiked: isLiked,
      createdAt: DateTime.now(),
      createdBy: _currentUser?.id,
    );
  }
}