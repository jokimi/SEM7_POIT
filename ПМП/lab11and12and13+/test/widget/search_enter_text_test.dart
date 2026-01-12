import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lab11and12/widgets/searchBar.dart';

void main() {
  testWidgets('SearchBar - enterText взаимодействие', (WidgetTester tester) async {
    String? searchValue;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MySearchBar(
            hintText: 'Search books...',
            onChanged: (value) {
              searchValue = value;
            },
          ),
        ),
      ),
    );

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, 'Timber');
    await tester.pumpAndSettle();

    expect(find.text('Timber'), findsOneWidget);
    expect(searchValue, 'Timber');
  });
}