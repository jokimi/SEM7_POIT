import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lab11and12/bloc/appEvent.dart';
import 'package:lab11and12/bloc/appState.dart';
import 'package:lab11and12/screens/authScreen.dart';
import 'package:lab11and12/screens/homeScreen.dart';
import 'package:lab11and12/screens/profileScreen.dart';
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

  testWidgets('Просмотр профиля и подтверждение данных', (tester) async {
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
    await tester.pumpAndSettle();

    verify(mockBloc.add(argThat(predicate<AppEvent>((event) => event is SignInRequested)))).called(1);

    await simulateStateLocal(buildUserState(), tester);

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('home_profile_avatar')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('jokimi'), findsOneWidget);
    expect(find.text('jokeiminny@gmail.com'), findsOneWidget);
    expect(find.text('User'), findsOneWidget);
    expect(find.textContaining('Дата регистрации'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile_logout_button')));
    await tester.pump();
    await tester.tap(find.text('Выйти').last);
    await tester.pumpAndSettle();

    verify(mockBloc.add(const SignOutRequested())).called(1);
    await simulateStateLocal(const AppUnauthenticated(), tester);
    expect(find.byType(AuthScreen), findsOneWidget);
  });
}

