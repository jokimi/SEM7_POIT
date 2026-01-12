import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab11and12/bloc/appState.dart';
import 'package:lab11and12/screens/authScreen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('AuthScreen - ввод email через enterText', (tester) async {
    final mockBloc = createMockBloc(initialState: const AppUnauthenticated());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const AuthScreen(),
        ),
      ),
    );

    final emailField = find.byKey(const Key('auth_email_field'));
    expect(emailField, findsOneWidget);

    await tester.enterText(emailField, 'user@example.com');
    await tester.pumpAndSettle();

    expect(find.text('user@example.com'), findsOneWidget);
  });
}

