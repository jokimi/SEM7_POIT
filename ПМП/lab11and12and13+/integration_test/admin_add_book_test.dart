import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lab11and12/bloc/appEvent.dart';
import 'package:lab11and12/bloc/appState.dart';
import 'package:lab11and12/screens/adminBooksScreen.dart';
import 'package:lab11and12/screens/authScreen.dart';
import 'package:lab11and12/screens/bookDetailScreen.dart';
import 'package:lab11and12/screens/homeScreen.dart';
import 'package:lab11and12/screens/profileScreen.dart';
import 'package:lab11and12/models/bookModel.dart';
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

  testWidgets('Администратор входит и добавляет книгу', (tester) async {
    await pumpApp(tester, mockBloc, connectivityService);
    await simulateStateLocal(const AppUnauthenticated(), tester);

    await tester.tap(find.byKey(const Key('auth_google_button')));
    await tester.pumpAndSettle();

    verify(mockBloc.add(const SignInWithGoogleRequested())).called(1);

    await simulateStateLocal(buildAdminState(), tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('home_admin_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin_add_book_fab')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('admin_book_title_field')),
      'Новая книга',
    );
    await tester.enterText(
      find.byKey(const Key('admin_book_author_field')),
      'Автор',
    );

    await tester.tap(find.byKey(const Key('admin_add_book_button')));
    await tester.pumpAndSettle();

    verify(mockBloc.add(argThat(predicate<AppEvent>((event) => event is BookAdded)))).called(1);

    expect(find.byType(AdminBooksScreen), findsOneWidget);

    final newBook = Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Новая книга',
      author: 'Автор',
      description: '',
      imagePath: 'assets/art.jpg',
      rating: 0,
      reviewsCount: 0,
      categories: const ['Comedy'],
      isLiked: false,
      createdAt: DateTime.now(),
      createdBy: 'admin',
      coverColor: Book.defaultCoverColor,
    );

    final currentState = buildAdminState();
    final updatedBooks = [newBook, ...currentState.books];
    final updatedState = AppLoaded(
      currentUser: currentState.currentUser,
      books: updatedBooks,
      filteredBooks: updatedBooks,
      searchQuery: currentState.searchQuery,
    );
    await simulateStateLocal(updatedState, tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.text('Новая книга').first);
    await tester.pumpAndSettle();

    expect(find.byType(BookDetailScreen), findsOneWidget);
    expect(find.text('Новая книга'), findsOneWidget);
    expect(find.text('Автор'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.west_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_profile_avatar')));
    await tester.pumpAndSettle();

    expect(find.text('keikenny'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile_logout_button')));
    await tester.pump();
    await tester.tap(find.text('Выйти').last);
    await tester.pumpAndSettle();

    verify(mockBloc.add(const SignOutRequested())).called(1);
    await simulateStateLocal(const AppUnauthenticated(), tester);
    expect(find.byType(AuthScreen), findsOneWidget);
  });
}

