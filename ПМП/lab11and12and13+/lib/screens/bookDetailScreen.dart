import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/appBLoC.dart';
import '../bloc/appEvent.dart';
import '../bloc/appState.dart';
import '../models/bookModel.dart';
import '../models/reviewModel.dart';
import '../widgets/bookCover.dart';
import '../widgets/ratingSection.dart';
import '../widgets/categories.dart';
import '../widgets/catalogActions.dart';
import '../widgets/reviewItem.dart';
import '../widgets/readNowButton.dart';
import '../widgets/introductionSection.dart';
import '../utils/color_parser.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    final coverColor = ColorParser.fromString(book.coverColor);

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
                _buildBookHeader(context, coverColor),
                const SizedBox(height: 20),
                _buildCatalogActions(context),
                const SizedBox(height: 20),
                IntroductionSection(description: book.description),
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

  Widget _buildBookHeader(BuildContext context, Color coverColor) {
    return Container(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BookCover(
            imagePath: book.imagePath,
            backgroundColor: coverColor,
            width: 140,
            height: 220,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildBookInfo(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBookInfo(BuildContext context) {
    return Container(
      height: 170,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard',
                    color: Color(0xFF5d666f),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            book.author,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 12),
          RatingSection(
            rating: book.rating,
            reviewsCount: book.reviewsCount,
          ),
          const SizedBox(height: 16),
          Categories(
            categories: book.categories,
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogActions(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final appBloc = context.read<AppBloc>();
        final likeEnabled = appBloc.remoteConfigService.isLikeButtonEnabled();
        final isLiked = state is AppLoaded
            ? appBloc.isBookInFavorites(book.id)
            : book.isLiked;

        return CatalogActions(
          isLiked: isLiked,
          onLikePressed: (likeEnabled && state is AppLoaded)
              ? () {
                  context.read<AppBloc>().add(FavoriteToggled(book.id));
                }
              : null,
        );
      },
    );
  }

  Widget _buildReviewsSection() {
    if (book.reviews.isEmpty) {
      return const SizedBox.shrink();
    }

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
        ...book.reviews.asMap().entries.map((entry) {
          final review = entry.value;
          final isLast = entry.key == book.reviews.length - 1;
          return Column(
            children: [
              ReviewItem(
                name: review.name,
                review: review.review,
                rating: review.rating,
                avatarPath: review.avatarPath,
              ),
              if (!isLast) const SizedBox(height: 20),
            ],
          );
        }).toList(),
      ],
    );
  }
}