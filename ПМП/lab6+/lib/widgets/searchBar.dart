import 'package:flutter/material.dart';

class MySearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String hintText;

  const MySearchBar({
    super.key,
    this.onChanged,
    this.onTap,
    this.hintText = 'Which book would you like to read today?',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFf8f9fb),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 15,
            offset: const Offset(0, 1),
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade400,
            fontFamily: 'Pretendard',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: Icon(Icons.search, color: Colors.grey.shade400),
        ),
        onChanged: onChanged,
        onTap: onTap,
      ),
    );
  }
}