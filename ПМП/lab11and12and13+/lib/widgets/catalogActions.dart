import 'package:flutter/material.dart';

class CatalogActions extends StatelessWidget {
  final bool isLiked;
  final VoidCallback? onLikePressed;

  const CatalogActions({
    super.key,
    required this.isLiked,
    this.onLikePressed,
  });

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
            icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            text: isLiked ? 'Liked' : 'Like',
            iconColor: isLiked ? Colors.red : Colors.grey.shade500,
            onTap: onLikePressed,
          ),
          _buildActionItem(
            icon: Icons.bookmark_add_outlined,
            text: 'Add To Bookshelf',
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String text,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor ?? Colors.grey.shade500, size: 24),
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
    );

    if (onTap == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [content],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: content,
          ),
        ),
      ],
    );
  }
}