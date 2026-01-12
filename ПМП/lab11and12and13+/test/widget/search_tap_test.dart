import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lab11and12/widgets/searchBar.dart';

void main() {
  testWidgets('SearchBar - Tap на поле поиска', (WidgetTester tester) async {
    bool wasTapped = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MySearchBar(
            onTap: () {
              wasTapped = true;
            },
          ),
        ),
      ),
    );

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.tap(textField);
    await tester.pumpAndSettle();

    expect(wasTapped, isTrue);
  });
}