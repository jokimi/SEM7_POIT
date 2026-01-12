import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int activeIndex;

  const CustomBottomNavigationBar({super.key, this.activeIndex = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.collections_bookmark_rounded, 0),
          _buildNavItem(Icons.explore, 1, isActive: activeIndex == 1),
          _buildNavItem(Icons.bar_chart_rounded, 2),
          _buildNavItem(Icons.person_2_rounded, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, {bool isActive = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Icon(
            icon,
            size: 30,
            color: isActive ? const Color(0xFF5d666f) : Colors.grey.shade400,
          ),
        ),
        if (isActive)
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: CircleIndicator(),
          )
        else
          const Padding(
            padding: EdgeInsets.only(bottom: 11),
            child: SizedBox(height: 12),
          ),
      ],
    );
  }
}

class CircleIndicator extends StatelessWidget {
  const CircleIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFffae1a),
      ),
    );
  }
}