import 'package:flutter/material.dart';

class CollectionAvatar extends StatelessWidget {
  final Map<String, dynamic> collection;
  final int index;

  const CollectionAvatar({
    super.key,
    required this.collection,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF6fbdbf),
      const Color(0xFFffd410),
      const Color(0xFF848f89),
      const Color(0xFF25b4c4),
    ];

    final avatarColor = index < colors.length ? colors[index] : colors[0];

    return Column(
      children: [
        SizedBox(
          height: 98,
          width: 73,
          child: Stack(
            children: [
              Positioned(
                left: 8,
                right: 8,
                top: 5,
                bottom: -8,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: avatarColor.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: avatarColor.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: 73,
                  height: 73,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      collection['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.center,
                              end: Alignment.bottomCenter,
                              colors: [avatarColor, avatarColor.withOpacity(0.7)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.collections_bookmark,
                            color: Colors.white,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -10),
          child: Text(
            collection['name']!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
              color: Color(0xFF5d666f),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}