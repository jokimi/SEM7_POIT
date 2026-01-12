import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/bookModel.dart';
import '../models/userModel.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

class AppInitialized extends AppEvent {
  const AppInitialized();
}

class UserSwitched extends AppEvent {
  final String userId;
  const UserSwitched(this.userId);

  @override
  List<Object?> get props => [userId];
}

class BooksSearched extends AppEvent {
  final String query;
  const BooksSearched(this.query);

  @override
  List<Object?> get props => [query];
}

class BookAdded extends AppEvent {
  final Book book;
  const BookAdded(this.book);

  @override
  List<Object?> get props => [book];
}

class BookUpdated extends AppEvent {
  final Book book;
  const BookUpdated(this.book);

  @override
  List<Object?> get props => [book];
}

class BookDeleted extends AppEvent {
  final String bookId;
  const BookDeleted(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class FavoriteToggled extends AppEvent {
  final String bookId;
  const FavoriteToggled(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class DataCompressed extends AppEvent {
  const DataCompressed();
}

class EncryptionDemonstrated extends AppEvent {
  const EncryptionDemonstrated();
}

// События аутентификации
class SignInRequested extends AppEvent {
  final String email;
  final String password;
  const SignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignUpRequested extends AppEvent {
  final String email;
  final String password;
  final String name;
  const SignUpRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

class SignOutRequested extends AppEvent {
  const SignOutRequested();
}

class PasswordResetRequested extends AppEvent {
  final String email;
  const PasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class SignInWithGoogleRequested extends AppEvent {
  const SignInWithGoogleRequested();
}

class AuthStateChanged extends AppEvent {
  final firebase_auth.User? user;
  const AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}

