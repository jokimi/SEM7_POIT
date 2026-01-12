import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logBookView(String bookId, String bookTitle) async {
    await _analytics.logEvent(
      name: 'book_view',
      parameters: {
        'book_id': bookId,
        'book_title': bookTitle,
      },
    );
  }

  Future<void> logBookLiked(String bookId, String bookTitle) async {
    await _analytics.logEvent(
      name: 'book_liked',
      parameters: {
        'book_id': bookId,
        'book_title': bookTitle,
      },
    );
  }

  Future<void> logBookUnliked(String bookId, String bookTitle) async {
    await _analytics.logEvent(
      name: 'book_unliked',
      parameters: {
        'book_id': bookId,
        'book_title': bookTitle,
      },
    );
  }

  Future<void> logSearch(String searchQuery) async {
    await _analytics.logEvent(
      name: 'search',
      parameters: {
        'search_query': searchQuery,
      },
    );
  }

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logBookCreated(String bookId, String bookTitle) async {
    await _analytics.logEvent(
      name: 'book_created',
      parameters: {
        'book_id': bookId,
        'book_title': bookTitle,
      },
    );
  }

  Future<void> logBookDeleted(String bookId) async {
    await _analytics.logEvent(
      name: 'book_deleted',
      parameters: {
        'book_id': bookId,
      },
    );
  }

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }
}

