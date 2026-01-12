import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab11and12/bloc/appBLoC.dart';
import 'package:lab11and12/bloc/appEvent.dart';
import 'package:lab11and12/bloc/appState.dart';
import 'package:lab11and12/services/authService.dart';
import 'package:lab11and12/services/firestoreService.dart';
import 'package:lab11and12/services/remoteConfigService.dart';
import 'package:mockito/mockito.dart';
import '../mocks.mocks.dart';
import 'test_helpers.dart';

Future<void> _voidFuture() async {}

void main() {
  late MockFirestoreService firestoreService;
  late MockAuthService authService;
  late MockRemoteConfigService remoteConfigService;

  setUp(() {
    firestoreService = MockFirestoreService();
    authService = MockAuthService();
    remoteConfigService = MockRemoteConfigService();

    when(remoteConfigService.initialize()).thenAnswer((_) => _voidFuture());
    when(firestoreService.enableOfflinePersistence()).thenAnswer((_) => _voidFuture());
    when(authService.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(authService.currentUser).thenReturn(null);
  });

  blocTest<AppBloc, AppState>(
    'Состояние AppUnauthenticated при инициализации без пользователя',
    build: () {
      return createTestBloc(
        firestoreService: firestoreService,
        authService: authService,
        remoteConfigService: remoteConfigService,
        authStateStreamOverride: Stream<User?>.empty(),
      );
    },
    act: (bloc) => bloc.add(const AppInitialized()),
    expect: () => const [
      AppLoading(),
      AppUnauthenticated(),
    ],
    verify: (_) {
      verify(remoteConfigService.initialize()).called(1);
      verify(firestoreService.enableOfflinePersistence()).called(1);
    },
  );
}