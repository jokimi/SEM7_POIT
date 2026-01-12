import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab11and12/bloc/appBLoC.dart';
import 'package:lab11and12/bloc/appEvent.dart';
import 'package:lab11and12/bloc/appState.dart';
import 'package:lab11and12/models/bookModel.dart';
import 'package:lab11and12/models/userModel.dart';
import 'package:lab11and12/services/analyticsService.dart';
import 'package:lab11and12/services/connectivityService.dart';
import 'package:lab11and12/services/remoteConfigService.dart';
import 'package:mockito/mockito.dart';

class MockAppBloc extends Mock implements AppBloc {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

final testUser = User(
  id: 'u1',
  name: 'Admin',
  email: 'admin@example.com',
  role: 1,
  createdAt: DateTime(2024, 1, 1),
  avatarPath: 'assets/avatar.jpg',
);

final testBooks = [
  Book(
    id: 'b1',
    title: 'Timber',
    author: 'Peter',
    description: 'Desc',
    imagePath: 'assets/timber.jpg',
    rating: 4.8,
    reviewsCount: 50,
    categories: const ['Nature'],
    isLiked: false,
    createdAt: DateTime(2024, 1, 1),
    coverColor: Book.defaultCoverColor,
  ),
  Book(
    id: 'b2',
    title: 'Sea of Poppies',
    author: 'Amitav',
    description: 'Another',
    imagePath: 'assets/seaofpoppies.jpg',
    rating: 4.2,
    reviewsCount: 20,
    categories: const ['Fiction'],
    isLiked: false,
    createdAt: DateTime(2024, 1, 2),
    coverColor: Book.defaultCoverColor,
  ),
];

AppLoaded buildLoadedState() => AppLoaded(
      currentUser: testUser,
      books: testBooks,
      filteredBooks: testBooks,
      searchQuery: '',
    );

Future<void> pumpWithBloc(
  WidgetTester tester,
  Widget child,
  MockAppBloc mockBloc,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AppBloc>.value(
        value: mockBloc,
        child: child,
      ),
    ),
  );
  await tester.pump();
}

MockAppBloc createMockBloc({
  AppState? initialState,
  StreamController<AppState>? stateController,
}) {
  final mockBloc = MockAppBloc();
  final controller = stateController ?? StreamController<AppState>.broadcast();
  final state = initialState ?? const AppUnauthenticated();
  final analyticsService = MockAnalyticsService();
  final remoteConfigService = MockRemoteConfigService();

  when(mockBloc.stream).thenAnswer((_) => controller.stream);
  when(mockBloc.state).thenAnswer((_) => state);
  when(mockBloc.close()).thenAnswer((_) async {});
  when(mockBloc.add(any as AppEvent)).thenReturn(null);
  when(mockBloc.analyticsService).thenReturn(analyticsService);
  when(mockBloc.remoteConfigService).thenReturn(remoteConfigService);
  when(mockBloc.isBookInFavorites(any as String)).thenReturn(false);
  when(analyticsService.logSearch(any as String)).thenAnswer((_) async {});
  when(analyticsService.logBookView(any as String, any as String)).thenAnswer((_) async {});
  when(remoteConfigService.isLikeButtonEnabled()).thenReturn(true);

  return mockBloc;
}

MockConnectivityService createMockConnectivityService() {
  final service = MockConnectivityService();
  when(service.connectivityStream).thenAnswer(
    (_) => const Stream<bool>.empty(),
  );
  when(service.isConnected()).thenAnswer((_) async => true);
  when(service.dispose()).thenReturn(null);
  return service;
}

