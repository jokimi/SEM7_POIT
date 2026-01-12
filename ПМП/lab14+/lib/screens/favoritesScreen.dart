import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/appBLoC.dart';
import '../bloc/appEvent.dart';
import '../bloc/appState.dart';
import '../models/bookModel.dart';
import '../widgets/staggeredAnimation.dart';

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
              final startDelay = Duration(milliseconds: index * 600);
              return FavoriteAnimatedCard(
                startDelay: startDelay,
                book: book,
                onTap: () => _showBookDetails(context, book),
                onRemove: () {
                  context.read<AppBloc>().add(FavoriteToggled(book.id));
                },
              );
            },
          );
        },
      ),
    );
  }
}

class FavoriteAnimatedCard extends StatefulWidget {
  final Book book;
  final Duration startDelay;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const FavoriteAnimatedCard({
    super.key,
    required this.book,
    required this.startDelay,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<FavoriteAnimatedCard> createState() => _FavoriteAnimatedCardState();
}

class _FavoriteAnimatedCardState extends State<FavoriteAnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blockOpacity;
  late Animation<double> _blockScale;
  late Animation<double> _coverOpacity;
  late Animation<double> _titleOpacity;
  late Animation<double> _descOpacity;
  late Animation<double> _actionsOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Ступени

    _blockOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2, curve: Curves.easeOut)),
    );
    _blockScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2, curve: Curves.easeOutBack)),
    );
    _coverOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.4, curve: Curves.easeOut)),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.55, curve: Curves.easeOut)),
    );
    _descOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.55, 0.75, curve: Curves.easeOut)),
    );
    _actionsOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.75, 1.0, curve: Curves.easeOut)),
    );

    Future.delayed(widget.startDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return FadeTransition(
      opacity: _blockOpacity,
      child: ScaleTransition(
        scale: _blockScale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 50),
          child: GestureDetector(
            onTap: widget.onTap,
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
                  // Кнопка удаления — стадия 5
                  Positioned(
                    top: -5,
                    right: -5,
                    child: FadeTransition(
                      opacity: _actionsOpacity,
                      child: GestureDetector(
                        onTap: widget.onRemove,
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
                  ),

                  // Текстовый блок — стадии 3 и 4
                  Padding(
                    padding: const EdgeInsets.only(left: 155),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                          opacity: _titleOpacity,
                          child: Text(
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
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _descOpacity,
                          child: Text(
                            _limitWordsLocal(book.description, 15),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                              fontFamily: 'Pretendard',
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Read More — стадия 5
                        FadeTransition(
                          opacity: _actionsOpacity,
                          child: Container(
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
                        ),
                      ],
                    ),
                  ),

                  // Обложка — стадия 2
                  Positioned(
                    left: 0,
                    top: -33,
                    child: FadeTransition(
                      opacity: _coverOpacity,
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
                                      _getColorFromStringLocal(book.title),
                                      _getColorFromStringLocal(book.title).withOpacity(0.7),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _limitWordsLocal(String text, int wordLimit) {
    final words = text.split(' ');
    if (words.length <= wordLimit) {
      return text;
    }
    return words.take(wordLimit).join(' ') + '...';
  }

  Color _getColorFromStringLocal(String text) {
    final colors = [
      const Color(0xFFf5bc15),
      const Color(0xFF858e85),
      const Color(0xFFf3d656),
      const Color(0xFFfbcec9),
      const Color(0xFFd0c9b7),
      const Color(0xFF6fbdbf),
      const Color(0xFF25b4c4),
    ];

    final index = text.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }
}