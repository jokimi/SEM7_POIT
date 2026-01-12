import 'package:flutter/material.dart';

class RatingSection extends StatelessWidget {
  final double rating;
  final int reviewsCount;

  const RatingSection({
    super.key,
    required this.rating,
    required this.reviewsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Star rating
            Row(
              children: List.generate(5, (index) {
                final starValue = rating / 2;
                if (index < starValue.floor()) {
                  return const Icon(Icons.star_rounded, color: Color(0xFFffae1a), size: 20);
                } else {
                  return Icon(Icons.star_rounded, color: Colors.grey.shade400, size: 20);
                }
              }),
            ),
            const SizedBox(width: 8),
            // Rating text
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${rating.toStringAsFixed(1)} ',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFffae1a),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  TextSpan(
                    text: '($reviewsCount)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}