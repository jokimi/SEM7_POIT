import 'package:flutter/material.dart';

class ReadNowButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const ReadNowButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFffae1a),
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFffae1a).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFFffae1a).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Read Now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.east_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}