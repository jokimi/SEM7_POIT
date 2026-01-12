import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lab11and12/widgets/introductionSection.dart';

void main() {
  testWidgets('IntroductionSection - Tap для expand/shrink', (WidgetTester tester) async {
    final longDescription = 'This is a very long description that should be shortened when not expanded. ' * 5;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IntroductionSection(description: longDescription),
        ),
      ),
    );

    expect(find.text('Introduction'), findsOneWidget);
    expect(find.text('Expand'), findsOneWidget);

    await tester.tap(find.text('Expand'));
    await tester.pumpAndSettle();

    expect(find.text('Shrink'), findsOneWidget);

    await tester.tap(find.text('Shrink'));
    await tester.pumpAndSettle();

    expect(find.text('Expand'), findsOneWidget);
  });
}