import 'package:flutter/material.dart';
import '../widgets/bookCover.dart';
import '../widgets/ratingSection.dart';
import '../widgets/categories.dart';
import '../widgets/catalogActions.dart';
import '../widgets/reviewItem.dart';
import '../widgets/readNowButton.dart';
import '../widgets/introductionSection.dart';
import '../models/book.dart';
import 'bookViewerScreen.dart';

class BookDetailScreen extends StatelessWidget {
  final Book? book;

  // Основной конструктор
  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    // Если книга не передана, показываем заглушку или возвращаемся назад
    if (book == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentBook = book!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 7),
          child: IconButton(
            icon: const Icon(Icons.west_rounded, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          '',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: const Icon(Icons.ios_share_rounded, color: Colors.black),
              onPressed: () {
                Navigator.pop(context, 'Book shared: ${currentBook.title}');
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookHeader(currentBook),
                const SizedBox(height: 20),
                const CatalogActions(),
                const SizedBox(height: 20),
                IntroductionSection(description: currentBook.description),
                const SizedBox(height: 20),
                _buildReviewsSection(currentBook), // Передаем currentBook как параметр
                const SizedBox(height: 25),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.8),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 136,
            bottom: 60,
            child: ReadNowButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookViewerScreen(book: currentBook),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookHeader(Book currentBook) {
    return Container(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BookCover(
            imagePath: currentBook.coverImage,
            backgroundColor: currentBook.coverColor,
            width: 140,
            height: 220,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildBookInfo(currentBook),
          ),
        ],
      ),
    );
  }

  Widget _buildBookInfo(Book currentBook) {
    return Container(
      height: 170,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentBook.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
              color: Color(0xFF5d666f),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            currentBook.author,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 12),
          RatingSection(
            rating: currentBook.rating,
            reviewsCount: currentBook.reviewsCount,
          ),
          const SizedBox(height: 16),
          Categories(
            categories: currentBook.categories,
          ),
        ],
      ),
    );
  }

  // Добавляем параметр currentBook в метод
  Widget _buildReviewsSection(Book currentBook) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
            color: Color(0xFF5d666f),
          ),
        ),
        const SizedBox(height: 15),
        // Используем отзывы из текущей книги
        ...currentBook.reviews.map((review) => Column(
          children: [
            ReviewItem(
              name: review.name,
              review: review.review,
              rating: review.rating,
              avatarPath: review.avatarPath,
            ),
            const SizedBox(height: 20),
          ],
        )).toList(),
      ],
    );
  }
}