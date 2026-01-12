import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/bookModel.dart';
import '../utils/color_parser.dart';

class BookCard extends StatelessWidget {
  final dynamic book;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onInfoPressed;
  final VoidCallback? onLikePressed;
  final bool? isLiked; // ДОБАВЛЕННЫЙ ПАРАМЕТР

  const BookCard({
    super.key,
    required this.book,
    required this.index,
    this.onTap,
    this.onInfoPressed,
    this.onLikePressed,
    this.isLiked, // ДОБАВЛЕННЫЙ ПАРАМЕТР
  });

  @override
  Widget build(BuildContext context) {
    final isHiveBook = book is Book;
    final bookColor = isHiveBook
        ? ColorParser.fromString(book.coverColor)
        : (book['color'] as Color? ?? const Color(0xFFd0c9b7));

    final imagePath = isHiveBook ? book.imagePath : book['image']!;
    final title = isHiveBook ? book.title : book['title']!;
    final author = isHiveBook ? book.author : book['author']!;

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned(
                left: -10,
                right: -10,
                top: 146,
                bottom: -20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          bookColor.withOpacity(0.6),
                          bookColor.withOpacity(0.1),
                          bookColor.withOpacity(0.05),
                          bookColor.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.3, 0.6, 1],
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 156,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [bookColor, Colors.black26],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.book,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Кнопка информации (открывает модалку с инфо о книге)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onInfoPressed,
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
                      Icons.info_outline,
                      color: Color(0xFF5d666f),
                      size: 16,
                    ),
                  ),
                ),
              ),
              // Кнопка лайка для Hive книг
              if (isHiveBook && onLikePressed != null)
                Positioned(
                  bottom: 22,
                  right: 8,
                  child: GestureDetector(
                    onTap: onLikePressed,
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
                      child: Icon(
                        (isLiked ?? false) ? Icons.favorite : Icons.favorite_border,
                        color: (isLiked ?? false) ? Colors.red : Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          height: isHiveBook ? 50 : 35,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard',
                      color: Color(0xFF5d666f),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    author,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      fontFamily: 'Pretendard',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return onTap != null
        ? GestureDetector(
      onTap: onTap,
      child: cardContent,
    )
        : cardContent;
  }
}