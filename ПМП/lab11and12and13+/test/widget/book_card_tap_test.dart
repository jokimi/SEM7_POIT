import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab11and12/models/bookModel.dart';
import 'package:lab11and12/widgets/bookCard.dart';

void main() {
  testWidgets('BookCard - tap on info triggers callback', (tester) async {
    var infoTapped = false;
    final book = Book(
      id: 'b1',
      title: 'Test Book',
      author: 'Author',
      description: 'Desc',
      imagePath: 'assets/avatar.jpg',
      rating: 4.5,
      reviewsCount: 10,
      categories: const ['Fiction'],
      isLiked: false,
      createdAt: DateTime(2024, 1, 1),
      coverColor: Book.defaultCoverColor,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BookCard(
              book: book,
              index: 0,
              onInfoPressed: () {
                infoTapped = true;
              },
            ),
          ),
        ),
      ),
    );

    final infoButton = find.byIcon(Icons.info_outline);
    expect(infoButton, findsOneWidget);

    await tester.tap(infoButton);
    await tester.pumpAndSettle();

    expect(infoTapped, isTrue);
  });
}

