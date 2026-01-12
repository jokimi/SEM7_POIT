import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final String actionText;

  const SectionHeader({
    super.key,
    required this.title,
    this.onTap,
    this.actionText = 'More',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
            color: Color(0xFF5d666f),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ],
    );
  }
}