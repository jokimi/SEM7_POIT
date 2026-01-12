import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final int index;
  final VoidCallback? onTap;

  const BookCard({
    super.key,
    required this.book,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bookColor = book['color'] as Color;

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
                    book['image']!,
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
                        child: Center(
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
            ],
          ),
        ),
        Container(
          height: 35,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['title']!,
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
                    book['author']!,
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