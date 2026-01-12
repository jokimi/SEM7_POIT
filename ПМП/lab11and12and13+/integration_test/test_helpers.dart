import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab11and12/bloc/appBLoC.dart';
import 'package:lab11and12/bloc/appState.dart';
import 'package:lab11and12/models/bookModel.dart';
import 'package:lab11and12/models/userModel.dart';
import 'package:lab11and12/screens/adminBooksScreen.dart';
import 'package:lab11and12/screens/authScreen.dart';
import 'package:lab11and12/screens/bookDetailScreen.dart';
import 'package:lab11and12/screens/favoritesScreen.dart';
import 'package:lab11and12/screens/homeScreen.dart';
import 'package:lab11and12/screens/profileScreen.dart';
import 'package:mockito/mockito.dart';
import '../test/mocks.mocks.dart';

final adminUser = User(
  id: 'admin',
  name: 'keikenny',
  email: 'lizakozeka@gmail.com',
  role: 1,
  createdAt: DateTime(2024, 1, 1),
  avatarPath: 'assets/kawaii.jpg',
);

final regularUser = User(
  id: 'user',
  name: 'jokimi',
  email: 'jokeiminny@gmail.com',
  role: 0,
  createdAt: DateTime(2024, 1, 2),
  avatarPath: 'assets/avatar.jpg',
);

final demoBooks = [
  Book(
    id: '1',
    title: 'Timber',
    author: 'Peter Dauvergne',
    rating: 8.5,
    reviewsCount: 89,
    categories: ['Nature', 'Environment'],
    coverColor: 'Color(0xFFf5bc15)',
    imagePath: 'assets/timber.jpg',
    isLiked: true,
    createdAt: DateTime(2025, 12, 8),
    createdBy: 'admin',
    description: 'A comprehensive exploration of timber industry and its environmental impact. This book delves into the complex relationship between human civilization and forest resources.',
  ),
  Book(
    id: '2',
    title: 'Sweet Bird',
    author: 'Tennessee Williams',
    rating: 9.1,
    reviewsCount: 155,
    categories: ['Drama', 'Classic'],
    coverColor: 'Color(0xFF858e85)',
    imagePath: 'assets/sweetbirdofyouth.jpg',
    isLiked: false,
    createdAt: DateTime(2025, 12, 8),
    createdBy: 'admin',
    description: 'A powerful drama about aging, lost youth, and the pursuit of dreams. Tennessee Williams masterfully explores human vulnerabilities and desires.',
  ),
  Book(
    id: '3',
    title: 'Early Bird',
    author: 'Rodney Rothman',
    rating: 7.8,
    reviewsCount: 67,
    categories: ['Comedy', 'Memoir'],
    coverColor: 'Color(0xFFf3d656)',
    imagePath: 'assets/earlybird.jpg',
    isLiked: false,
    createdAt: DateTime(2025, 12, 8),
    createdBy: 'admin',
    description: 'A hilarious memoir about early retirement and finding new purpose in life. Full of witty observations and life lessons.',
  ),
  Book(
    id: '4',
    title: 'The Crow\'s Vow',
    author: 'Susan Briscoe',
    rating: 9.2,
    reviewsCount: 203,
    categories: ['Travelers', 'Literature'],
    coverColor: 'Color(0xFFfbcec9)',
    imagePath: 'assets/thecrowsvow.jpg',
    isLiked: true,
    createdAt: DateTime(2025, 12, 8),
    createdBy: 'admin',
    description: 'The Crow\'s Vow is an extraordinarily moving book-length sequence that follows the story of a marriage come undone. Organized into four seasons, the book traces the emotional landscape of love, loss, and the possibility of redemption.'
  ),
  Book(
    id: '5',
    title: 'Sea of Poppies',
    author: 'Amitav Ghosh',
    rating: 9.6,
    reviewsCount: 178,
    categories: ['Historical', 'Adventure'],
    coverColor: 'Color(0xFFd0c9b7)',
    imagePath: 'assets/seaofpoppies.jpg',
    isLiked: false,
    createdAt: DateTime(2025, 12, 8),
    createdBy: 'admin',
    description: 'The first in an epic trilogy, Sea of Poppies is a stunningly vibrant and intensely human work that brings alive the nineteenth-century opium trade.',
  ),
];

