import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab11and12/bloc/appBLoC.dart';
import 'package:lab11and12/bloc/appEvent.dart';
import 'package:lab11and12/bloc/appState.dart';
import 'package:lab11and12/models/bookModel.dart';
import 'package:lab11and12/models/favoriteModel.dart';
import 'package:lab11and12/services/authService.dart';
import 'package:lab11and12/services/databaseService.dart';
import 'package:lab11and12/services/firestoreService.dart';
import 'package:lab11and12/services/hiveService.dart';
import 'package:lab11and12/services/analyticsService.dart';
import 'package:lab11and12/services/remoteConfigService.dart';
import 'package:mockito/mockito.dart';
import 'package:lab11and12/services/firestoreService.dart';
import 'package:lab11and12/services/authService.dart';
import 'package:lab11and12/services/databaseService.dart';
import 'package:lab11and12/services/hiveService.dart';
import 'package:lab11and12/services/analyticsService.dart';
import 'package:lab11and12/services/remoteConfigService.dart';
import '../mocks.mocks.dart';
import '../mocks.mocks.dart';
import 'test_helpers.dart';

Future<void> _voidFuture() async {}

void main() {
  late MockFirestoreService firestoreService;
  late MockAuthService authService;
  late MockDatabaseService databaseService;
  late MockHiveService hiveService;
  late MockAnalyticsService analyticsService;
  late MockRemoteConfigService remoteConfigService;
  late MockUser firebaseUser;

  setUp(() {
    firestoreService = MockFirestoreService();
    authService = MockAuthService();
    databaseService = MockDatabaseService();
    hiveService = MockHiveService();
    analyticsService = MockAnalyticsService();
    remoteConfigService = MockRemoteConfigService();
    firebaseUser = MockUser();

    // Сбрасываем все моки перед настройкой
    reset(firestoreService);
    reset(authService);
    reset(databaseService);
    reset(hiveService);
    reset(analyticsService);
    reset(remoteConfigService);
    reset(firebaseUser);

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

    when(authService.currentUser).thenReturn(firebaseUser);
    when(firebaseUser.uid).thenReturn(userId);
    when(firestoreService.getUser(userId)).thenAnswer((_) async => sampleUser);
    when(firestoreService.getBooks()).thenAnswer((_) async => [sampleBook]);
    when(firestoreService.getFavorites(userId)).thenAnswer(
      (_) async => [
        Favorite(
          id: '${userId}_${sampleBook.id}',
          userId: userId,
          bookId: sampleBook.id,
          addedAt: DateTime.now(),
        ),
      ],
    );
    when(firestoreService.getBooksStream()).thenAnswer(
      (_) => const Stream.empty(),
    );
  });

  blocTest<AppBloc, AppState>(
    'Состояние AppLoaded, когда есть текущий пользователь',
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
    act: (bloc) => bloc.add(const AppInitialized()),
    expect: () => [
      const AppLoading(),
      predicate<AppState>((state) {
        if (state is! AppLoaded) return false;
        return state.currentUser?.id == sampleUser.id &&
            state.currentUser?.name == sampleUser.name &&
            state.books.length == 1 &&
            state.books.first.id == likedBook.id &&
            state.books.first.isLiked == true &&
            state.filteredBooks.length == 1 &&
            state.searchQuery == '';
      }),
    ],
    verify: (_) {
      verify(databaseService.initializeUserStatus()).called(1);
      verify(analyticsService.setUserId(userId)).called(1);
      verify(hiveService.replaceBooks(any)).called(1);
      verify(hiveService.replaceFavorites(userId, any)).called(1);
    },
  );
}