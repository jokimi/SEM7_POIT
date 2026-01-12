import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab11and12/bloc/appBLoC.dart';
import 'package:lab11and12/bloc/appEvent.dart';
import 'package:lab11and12/bloc/appState.dart';
import 'package:lab11and12/models/bookModel.dart';
import 'package:lab11and12/services/analyticsService.dart';
import 'package:lab11and12/services/authService.dart';
import 'package:lab11and12/services/databaseService.dart';
import 'package:lab11and12/services/firestoreService.dart';
import 'package:lab11and12/services/hiveService.dart';
import 'package:lab11and12/services/remoteConfigService.dart';
import 'package:mockito/mockito.dart';
import '../mocks.mocks.dart';
import 'test_helpers.dart';

Future<void> _voidFuture() async {}

void main() {
  late MockFirestoreService firestoreService;
  late MockHiveService hiveService;
  late MockRemoteConfigService remoteConfigService;
  late MockAuthService authService;
  late MockDatabaseService databaseService;
  late MockAnalyticsService analyticsService;

  setUp(() {
    firestoreService = MockFirestoreService();
    hiveService = MockHiveService();
    remoteConfigService = MockRemoteConfigService();
    authService = MockAuthService();
    databaseService = MockDatabaseService();
    analyticsService = MockAnalyticsService();

    when(remoteConfigService.initialize()).thenAnswer((_) => _voidFuture());
    when(firestoreService.enableOfflinePersistence()).thenAnswer((_) => _voidFuture());
    when(remoteConfigService.isLikeButtonEnabled()).thenReturn(true);
    when(databaseService.initializeUserStatus()).thenAnswer((_) => _voidFuture());
    when(databaseService.cleanup()).thenAnswer((_) => _voidFuture());
    when(authService.signOut()).thenAnswer((_) => _voidFuture());
    when(analyticsService.setUserId(any)).thenAnswer((_) => _voidFuture());
    when(analyticsService.logLogin(any)).thenAnswer((_) => _voidFuture());
    when(analyticsService.logSignUp(any)).thenAnswer((_) => _voidFuture());
    when(analyticsService.logSearch(any)).thenAnswer((_) => _voidFuture());
    when(analyticsService.logBookView(any, any)).thenAnswer((_) => _voidFuture());
    when(analyticsService.logBookLiked(any, any)).thenAnswer((_) => _voidFuture());
    when(analyticsService.logBookUnliked(any, any)).thenAnswer((_) => _voidFuture());
    when(hiveService.replaceBooks(any)).thenAnswer((_) => _voidFuture());
    when(hiveService.replaceFavorites(any, any)).thenAnswer((_) => _voidFuture());
    when(hiveService.addToFavorites(any, any)).thenAnswer((_) => _voidFuture());
    when(hiveService.removeFromFavorites(any, any)).thenAnswer((_) => _voidFuture());
    when(hiveService.getBooks()).thenReturn([]);
    when(hiveService.getFavorites(any)).thenReturn([]);
    when(hiveService.addBook(any)).thenAnswer((_) => _voidFuture());
    when(hiveService.updateBook(any)).thenAnswer((_) => _voidFuture());
    when(hiveService.deleteBook(any)).thenAnswer((_) => _voidFuture());
    when(authService.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(firestoreService.addToFavorites(any, any)).thenAnswer((_) => _voidFuture());
    when(firestoreService.removeFromFavorites(any, any)).thenAnswer((_) => _voidFuture());
  });

  blocTest<AppBloc, AppState>(
    'FavoriteToggled обновляет книгу и синхронизирует сервисы',
    build: () {
      return AppBloc(
        firestoreService: firestoreService,
        authService: authService,
        databaseService: databaseService,
        analyticsService: analyticsService,
        remoteConfigService: remoteConfigService,
        hiveService: hiveService,
        authStateStreamOverride: Stream<User?>.empty(),
      );
    },
    seed: () => AppLoaded(
      currentUser: sampleUser,
      books: [sampleBook],
      filteredBooks: [sampleBook],
      searchQuery: '',
    ),
    act: (bloc) => bloc.add(FavoriteToggled(sampleBook.id)),
    expect: () => [
      predicate<AppState>((state) {
        if (state is! AppLoaded) return false;
        return state.currentUser?.id == sampleUser.id &&
            state.books.length == 1 &&
            state.books.first.id == likedBook.id &&
            state.books.first.isLiked == true &&
            state.filteredBooks.length == 1 &&
            state.filteredBooks.first.isLiked == true &&
            state.searchQuery == '';
      }),
    ],
    verify: (_) {
      verify(remoteConfigService.isLikeButtonEnabled()).called(1);
      verify(hiveService.addToFavorites(userId, sampleBook.id)).called(1);
      verify(firestoreService.addToFavorites(userId, sampleBook.id)).called(1);
    },
  );
}

