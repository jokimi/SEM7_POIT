import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab11and12/bloc/appBLoC.dart';
import 'package:lab11and12/bloc/appEvent.dart';
import 'package:lab11and12/bloc/appState.dart';
import 'package:lab11and12/services/authService.dart';
import 'package:lab11and12/services/databaseService.dart';
import 'package:lab11and12/services/firestoreService.dart';
import 'package:lab11and12/services/hiveService.dart';
import 'package:lab11and12/services/analyticsService.dart';
import 'package:lab11and12/services/remoteConfigService.dart';
import 'package:mockito/mockito.dart';
import '../mocks.mocks.dart';
import 'test_helpers.dart';

Future<void> _voidFuture() async {}

void main() {
  late MockAuthService authService;
  late MockDatabaseService databaseService;
  late MockFirestoreService firestoreService;
  late MockHiveService hiveService;
  late MockAnalyticsService analyticsService;
  late MockRemoteConfigService remoteConfigService;

  setUp(() {
    authService = MockAuthService();
    databaseService = MockDatabaseService();
    firestoreService = MockFirestoreService();
    hiveService = MockHiveService();
    analyticsService = MockAnalyticsService();
    remoteConfigService = MockRemoteConfigService();

    when(authService.signOut()).thenAnswer((_) => _voidFuture());
    when(databaseService.cleanup()).thenAnswer((_) => _voidFuture());
    when(remoteConfigService.initialize()).thenAnswer((_) => _voidFuture());
    when(firestoreService.enableOfflinePersistence()).thenAnswer((_) => _voidFuture());
    when(authService.authStateChanges).thenAnswer((_) => const Stream.empty());
  });

  blocTest<AppBloc, AppState>(
    'SignOutRequested очищает данные и возвращает AppUnauthenticated',
    build: () {
      return createTestBloc(
        authService: authService,
        databaseService: databaseService,
        firestoreService: firestoreService,
        hiveService: hiveService,
        analyticsService: analyticsService,
        remoteConfigService: remoteConfigService,
        authStateStreamOverride: Stream.empty(),
      );
    },
    seed: () => AppLoaded(
      currentUser: sampleUser,
      books: [sampleBook],
      filteredBooks: [sampleBook],
      searchQuery: '',
    ),
    act: (bloc) => bloc.add(const SignOutRequested()),
    expect: () => const [
      AppUnauthenticated(),
    ],
    verify: (_) {
      verify(databaseService.cleanup()).called(1);
      verify(authService.signOut()).called(1);
    },
  );
}