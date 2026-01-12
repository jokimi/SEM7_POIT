import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/appBLoC.dart';
import '../bloc/appEvent.dart';
import '../bloc/appState.dart';
import '../models/bookModel.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Color _getColorFromString(String text) {
    final colors = [
      Color(0xFFf5bc15),
      Color(0xFF858e85),
      Color(0xFFf3d656),
      Color(0xFFfbcec9),
      Color(0xFFd0c9b7),
      Color(0xFF6fbdbf),
      Color(0xFF25b4c4),
    ];

    final index = text.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  String _limitWords(String text, int wordLimit) {
    final words = text.split(' ');
    if (words.length <= wordLimit) {
      return text;
    }
    return words.take(wordLimit).join(' ') + '...';
  }

  void _showBookDetails(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 150,
                  child: Image.asset(
                    book.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getColorFromString(book.title),
                              _getColorFromString(book.title).withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.book,
                          color: Colors.white,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Author: ${book.author}'),
              const SizedBox(height: 8),
              Text('Rating: ${book.rating}'),
              Text('Reviews: ${book.reviewsCount}'),
              Text('Liked: ${book.isLiked ? "Yes" : "No"}'),
              const SizedBox(height: 8),
              Text('Categories: ${book.categories.join(", ")}'),
              const SizedBox(height: 8),
              Text('Description: ${book.description}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorite Books',
          style: TextStyle(
            color: Color(0xFF5d666f),
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          if (state is AppLoading || (state is AppLoaded && state.isLoading)) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is! AppLoaded) {
            return const Center(
              child: Text('Ошибка загрузки данных'),
            );
          }

          final bloc = context.read<AppBloc>();
          final favoriteBooks = bloc.getFavoriteBooks();

          if (favoriteBooks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Нет избранных книг',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(25, 35, 25, 25),
            itemCount: favoriteBooks.length,
            itemBuilder: (context, index) {
              final book = favoriteBooks[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 50),
                child: GestureDetector(
                  onTap: () {
                    _showBookDetails(context, book);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 15,
                          offset: const Offset(0, 1),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                      Positioned(
                        top: -5,
                        right: -5,
                        child: GestureDetector(
                          key: Key('favorites_remove_${book.id}'),
                          onTap: () {
                            context.read<AppBloc>().add(FavoriteToggled(book.id));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                        Padding(
                          padding: const EdgeInsets.only(left: 155),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Pretendard',
                                  color: Color(0xFF5d666f),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _limitWords(book.description, 15),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade400,
                                  fontFamily: 'Pretendard',
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFffae1a),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Read More',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Pretendard',
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.east_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: -33,
                          child: Container(
                            width: 130,
                            height: 190,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                book.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _getColorFromString(book.title),
                                          _getColorFromString(book.title).withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.book,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}