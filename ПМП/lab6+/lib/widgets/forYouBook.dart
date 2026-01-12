import 'package:flutter/material.dart';
import '../models/book.dart';
import 'bookCover.dart';

class ForYouBook extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  const ForYouBook({super.key, required this.book, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            Padding(
              padding: const EdgeInsets.only(left: 155),
              child: BookDescription(book: book),
            ),
            Positioned(
              left: 0,
              top: -31,
              child: BookCover(
                imagePath: book.coverImage,
                backgroundColor: book.coverColor,
                width: 130,
                height: 190,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookDescription extends StatelessWidget {
  final Book book;

  const BookDescription({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${book.title}: action and adventure',
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
          _limitWords(book.description, 10),
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
            fontFamily: 'Pretendard',
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        const ReadMoreButton(),
      ],
    );
  }

  String _limitWords(String text, int wordLimit) {
    final words = text.split(' ');
    if (words.length <= wordLimit) {
      return text;
    }
    return words.take(wordLimit).join(' ') + '...';
  }
}

class ReadMoreButton extends StatelessWidget {
  const ReadMoreButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}