import 'package:flutter/material.dart';
import 'dart:ui';

class BookCover extends StatelessWidget {
  final String imagePath;
  final Color backgroundColor;
  final double width;
  final double height;

  const BookCover({
    super.key,
    required this.imagePath,
    required this.backgroundColor,
    this.width = 140,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Blur effect
          Positioned(
            left: -10,
            right: -10,
            top: 196,
            bottom: -20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor.withOpacity(0.6),
                      backgroundColor.withOpacity(0.1),
                      backgroundColor.withOpacity(0.05),
                      backgroundColor.withOpacity(0.0),
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
          // Main cover image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [backgroundColor, Colors.black26],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.book,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}