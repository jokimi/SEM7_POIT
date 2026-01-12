import 'package:flutter/material.dart';
import '../models/book.dart';

class BookViewerScreen extends StatefulWidget {
  final Book? book;
  const BookViewerScreen({super.key, required this.book});
  @override
  _BookViewerScreenState createState() => _BookViewerScreenState();
}

class _BookViewerScreenState extends State<BookViewerScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> bookPages = [
    "Chapter 1\n\nThe journey begins on a misty morning. The protagonist stands at the crossroads, uncertain of which path to take. Each road represents a different future, a different destiny waiting to unfold.",
    "Chapter 2\n\nMemories flood back - childhood days spent in the old house by the river. The scent of blooming jasmine, the sound of flowing water, the warmth of summer sun on skin.",
    "Chapter 3\n\nA chance encounter changes everything. In a crowded marketplace, their eyes meet across the sea of people. Time seems to stand still as recognition dawns.",
    "Chapter 4\n\nThe storm arrives unexpectedly, mirroring the turmoil within. Rain lashes against windows while secrets are revealed in the flickering candlelight.",
    "Chapter 5\n\nA difficult decision must be made. Sacrifices loom on the horizon, and the weight of responsibility presses down like physical force.",
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.book == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentBook = widget.book!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentBook.title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
              ),
            ),
            Text(
              'Page ${_currentPage + 1} of ${bookPages.length}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / bookPages.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(currentBook.coverColor),
            minHeight: 3,
          ),

          // PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: bookPages.length,
              itemBuilder: (context, index) {
                return _buildPage(bookPages[index], index, currentBook);
              },
            ),
          ),

          // Navigation controls
          _buildNavigationControls(currentBook),
        ],
      ),
    );
  }

  Widget _buildPage(String content, int pageIndex, Book currentBook) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основной контент страницы
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                fontFamily: 'Pretendard',
                color: Color(0xFF5d666f),
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),

            // Если это последняя страница, показываем завершение книги
            if (pageIndex == bookPages.length - 1)
              _buildBookEnd(currentBook),
          ],
        ),
      ),
    );
  }

  Widget _buildBookEnd(Book currentBook) {
    return Center(
      child: Container(
        width: double.infinity, // Занимает всю доступную ширину
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: currentBook.coverColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Минимальный размер по содержимому
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              size: 50,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve finished reading "${currentBook.title}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Pretendard',
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: currentBook.coverColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Return',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls(Book currentBook) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          ElevatedButton.icon(
            onPressed: _currentPage > 0
                ? () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
                : null,
            icon: const Icon(Icons.west_rounded),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black,
            ),
          ),

          // Page indicator
          Text(
            '${_currentPage + 1} / ${bookPages.length}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),

          // Next button
          ElevatedButton.icon(
            onPressed: _currentPage < bookPages.length - 1
                ? () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
                : null,
            icon: const Text('Next'),
            label: const Icon(Icons.east_rounded),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentBook.coverColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}