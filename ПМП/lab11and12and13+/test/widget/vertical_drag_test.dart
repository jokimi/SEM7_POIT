import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lab11and12/widgets/bookCard.dart';
import 'package:lab11and12/models/bookModel.dart';

void main() {
  testWidgets('ListView - Drag вертикальный скролл', (WidgetTester tester) async {
    final books = List.generate(15, (index) => Book(
      id: 'book-$index',
      title: 'Book $index',
      author: 'Author $index',
      description: 'Description $index',
      imagePath: 'assets/timber.jpg',
      rating: 4.0,
      reviewsCount: 10,
      categories: const ['Fiction'],
      isLiked: false,
      createdAt: DateTime(2024, 1, 1),
      coverColor: Book.defaultCoverColor,
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: books
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: BookCard(book: b, index: books.indexOf(b)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Book 0'), findsOneWidget);
    expect(find.text('Book 14'), findsNothing);

    // Выполняем drag вверх — скроллим всю страницу
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();

    // После скролла должны увидеть другие книги
    expect(find.text('Book 0'), findsNothing);
    expect(find.text('Book 14'), findsOneWidget);
  });
}

