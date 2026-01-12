import 'package:flutter/material.dart';

class MySearchBar extends StatefulWidget {
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
  State<MySearchBar> createState() => _MySearchBarState();
}

class _MySearchBarState extends State<MySearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0.0,
        end: _isFocused ? 1.0 : 0.0,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFFf8f9fb),
              Colors.white,
              value,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300.withOpacity(1.0 - value * 0.7),
                blurRadius: 15 + value * 5,
                offset: Offset(0, 1 + value * 2),
                spreadRadius: 1 + value,
              ),
            ],
          ),
          child: TextField(
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                fontFamily: 'Pretendard',
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: Icon(Icons.search, color: Colors.grey.shade400),
            ),
            onChanged: widget.onChanged,
            onTap: widget.onTap,
          ),
        );
      },
    );
  }
}