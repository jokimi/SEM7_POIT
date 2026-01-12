import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab11and12/bloc/appBLoC.dart';
import 'package:lab11and12/bloc/appEvent.dart';
import 'package:lab11and12/bloc/appState.dart';
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
  late MockAnalyticsService analyticsService;
  late MockAuthService authService;
  late MockDatabaseService databaseService;
  late MockFirestoreService firestoreService;
  late MockHiveService hiveService;
  late MockRemoteConfigService remoteConfigService;

  setUp(() {
    analyticsService = MockAnalyticsService();
    authService = MockAuthService();
    databaseService = MockDatabaseService();
    firestoreService = MockFirestoreService();
    hiveService = MockHiveService();
    remoteConfigService = MockRemoteConfigService();

    when(analyticsService.logSearch(any)).thenAnswer((_) => _voidFuture());
    when(remoteConfigService.initialize()).thenAnswer((_) => _voidFuture());
    when(firestoreService.enableOfflinePersistence()).thenAnswer((_) => _voidFuture());
    when(authService.authStateChanges).thenAnswer((_) => const Stream.empty());
  });

  blocTest<AppBloc, AppState>(
    'BooksSearched фильтрует список и логирует запрос',
    build: () {
      return createTestBloc(
        analyticsService: analyticsService,
        authService: authService,
        databaseService: databaseService,
        firestoreService: firestoreService,
        hiveService: hiveService,
        remoteConfigService: remoteConfigService,
        authStateStreamOverride: Stream.empty(),
      );
    },
    seed: () => AppLoaded(
      currentUser: sampleUser,
      books: [sampleBook, sampleBook.copyWith(id: 'book-2', title: 'Other')],
      filteredBooks: [sampleBook, sampleBook.copyWith(id: 'book-2', title: 'Other')],
      searchQuery: '',
    ),
    act: (bloc) => bloc.add(const BooksSearched('Timber')),
    expect: () => [
      predicate<AppState>((state) {
        if (state is! AppLoaded) return false;
        return state.currentUser?.id == sampleUser.id &&
            state.books.length == 2 &&
            state.filteredBooks.length == 1 &&
            state.filteredBooks.first.title == 'Timber' &&
            state.searchQuery == 'Timber';
      }),
    ],
    verify: (_) {
      verify(analyticsService.logSearch('Timber')).called(1);
    },
  );
}