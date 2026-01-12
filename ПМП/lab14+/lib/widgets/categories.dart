import 'package:flutter/material.dart';

class Categories extends StatelessWidget {
  final List<String> categories;

  const Categories({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: categories.map((category) {
        return Chip(
          label: Text(
            category,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Pretendard',
              color: Color(0xFF5d666f),
            ),
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}