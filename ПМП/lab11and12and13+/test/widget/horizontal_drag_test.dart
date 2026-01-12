import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lab11and12/widgets/bookCard.dart';
import 'package:lab11and12/models/bookModel.dart';

void main() {
  testWidgets('Horizontal ListView - Drag горизонтальный скролл', (WidgetTester tester) async {
    final books = List.generate(10, (index) => Book(
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
          body: Container(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 105,
                  child: BookCard(
                    book: books[index],
                    index: index,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Book 0'), findsOneWidget);
    expect(find.text('Book 9'), findsNothing);

    // Выполняем drag влево для горизонтального скролла
    await tester.drag(find.byType(ListView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    // После скролла должны увидеть другие книги
    expect(find.text('Book 0'), findsNothing);
    expect(find.text('Book 9'), findsOneWidget);
  });
}

