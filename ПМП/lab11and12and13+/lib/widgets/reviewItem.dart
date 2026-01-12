import 'package:flutter/material.dart';

class ReviewItem extends StatelessWidget {
  final String name;
  final String review;
  final double rating;
  final String avatarPath;

  const ReviewItem({
    super.key,
    required this.name,
    required this.review,
    required this.rating,
    required this.avatarPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 65,
            height: 65,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset(
                avatarPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getAvatarColor(name),
                          _getAvatarColor(name).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text(
                        name.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 25),
          // Review content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        color: Color(0xFF5d666f),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFffae1a),
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFffae1a),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  review,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6fbdbf),
      const Color(0xFFffae1a),
      const Color(0xFFfbcec9),
      const Color(0xFF858e85),
      const Color(0xFFf3d656),
      const Color(0xFF25b4c4),
    ];

    final index = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }
}