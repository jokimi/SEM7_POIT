import 'package:flutter/material.dart';

class CatalogActions extends StatelessWidget {
  const CatalogActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionItem(
            icon: Icons.list_alt_rounded,
            text: 'Catalog',
          ),
          _buildActionItem(
            icon: Icons.favorite_border_rounded,
            text: 'Like',
          ),
          _buildActionItem(
            icon: Icons.bookmark_add_outlined,
            text: 'Add To Bookshelf',
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String text}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey.shade500, size: 24),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5d666f),
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}