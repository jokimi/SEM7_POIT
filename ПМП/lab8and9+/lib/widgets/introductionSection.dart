import 'package:flutter/material.dart';

class IntroductionSection extends StatefulWidget {
  const IntroductionSection({super.key});

  @override
  _IntroductionSectionState createState() => _IntroductionSectionState();
}

class _IntroductionSectionState extends State<IntroductionSection> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Introduction',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard',
                    color: Color(0xFF5d666f),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpanded ? 'Shrink' : 'Expand',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5d666f),
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF5d666f),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isExpanded
                ? 'The Crow\'s Vow is an extraordinarily moving book-length sequence that follows the story of a marriage come undone. Organized into four seasons, the book traces the emotional landscape of love, loss, and the possibility of redemption. Through lyrical prose and vivid imagery, Susan Briscoe explores the complexities of human relationships and the enduring power of memory. This profound work has been praised by critics for its emotional depth and literary craftsmanship.'
                : 'The Crow\'s Vow is an extraordinarily moving book-length sequence that follows the story of a marriage come undone. Organized into four seasons...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }
}