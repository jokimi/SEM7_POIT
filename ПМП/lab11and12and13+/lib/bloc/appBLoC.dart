import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'appEvent.dart';
import 'appState.dart';
import '../models/bookModel.dart';
import '../models/userModel.dart' as models;
import '../services/firestoreService.dart';
import '../services/authService.dart';
import '../services/databaseService.dart';
import '../services/analyticsService.dart';
import '../services/remoteConfigService.dart';
import '../services/hiveService.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final FirestoreService _firestoreService;
  final AuthService _authService;
  final DatabaseService _databaseService;
  final AnalyticsService _analyticsService;
  final RemoteConfigService _remoteConfigService;
  final HiveService _hiveService;
  final Stream<User?>? _authStateStreamOverride;
  
  StreamSubscription<List<Book>>? _booksSubscription;
  StreamSubscription<User?>? _authSubscription;

  AppBloc({
    FirestoreService? firestoreService,
    AuthService? authService,
    DatabaseService? databaseService,
    AnalyticsService? analyticsService,
    RemoteConfigService? remoteConfigService,
    HiveService? hiveService,
    Stream<User?>? authStateStreamOverride,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _authService = authService ?? AuthService(),
        _databaseService = databaseService ?? DatabaseService(),
        _analyticsService = analyticsService ?? AnalyticsService(),
        _remoteConfigService = remoteConfigService ?? RemoteConfigService(),
        _hiveService = hiveService ?? HiveService(),
        _authStateStreamOverride = authStateStreamOverride,
        super(const AppInitial()) {
    on<AppInitialized>(_onAppInitialized);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<BooksSearched>(_onBooksSearched);
    on<BookAdded>(_onBookAdded);
    on<BookUpdated>(_onBookUpdated);
    on<BookDeleted>(_onBookDeleted);
    on<FavoriteToggled>(_onFavoriteToggled);
    on<DataCompressed>(_onDataCompressed);
    on<EncryptionDemonstrated>(_onEncryptionDemonstrated);

    // Подписываемся на изменения состояния аутентификации
    final authStream = _authStateStreamOverride ?? _authService.authStateChanges;
    _authSubscription = authStream.listen((user) {
      add(AuthStateChanged(user));
    });
  }

  @override
  Future<void> close() {
    _booksSubscription?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onAppInitialized(
    AppInitialized event,
    Emitter<AppState> emit,
  ) async {
    emit(const AppLoading());
    try {
      // Инициализация Remote Config
      await _remoteConfigService.initialize();
      
      // Включаем офлайн синхронизацию Firestore
      await _firestoreService.enableOfflinePersistence();
      
      // Проверяем текущего пользователя
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        final userModel = await _firestoreService.getUser(firebaseUser.uid);
        if (userModel != null) {
          await _databaseService.initializeUserStatus();
          await _analyticsService.setUserId(firebaseUser.uid);
          await _loadBooksAndEmit(emit, userModel);
        } else {
          emit(const AppUnauthenticated());
        }
      } else {
        emit(const AppUnauthenticated());
      }
    } catch (e) {
      // Если ошибка связана с офлайном Firestore - пробуем загрузить данные из кэша
      if (e is FirebaseException && _isOfflineError(e)) {
        try {
          final cachedBooks = _hiveService.getBooks();
          if (cachedBooks.isNotEmpty) {
            // Пользователь в офлайне, но книги есть в кэше – отображаем их
            emit(const AppUnauthenticated());
            return;
          }
        } catch (_) {
          // Игнорируем ошибки кэша и падаем в общий обработчик ниже
        }
      }
      emit(AppError(e.toString()));
    }
  }

  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AppState> emit,
  ) async {
    if (event.user == null) {
      await _databaseService.cleanup();
      emit(const AppUnauthenticated());
    } else {
      try {
        final userModel = await _firestoreService.getUser(event.user!.uid);
        if (userModel != null) {
          await _databaseService.initializeUserStatus();
          await _analyticsService.setUserId(event.user!.uid);
          await _loadBooksAndEmit(emit, userModel);
        } else {
          emit(const AppUnauthenticated());
        }
      } catch (e) {
        if (e is FirebaseException && _isOfflineError(e)) {
          // При офлайне не показываем экран ошибки, остаёмся в текущем состоянии
          return;
        }
        emit(AppError(e.toString()));
      }
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AppState> emit,
  ) async {
    emit(const AppLoading());
    try {
      final userModel = await _authService.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      if (userModel != null) {
        await _analyticsService.logLogin('email');
        await _databaseService.initializeUserStatus();
        await _loadBooksAndEmit(emit, userModel);
      } else {
        emit(const AppUnauthenticated());
      }
    } catch (e) {
      if (e is FirebaseException && _isOfflineError(e)) {
        return;
      }
      emit(AppError(e.toString()));
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AppState> emit,
  ) async {
    emit(const AppLoading());
    try {
      final userModel = await _authService.signUpWithEmail(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      if (userModel != null) {
        await _analyticsService.logSignUp('email');
        await _databaseService.initializeUserStatus();
        await _loadBooksAndEmit(emit, userModel);
      } else {
        emit(const AppUnauthenticated());
      }
    } catch (e) {
      if (e is FirebaseException && _isOfflineError(e)) {
        return;
      }
      emit(AppError(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AppState> emit,
  ) async {
    try {
      await _databaseService.cleanup();
      await _authService.signOut();
      emit(const AppUnauthenticated());
    } catch (e) {
      if (e is FirebaseException && _isOfflineError(e)) {
        return;
      }
      emit(AppError(e.toString()));
    }
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AppState> emit,
  ) async {
    try {
      await _authService.resetPassword(event.email);
      // Не меняем состояние, просто отправляем email
    } catch (e) {
      if (e is FirebaseException && _isOfflineError(e)) {
        return;
      }
      emit(AppError(e.toString()));
    }
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AppState> emit,
  ) async {
    emit(const AppLoading());
    try {
      final userModel = await _authService.signInWithGoogle();
      if (userModel != null) {
        await _analyticsService.logLogin('google');
        await _databaseService.initializeUserStatus();
        await _loadBooksAndEmit(emit, userModel);
      } else {
        emit(const AppUnauthenticated());
      }
    } catch (e) {
      emit(AppError(e.toString()));
    }
  }

  Future<void> _loadBooksAndEmit(Emitter<AppState> emit, models.User userModel) async {
    try {
      final books = await _firestoreService.getBooks();
      final favoriteIds = await _firestoreService
          .getFavorites(userModel.id)
          .then((favorites) => favorites.map((f) => f.bookId).toSet());
      
      final syncedBooks = _mergeBooksWithFavorites(books, favoriteIds);
      
      await _hiveService.replaceBooks(syncedBooks);
      await _hiveService.replaceFavorites(userModel.id, favoriteIds);
      
      emit(AppLoaded(
        currentUser: userModel,
        books: syncedBooks,
        filteredBooks: syncedBooks,
        searchQuery: '',
      ));
      
      _booksSubscription?.cancel();
      _booksSubscription = _firestoreService.getBooksStream().listen((books) async {
        if (state is AppLoaded) {
          final currentState = state as AppLoaded;
          final syncedBooks = await _syncBooksWithFavorites(books, currentState.currentUser);
          final filteredBooks = _applySearchFilter(syncedBooks, currentState.searchQuery);
          await _hiveService.replaceBooks(syncedBooks);
          emit(currentState.copyWith(
            books: syncedBooks,
            filteredBooks: filteredBooks,
          ));
        }
      }, onError: (error, stackTrace) {
        if (error is FirebaseException && _isOfflineError(error)) {
          return;
        }
        emit(AppError(error.toString()));
      });
    } on FirebaseException catch (e) {
      if (_isOfflineError(e)) {
        final cachedBooks = _hiveService.getBooks();
        if (cachedBooks.isNotEmpty) {
          final cachedFavorites = _hiveService
              .getFavorites(userModel.id)
              .map((f) => f.bookId)
              .toSet();
          final syncedBooks = _mergeBooksWithFavorites(cachedBooks, cachedFavorites);
          emit(AppLoaded(
            currentUser: userModel,
            books: syncedBooks,
            filteredBooks: syncedBooks,
            searchQuery: '',
          ));
          return;
        }
      }
      emit(AppError(e.message ?? e.toString()));
    } catch (e) {
      emit(AppError(e.toString()));
    }
  }

  Future<List<Book>> _syncBooksWithFavorites(List<Book> books, models.User? user) async {
    if (user == null) {
      return books.map((b) => b.isLiked ? b.copyWith(isLiked: false) : b).toList();
    }
    
    try {
      final favoriteIds = await _firestoreService
          .getFavorites(user.id)
          .then((favorites) => favorites.map((f) => f.bookId).toSet());
      await _hiveService.replaceFavorites(user.id, favoriteIds);
      return _mergeBooksWithFavorites(books, favoriteIds);
    } on FirebaseException catch (e) {
      if (_isOfflineError(e)) {
        final cachedFavorites = _hiveService
            .getFavorites(user.id)
            .map((f) => f.bookId)
            .toSet();
        return _mergeBooksWithFavorites(books, cachedFavorites);
      }
      rethrow;
    }
  }

  void _onBooksSearched(BooksSearched event, Emitter<AppState> emit) {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      final filteredBooks = _applySearchFilter(currentState.books, event.query);
      
      if (event.query.isNotEmpty) {
        _analyticsService.logSearch(event.query);
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
      
      final updatedBooks = [event.book, ...currentState.books];
      final filteredBooks = _applySearchFilter(updatedBooks, currentState.searchQuery);
      emit(currentState.copyWith(
        books: updatedBooks,
        filteredBooks: filteredBooks,
        isLoading: false,
      ));
      
      try {
        await _hiveService.addBook(event.book);
        await _firestoreService.addBook(event.book);
        _analyticsService.logBookCreated(event.book.id, event.book.title);
      } on FirebaseException catch (e) {
        if (_isOfflineError(e)) {
          return;
        }
        emit(AppError(e.message ?? e.toString()));
      } catch (e) {
        if (e is FirebaseException && _isOfflineError(e)) {
          return;
        }
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

      final updatedBooks = currentState.books.map((book) {
        return book.id == event.book.id ? event.book : book;
      }).toList();
      final filteredBooks = _applySearchFilter(updatedBooks, currentState.searchQuery);

      emit(currentState.copyWith(
        books: updatedBooks,
        filteredBooks: filteredBooks,
        isLoading: false,
      ));

      try {
        await _hiveService.updateBook(event.book);
        await _firestoreService.updateBook(event.book);
        // Firestore стрим синхронизирует окончательное состояние
      } on FirebaseException catch (e) {
        if (_isOfflineError(e)) {
          return;
        }
        emit(AppError(e.message ?? e.toString()));
    } catch (e) {
      if (e is FirebaseException && _isOfflineError(e)) {
        return;
      }
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
      
      final updatedBooks = currentState.books.where((book) => book.id != event.bookId).toList();
      final filteredBooks = _applySearchFilter(updatedBooks, currentState.searchQuery);
      emit(currentState.copyWith(
        books: updatedBooks,
        filteredBooks: filteredBooks,
        isLoading: false,
      ));
      
      try {
        await _hiveService.deleteBook(event.bookId);
        await _firestoreService.deleteBook(event.bookId);
        _analyticsService.logBookDeleted(event.bookId);
      } on FirebaseException catch (e) {
        if (_isOfflineError(e)) {
          return;
        }
        emit(AppError(e.message ?? e.toString()));
      } catch (e) {
        if (e is FirebaseException && _isOfflineError(e)) {
          return;
        }
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
      final userId = currentState.currentUser!.id;
      
      // Проверяем Remote Config - включена ли кнопка like
      if (!_remoteConfigService.isLikeButtonEnabled()) {
        return; // Кнопка отключена через Remote Config
      }

      final book = currentState.books.firstWhere((b) => b.id == event.bookId);
      final isLiked = book.isLiked;

      // Сначала обновляем локальное состояние (Hive + BLoC),
      // чтобы лайк менял цвет даже без интернета.
      if (isLiked) {
        await _hiveService.removeFromFavorites(userId, event.bookId);
      } else {
        await _hiveService.addToFavorites(userId, event.bookId);
      }

      final updatedBooks = currentState.books.map((b) {
        if (b.id == event.bookId) {
          return b.copyWith(isLiked: !isLiked);
        }
        return b;
      }).toList();

      final filteredBooks = _applySearchFilter(updatedBooks, currentState.searchQuery);
      emit(currentState.copyWith(
        books: updatedBooks,
        filteredBooks: filteredBooks,
      ));

      // После этого пытаемся синхронизировать с Firestore.
      // Любые ошибки (в том числе оффлайн) не ломают локальный UI.
      try {
        if (isLiked) {
          await _firestoreService.removeFromFavorites(
            userId,
            event.bookId,
          );
          _analyticsService.logBookUnliked(event.bookId, book.title);
        } else {
          await _firestoreService.addToFavorites(
            userId,
            event.bookId,
          );
          _analyticsService.logBookLiked(event.bookId, book.title);
        }
      } on FirebaseException catch (e) {
        if (_isOfflineError(e)) {
          // Оффлайн-ошибки игнорируем – данные синхронизируются при подключении.
          return;
        }
        // Для других ошибок просто логируем, не меняя состояние.
        // Можно добавить отчёт в Analytics при необходимости.
        return;
      } catch (_) {
        // Не даём неожиданным ошибкам ломать UI.
        return;
      }
    }
  }

  Future<void> _onDataCompressed(
    DataCompressed event,
    Emitter<AppState> emit,
  ) async {
    // Для Firestore это не применимо, но оставляем для совместимости
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      emit(currentState.copyWith(isLoading: false));
    }
  }

  Future<void> _onEncryptionDemonstrated(
    EncryptionDemonstrated event,
    Emitter<AppState> emit,
  ) async {
    // Это событие не меняет состояние
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

  bool isBookInFavorites(String bookId) {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      if (currentState.currentUser == null) return false;
      final book = currentState.books.firstWhere(
        (b) => b.id == bookId,
        orElse: () => Book(
          id: '',
          title: '',
          author: '',
          description: '',
          imagePath: '',
          rating: 0,
          reviewsCount: 0,
          categories: [],
          isLiked: false,
          createdAt: DateTime.now(),
          coverColor: Book.defaultCoverColor,
        ),
      );
      return book.isLiked;
    }
    return false;
  }

  List<Book> getFavoriteBooks() {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      return currentState.books.where((book) => book.isLiked).toList();
    }
    return [];
  }

  Book createDemoBook({
    required String title,
    required String author,
    String description = '',
    String imagePath = 'assets/default_book.jpg',
    double rating = 0.0,
    int reviewsCount = 0,
    List<String> categories = const [],
    bool isLiked = false,
    String coverColor = Book.defaultCoverColor,
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
        coverColor: coverColor,
        reviews: const [],
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
      coverColor: coverColor,
      reviews: const [],
    );
  }

  bool _isOfflineError(Object error) {
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      final message = error.message?.toLowerCase() ?? '';
      return code == 'unavailable' ||
          code == 'network-request-failed' ||
          code == 'cloud_firestore/unavailable' ||
          message.contains('unavailable') ||
          message.contains('network') ||
          message.contains('offline');
    }
    return false;
  }
  
  List<Book> _mergeBooksWithFavorites(List<Book> books, Set<String> favoriteIds) {
    return books.map((book) {
      final isLiked = favoriteIds.contains(book.id);
      if (book.isLiked != isLiked) {
        return book.copyWith(isLiked: isLiked);
      }
      return book;
    }).toList();
  }

  // Получить Remote Config сервис
  RemoteConfigService get remoteConfigService => _remoteConfigService;
  
  // Получить Database сервис
  DatabaseService get databaseService => _databaseService;
  
  // Получить Analytics сервис
  AnalyticsService get analyticsService => _analyticsService;
  
  // Получить статистику Hive
  Map<String, int> getStats() {
    return _hiveService.getStats();
  }
  
  // Демонстрация шифрования Hive
  Future<String> demonstrateEncryption() async {
    return await _hiveService.demonstrateWrongKeyOnBooks();
  }
}
