import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lab11and12/bloc/appEvent.dart';
import 'package:lab11and12/bloc/appState.dart';
import 'package:lab11and12/screens/authScreen.dart';
import 'package:lab11and12/screens/favoritesScreen.dart';
import 'package:lab11and12/screens/homeScreen.dart';
import 'package:lab11and12/screens/profileScreen.dart';
import 'package:lab11and12/widgets/bookCard.dart';
import 'package:mockito/mockito.dart';
import '../test/mocks.mocks.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockAppBloc mockBloc;
  late MockConnectivityService connectivityService;
  late StreamController<AppState> stateController;
  late AppState currentState;

  setUp(() {
    stateController = StreamController<AppState>.broadcast();
    currentState = const AppUnauthenticated();
    connectivityService = createMockConnectivityService();
    mockBloc = createMockBloc(
      initialState: currentState,
      stateController: stateController,
    );
  });

  tearDown(() async {
    await stateController.close();
  });

  Future<void> simulateStateLocal(AppState state, WidgetTester tester) async {
    currentState = state;
    when(mockBloc.state).thenAnswer((_) => state);
    stateController.add(state);
    await tester.pumpAndSettle();
  }

  testWidgets('Пользователь работает с избранным', (tester) async {
    await pumpApp(tester, mockBloc, connectivityService);
    await simulateStateLocal(const AppUnauthenticated(), tester);

    await tester.enterText(
      find.byKey(const Key('auth_email_field')),
      'jokeiminny@gmail.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth_password_field')),
      'jokimi',
    );
    await tester.tap(find.byKey(const Key('auth_submit_button')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    verify(mockBloc.add(argThat(predicate<AppEvent>((event) => event is SignInRequested)))).called(1);

    when(mockBloc.getFavoriteBooks()).thenReturn(
      [demoBooks[1], demoBooks[3]],
    );

    final bookToAdd = demoBooks[1];
    when(mockBloc.isBookInFavorites(bookToAdd.id)).thenReturn(false);
    when(mockBloc.getFavoriteBooks()).thenReturn([]);

    final initialBooks = demoBooks.map((book) {
      if (book.id == bookToAdd.id) {
        return book.copyWith(isLiked: false);
      }
      return book;
    }).toList();
    
    final initialState = AppLoaded(
      currentUser: regularUser,
      books: initialBooks,
      filteredBooks: initialBooks,
      searchQuery: '',
    );
    
    await simulateStateLocal(initialState, tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final likeButtons = find.byIcon(Icons.favorite_border);
    expect(likeButtons, findsWidgets);
    await tester.tap(likeButtons.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    verify(mockBloc.add(argThat(predicate<AppEvent>((event) => event is FavoriteToggled)))).called(1);

    when(mockBloc.isBookInFavorites(bookToAdd.id)).thenReturn(true);
    when(mockBloc.getFavoriteBooks()).thenReturn([bookToAdd]);
    
    final booksWithLiked = initialBooks.map((book) {
      if (book.id == bookToAdd.id) {
        return book.copyWith(isLiked: true);
      }
      return book;
    }).toList();
    
    final stateWithLiked = AppLoaded(
      currentUser: regularUser,
      books: booksWithLiked,
      filteredBooks: booksWithLiked,
      searchQuery: '',
    );
    await simulateStateLocal(stateWithLiked, tester);

    await tester.tap(find.byKey(const Key('home_favorites_button')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Favorite Books'), findsOneWidget);

    final favoriteBooksBefore = mockBloc.getFavoriteBooks();
    expect(favoriteBooksBefore.isNotEmpty, isTrue);

    final bookToRemove = favoriteBooksBefore.first;
    expect(find.text(bookToRemove.title), findsOneWidget);

    await tester.tap(find.byKey(Key('favorites_remove_${bookToRemove.id}')));
    await tester.pumpAndSettle();

    verify(mockBloc.add(argThat(predicate<AppEvent>((event) => event is FavoriteToggled && event.bookId == bookToRemove.id)))).called(1);

    when(mockBloc.isBookInFavorites(bookToRemove.id)).thenReturn(false);
    final remainingFavorites = favoriteBooksBefore.where((b) => b.id != bookToRemove.id).toList();
    when(mockBloc.getFavoriteBooks()).thenReturn(remainingFavorites);

    final updatedBooks = booksWithLiked.map((book) {
      if (book.id == bookToRemove.id) {
        return book.copyWith(isLiked: false);
      }
      return book;
    }).toList();
    
    final updatedState = AppLoaded(
      currentUser: regularUser,
      books: updatedBooks,
      filteredBooks: updatedBooks,
      searchQuery: '',
    );
    await simulateStateLocal(updatedState, tester);

    if (remainingFavorites.isEmpty) {
      expect(find.text('Нет избранных книг'), findsOneWidget);
    } else {
      expect(find.text(bookToRemove.title), findsNothing);
    }

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('home_profile_avatar')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('profile_logout_button')));
    await tester.pump();
    await tester.tap(find.text('Выйти').last);
    await tester.pumpAndSettle();

    verify(mockBloc.add(const SignOutRequested())).called(1);
    await simulateStateLocal(const AppUnauthenticated(), tester);
  });
}