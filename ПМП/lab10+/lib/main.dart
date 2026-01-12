import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/appBLoC.dart';
import 'bloc/appEvent.dart';
import 'screens/homeScreen.dart';
import 'screens/bookDetailScreen.dart';
import 'screens/adminBooksScreen.dart';
import 'screens/favoritesScreen.dart';
import 'screens/hiveStatsScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppBloc()..add(const AppInitialized()),
      child: MaterialApp(
        title: 'Daily Reading with Hive',
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
          '/book_detail': (context) => BookDetailScreen(),
          '/admin_books': (context) => AdminBooksScreen(),
          '/favorites': (context) => FavoritesScreen(),
          '/hive_stats': (context) => HiveStatsScreen(),
        },
      ),
    );
  }
}