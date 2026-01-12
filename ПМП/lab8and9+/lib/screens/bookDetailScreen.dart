import 'package:flutter/material.dart';
import '../widgets/bookCover.dart';
import '../widgets/ratingSection.dart';
import '../widgets/categories.dart';
import '../widgets/catalogActions.dart';
import '../widgets/reviewItem.dart';
import '../widgets/readNowButton.dart';
import '../widgets/introductionSection.dart';

class BookDetailScreen extends StatelessWidget {
  final Map<String, dynamic> bookData = {
    'title': 'The Crow\'s Vow',
    'author': 'Susan Briscoe',
    'rating': 9.2,
    'reviewsCount': 156,
    'categories': ['Travelers', 'Literature'],
    'coverColor': Color(0xFFfbcec9),
    'coverImage': 'assets/thecrowsvow.jpg',
  };

  @override
  Widget build(BuildContext context) {
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
            color: Color(0xFF5d666f),
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: const Icon(Icons.ios_share_rounded, color: Colors.black),
              onPressed: () {},
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
                _buildBookHeader(),
                const SizedBox(height: 20),
                const CatalogActions(),
                const SizedBox(height: 20),
                const IntroductionSection(),
                const SizedBox(height: 20),
                _buildReviewsSection(),
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
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookHeader() {
    return Container(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BookCover(
            imagePath: bookData['coverImage']!,
            backgroundColor: bookData['coverColor'],
            width: 140,
            height: 220,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildBookInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookInfo() {
    return Container(
      height: 170,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bookData['title']!,
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
            bookData['author']!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 12),
          RatingSection(
            rating: bookData['rating'] as double,
            reviewsCount: bookData['reviewsCount'] as int,
          ),
          const SizedBox(height: 16),
          Categories(
            categories: bookData['categories'] as List<String>,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
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
        ReviewItem(
          name: 'Dolores',
          review: 'Beautiful graphics. Nothing else like it that I know of. Makes one focus...',
          rating: 9.2,
          avatarPath: 'assets/dolores.jpg',
        ),
        const SizedBox(height: 20),
        ReviewItem(
          name: 'Anna Lawrence',
          review: 'Amazing book! Truly a work of art, a true inspiration.',
          rating: 8.9,
          avatarPath: 'assets/anna.jpg',
        ),
        const SizedBox(height: 20),
        ReviewItem(
          name: 'Theo',
          review: 'Captivating storyline with deep character development.',
          rating: 7.0,
          avatarPath: 'assets/theo.jpg',
        ),
      ],
    );
  }
}