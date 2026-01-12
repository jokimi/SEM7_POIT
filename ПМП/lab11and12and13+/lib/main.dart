import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'bloc/appBLoC.dart';
import 'bloc/appEvent.dart';
import 'bloc/appState.dart';
import 'models/bookModel.dart';
import 'screens/homeScreen.dart';
import 'screens/bookDetailScreen.dart';
import 'screens/adminBooksScreen.dart';
import 'screens/favoritesScreen.dart';
import 'screens/hiveStatsScreen.dart';
import 'screens/authScreen.dart';
import 'screens/profileScreen.dart';
import 'services/messagingService.dart';
import 'firebase_options.dart';
import 'services/hiveService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final messagingService = MessagingService();
    await messagingService.initialize();
  } catch (e) {
    print('Ошибка инициализации Firebase: $e');
  }
  
  try {
    await HiveService().init();
  } catch (e) {
    print('Ошибка инициализации Hive: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppBloc()..add(const AppInitialized()),
      child: MaterialApp(
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
        home: BlocBuilder<AppBloc, AppState>(
          builder: (context, state) {
            if (state is AppUnauthenticated) {
              return const AuthScreen();
            } else if (state is AppLoaded) {
              return HomeScreen();
            } else if (state is AppLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (state is AppError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: ${state.message}'),
                      ElevatedButton(
                        onPressed: () {
                          context.read<AppBloc>().add(const AppInitialized());
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
        routes: {
          '/home': (context) => HomeScreen(),
          '/auth': (context) => const AuthScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/book_detail': (context) {
            final book = ModalRoute.of(context)?.settings.arguments as Book?;
            if (book == null) {
              return const Scaffold(
                body: Center(child: Text('Книга не найдена')),
              );
            }
            return BookDetailScreen(book: book);
          },
          '/admin_books': (context) => AdminBooksScreen(),
          '/favorites': (context) => FavoritesScreen(),
          '/hive_stats': (context) => HiveStatsScreen(),
        },
      ),
    );
  }
}
