import 'package:flutter/material.dart';

class IntroductionSection extends StatefulWidget {
  final String description;

  const IntroductionSection({super.key, required this.description});

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
                ? widget.description
                : _limitWords(widget.description, 20),
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

  String _limitWords(String text, int wordLimit) {
    final words = text.split(' ');
    if (words.length <= wordLimit) {
      return text;
    }
    return words.take(wordLimit).join(' ') + '...';
  }
}