import 'package:flutter/material.dart';
import 'models/book.dart';
import 'screens/homeScreen.dart';
import 'screens/bookDetailScreen.dart';
import 'screens/bookViewerScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Reading',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Pretendard',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard',
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontFamily: 'Pretendard',
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
      home: HomeScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/book_detail': (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments;
          if (arguments is Book) {
            return BookDetailScreen(book: arguments);
          }
          return const Scaffold(body: Center(child: Text('Book not found')));
        },
        '/book_viewer': (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments;
          if (arguments is Book) {
            return BookViewerScreen(book: arguments);
          }
          return const Scaffold(body: Center(child: Text('Book not found')));
        },
      },
    );
  }
}