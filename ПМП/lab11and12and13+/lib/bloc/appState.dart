import 'package:equatable/equatable.dart';
import '../models/bookModel.dart';
import '../models/userModel.dart';

abstract class AppState extends Equatable {
  const AppState();

  @override
  List<Object?> get props => [];
}

class AppInitial extends AppState {
  const AppInitial();
}

class AppLoading extends AppState {
  const AppLoading();
}

class AppLoaded extends AppState {
  final User? currentUser;
  final List<Book> books;
  final List<Book> filteredBooks;
  final String searchQuery;
  final bool isLoading;

  const AppLoaded({
    required this.currentUser,
    required this.books,
    required this.filteredBooks,
    required this.searchQuery,
    this.isLoading = false,
  });

  AppLoaded copyWith({
    User? currentUser,
    List<Book>? books,
    List<Book>? filteredBooks,
    String? searchQuery,
    bool? isLoading,
  }) {
    return AppLoaded(
      currentUser: currentUser ?? this.currentUser,
      books: books ?? this.books,
      filteredBooks: filteredBooks ?? this.filteredBooks,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAdmin => currentUser?.role == 1;
  bool get canManageBooks => isAdmin;

  @override
  List<Object?> get props => [
        currentUser,
        books,
        filteredBooks,
        searchQuery,
        isLoading,
      ];
}

class AppError extends AppState {
  final String message;
  const AppError(this.message);

  @override
  List<Object?> get props => [message];
}

class AppUnauthenticated extends AppState {
  const AppUnauthenticated();
}