AppLoaded buildAdminState() => AppLoaded(
      currentUser: adminUser,
      books: demoBooks,
      filteredBooks: demoBooks,
      searchQuery: '',
    );

AppLoaded buildUserState() => AppLoaded(
      currentUser: regularUser,
      books: demoBooks,
      filteredBooks: demoBooks,
      searchQuery: '',
    );

Future<void> pumpApp(
  WidgetTester tester,
  MockAppBloc mockBloc,
  MockConnectivityService connectivityService,
) async {
  await tester.pumpWidget(
    BlocProvider<AppBloc>.value(
      value: mockBloc,
      child: MaterialApp(
        initialRoute: '/auth',
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/home': (context) => HomeScreen(connectivityService: connectivityService),
          '/admin_books': (context) => const AdminBooksScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/book_detail': (context) {
            final book = ModalRoute.of(context)?.settings.arguments as Book?;
            if (book == null) {
              return const Scaffold(
                body: Center(child: Text('Книга не найдена')),
              );
            }
            return BookDetailScreen(book: book);
          },
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
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
  final databaseService = MockDatabaseService();

  when(mockBloc.stream).thenAnswer((_) => controller.stream);
  when(mockBloc.state).thenAnswer((_) => state);
  when(mockBloc.close()).thenAnswer((_) async {});
  when(mockBloc.add(any)).thenReturn(null);
  when(mockBloc.analyticsService).thenReturn(analyticsService);
  when(mockBloc.remoteConfigService).thenReturn(remoteConfigService);
  when(mockBloc.databaseService).thenReturn(databaseService);
  when(mockBloc.isBookInFavorites(any)).thenReturn(false);
  when(mockBloc.getFavoriteBooks()).thenReturn([]);
  when(mockBloc.createDemoBook(
    title: anyNamed('title'),
    author: anyNamed('author'),
    description: anyNamed('description'),
    imagePath: anyNamed('imagePath'),
    rating: anyNamed('rating'),
    reviewsCount: anyNamed('reviewsCount'),
    categories: anyNamed('categories'),
    isLiked: anyNamed('isLiked'),
    coverColor: anyNamed('coverColor'),
  )).thenAnswer((invocation) {
    final title = invocation.namedArguments[#title] as String? ?? 'New Book';
    final author = invocation.namedArguments[#author] as String? ?? 'Unknown';
    return Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      author: author,
      description: invocation.namedArguments[#description] as String? ?? '',
      imagePath: invocation.namedArguments[#imagePath] as String? ?? 'assets/avatar.jpg',
      rating: invocation.namedArguments[#rating] as double? ?? 0,
      reviewsCount: invocation.namedArguments[#reviewsCount] as int? ?? 0,
      categories: (invocation.namedArguments[#categories] as List<String>?) ?? const [],
      isLiked: invocation.namedArguments[#isLiked] as bool? ?? false,
      createdAt: DateTime.now(),
      coverColor: invocation.namedArguments[#coverColor] as String? ?? Book.defaultCoverColor,
    );
  });

  when(analyticsService.logSearch(any)).thenAnswer((_) async {});
  when(analyticsService.logBookView(any, any)).thenAnswer((_) async {});
  when(remoteConfigService.isLikeButtonEnabled()).thenReturn(true);
  when(remoteConfigService.getBlockColor()).thenReturn(const Color(0xFFffae1a));

  when(databaseService.getUserStatusStream(any)).thenAnswer(
    (_) => Stream.value({
      'status': 'online',
      'lastSeen': DateTime(2024, 1, 3).toIso8601String(),
    }),
  );

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

Future<void> updateState(
  AppState state,
  WidgetTester tester,
  StreamController<AppState> stateController,
  MockAppBloc mockBloc,
) async {
  when(mockBloc.state).thenAnswer((_) => state);
  stateController.add(state);
  await tester.pumpAndSettle();
}