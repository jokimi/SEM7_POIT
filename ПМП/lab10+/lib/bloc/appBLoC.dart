import 'dart:async';
import 'package:bloc/bloc.dart';
import 'appEvent.dart';
import 'appState.dart';
import '../models/bookModel.dart';
import '../models/userModel.dart';
import '../services/hiveService.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final HiveService _hiveService = HiveService();

  AppBloc() : super(const AppInitial()) {
    on<AppInitialized>(_onAppInitialized);
    on<UserSwitched>(_onUserSwitched);
    on<BooksSearched>(_onBooksSearched);
    on<BookAdded>(_onBookAdded);
    on<BookUpdated>(_onBookUpdated);
    on<BookDeleted>(_onBookDeleted);
    on<FavoriteToggled>(_onFavoriteToggled);
    on<DataCompressed>(_onDataCompressed);
    on<EncryptionDemonstrated>(_onEncryptionDemonstrated);
  }

  Future<void> _onAppInitialized(
    AppInitialized event,
    Emitter<AppState> emit,
  ) async {
    emit(const AppLoading());
    try {
      await _hiveService.init();
      final users = _hiveService.getUsers();
      User? currentUser;
      if (users.isNotEmpty) {
        currentUser = users.first;
      }
      final books = await _loadBooks(currentUser);
      emit(AppLoaded(
        currentUser: currentUser,
        books: books,
        filteredBooks: books,
        searchQuery: '',
      ));
    } catch (e) {
      emit(AppError(e.toString()));
    }
  }

  Future<void> _onUserSwitched(
    UserSwitched event,
    Emitter<AppState> emit,
  ) async {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      final newUser = _hiveService.getUser(event.userId);
      final books = await _loadBooks(newUser);
      emit(currentState.copyWith(
        currentUser: newUser,
        books: books,
        filteredBooks: books,
        searchQuery: '',
      ));
    }
  }

  void _onBooksSearched(BooksSearched event, Emitter<AppState> emit) {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      List<Book> filteredBooks;
      if (event.query.isEmpty) {
        filteredBooks = currentState.books;
      } else {
        filteredBooks = currentState.books.where((book) {
          return book.title.toLowerCase().contains(event.query.toLowerCase()) ||
              book.author.toLowerCase().contains(event.query.toLowerCase()) ||
              book.categories.any((category) =>
                  category.toLowerCase().contains(event.query.toLowerCase()));
        }).toList();
      }
      emit(currentState.copyWith(
        filteredBooks: filteredBooks,
        searchQuery: event.query,
      ));
    }
  }

  Future<void> _onBookAdded(BookAdded event, Emitter<AppState> emit) async {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      emit(currentState.copyWith(isLoading: true));
      try {
        await _hiveService.addBook(event.book);
        final books = await _loadBooks(currentState.currentUser);
        final filteredBooks = _applySearchFilter(books, currentState.searchQuery);
        emit(currentState.copyWith(
          books: books,
          filteredBooks: filteredBooks,
          isLoading: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoading: false));
        emit(AppError(e.toString()));
      }
    }
  }

  Future<void> _onBookUpdated(
    BookUpdated event,
    Emitter<AppState> emit,
  ) async {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      emit(currentState.copyWith(isLoading: true));
      try {
        await _hiveService.updateBook(event.book);
        final books = await _loadBooks(currentState.currentUser);
        final filteredBooks = _applySearchFilter(books, currentState.searchQuery);
        emit(currentState.copyWith(
          books: books,
          filteredBooks: filteredBooks,
          isLoading: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoading: false));
        emit(AppError(e.toString()));
      }
    }
  }

  Future<void> _onBookDeleted(
    BookDeleted event,
    Emitter<AppState> emit,
  ) async {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      emit(currentState.copyWith(isLoading: true));
      try {
        await _hiveService.deleteBook(event.bookId);
        final books = await _loadBooks(currentState.currentUser);
        final filteredBooks = _applySearchFilter(books, currentState.searchQuery);
        emit(currentState.copyWith(
          books: books,
          filteredBooks: filteredBooks,
          isLoading: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoading: false));
        emit(AppError(e.toString()));
      }
    }
  }

  Future<void> _onFavoriteToggled(
    FavoriteToggled event,
    Emitter<AppState> emit,
  ) async {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      if (currentState.currentUser == null) return;

      try {
        if (_hiveService.isBookInFavorites(currentState.currentUser!.id, event.bookId)) {
          await _hiveService.removeFromFavorites(
            currentState.currentUser!.id,
            event.bookId,
          );
        } else {
          await _hiveService.addToFavorites(
            currentState.currentUser!.id,
            event.bookId,
          );
        }

        // Обновляем состояние лайка в книге
        final bookIndex = currentState.books.indexWhere((b) => b.id == event.bookId);
        if (bookIndex != -1) {
          final book = currentState.books[bookIndex];
          final updatedBook = book.copyWith(isLiked: !book.isLiked);
          await _hiveService.updateBook(updatedBook);
        }

        final books = await _loadBooks(currentState.currentUser);
        final filteredBooks = _applySearchFilter(books, currentState.searchQuery);
        emit(currentState.copyWith(
          books: books,
          filteredBooks: filteredBooks,
        ));
      } catch (e) {
        emit(AppError(e.toString()));
      }
    }
  }

  Future<void> _onDataCompressed(
    DataCompressed event,
    Emitter<AppState> emit,
  ) async {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      emit(currentState.copyWith(isLoading: true));
      try {
        await _hiveService.compressData();
        emit(currentState.copyWith(isLoading: false));
      } catch (e) {
        emit(currentState.copyWith(isLoading: false));
        emit(AppError(e.toString()));
      }
    }
  }

  Future<void> _onEncryptionDemonstrated(
    EncryptionDemonstrated event,
    Emitter<AppState> emit,
  ) async {
  }

  Future<List<Book>> _loadBooks(User? currentUser) async {
    final books = _hiveService.getBooks();

    // Синхронизируем поле isLiked с боксом favorites текущего пользователя
    if (currentUser != null) {
      final favoriteIds = _hiveService
          .getFavorites(currentUser.id)
          .map((fav) => fav.bookId)
          .toSet();
      for (int i = 0; i < books.length; i++) {
        final book = books[i];
        final shouldBeLiked = favoriteIds.contains(book.id);
        if (book.isLiked != shouldBeLiked) {
          final updatedBook = book.copyWith(isLiked: shouldBeLiked);
          books[i] = updatedBook;
          await _hiveService.updateBook(updatedBook);
        }
      }
    } else {
      for (int i = 0; i < books.length; i++) {
        if (books[i].isLiked) {
          final updatedBook = books[i].copyWith(isLiked: false);
          books[i] = updatedBook;
          await _hiveService.updateBook(updatedBook);
        }
      }
    }

    return books;
  }

  List<Book> _applySearchFilter(List<Book> books, String query) {
    if (query.isEmpty) {
      return books;
    }
    return books.where((book) {
      return book.title.toLowerCase().contains(query.toLowerCase()) ||
          book.author.toLowerCase().contains(query.toLowerCase()) ||
          book.categories.any((category) =>
              category.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  List<User> getUsers() {
    return _hiveService.getUsers();
  }

  bool isBookInFavorites(String bookId) {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      if (currentState.currentUser == null) return false;
      return _hiveService.isBookInFavorites(
        currentState.currentUser!.id,
        bookId,
      );
    }
    return false;
  }

  List<Book> getFavoriteBooks() {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      if (currentState.currentUser == null) return [];

      final favoriteIds = _hiveService
          .getFavorites(currentState.currentUser!.id)
          .map((fav) => fav.bookId)
          .toList();

      return currentState.books
          .where((book) => favoriteIds.contains(book.id))
          .toList();
    }
    return [];
  }

  Map<String, int> getStats() {
    return _hiveService.getStats();
  }

  Future<String> demonstrateEncryption() async {
    return await _hiveService.demonstrateWrongKeyOnBooks();
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
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
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
        createdBy: currentState.currentUser?.id,
      );
    }
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
      createdBy: null,
    );
  }
}

