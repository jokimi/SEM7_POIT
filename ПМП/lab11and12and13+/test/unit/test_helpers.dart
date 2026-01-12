import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:lab11and12/bloc/appBLoC.dart';
import 'package:lab11and12/models/bookModel.dart';
import 'package:lab11and12/models/favoriteModel.dart';
import 'package:lab11and12/models/userModel.dart' as models;
import 'package:lab11and12/services/analyticsService.dart';
import 'package:lab11and12/services/authService.dart';
import 'package:lab11and12/services/databaseService.dart';
import 'package:lab11and12/services/firestoreService.dart';
import 'package:lab11and12/services/hiveService.dart';
import 'package:lab11and12/services/remoteConfigService.dart';
import 'package:mockito/mockito.dart';
import '../mocks.mocks.dart';

Future<void> _voidFuture() async {}

const userId = 'user-1';

final sampleUser = models.User(
  id: userId,
  name: 'jokimi',
  email: 'jokeiminny@gmail.com',
  role: 0,
  createdAt: DateTime(2025, 12, 8),
);

final sampleBook = Book(
  id: 'book-1',
  title: 'Timber',
  author: 'Author',
  description: 'Desc',
  imagePath: 'assets/timber.jpg',
  rating: 4.5,
  reviewsCount: 10,
  categories: const ['Nature'],
  isLiked: false,
  createdAt: DateTime(2025, 1, 1),
  createdBy: userId,
  coverColor: Book.defaultCoverColor,
);

final likedBook = sampleBook.copyWith(isLiked: true);

AppBloc createTestBloc({
  MockFirestoreService? firestoreService,
  MockAuthService? authService,
  MockDatabaseService? databaseService,
  MockAnalyticsService? analyticsService,
  MockRemoteConfigService? remoteConfigService,
  MockHiveService? hiveService,
  Stream<User?>? authStateStreamOverride,
}) {
  final fs = firestoreService ?? MockFirestoreService();
  final as = authService ?? MockAuthService();
  final ds = databaseService ?? MockDatabaseService();
  final ans = analyticsService ?? MockAnalyticsService();
  final rcs = remoteConfigService ?? MockRemoteConfigService();
  final hs = hiveService ?? MockHiveService();

  when(rcs.initialize()).thenAnswer((_) => _voidFuture());
  when(fs.enableOfflinePersistence()).thenAnswer((_) => _voidFuture());
  when(rcs.isLikeButtonEnabled()).thenReturn(true);
  when(ds.initializeUserStatus()).thenAnswer((_) => _voidFuture());
  when(ds.cleanup()).thenAnswer((_) => _voidFuture());
  when(as.signOut()).thenAnswer((_) => _voidFuture());
  when(ans.setUserId(any)).thenAnswer((_) => _voidFuture());
  when(ans.logLogin(any)).thenAnswer((_) => _voidFuture());
  when(ans.logSignUp(any)).thenAnswer((_) => _voidFuture());
  when(ans.logSearch(any)).thenAnswer((_) => _voidFuture());
  when(ans.logBookView(any, any)).thenAnswer((_) => _voidFuture());
  when(ans.logBookLiked(any, any)).thenAnswer((_) => _voidFuture());
  when(ans.logBookUnliked(any, any)).thenAnswer((_) => _voidFuture());
  when(hs.replaceBooks(any)).thenAnswer((_) => _voidFuture());
  when(hs.replaceFavorites(any, any)).thenAnswer((_) => _voidFuture());
  when(hs.addToFavorites(any, any)).thenAnswer((_) => _voidFuture());
  when(hs.removeFromFavorites(any, any)).thenAnswer((_) => _voidFuture());
  when(hs.getBooks()).thenReturn([]);
  when(hs.getFavorites(any)).thenReturn([]);
  when(hs.addBook(any)).thenAnswer((_) => _voidFuture());
  when(hs.updateBook(any)).thenAnswer((_) => _voidFuture());
  when(hs.deleteBook(any)).thenAnswer((_) => _voidFuture());

  when(as.authStateChanges).thenAnswer((_) => const Stream.empty());

  return AppBloc(
    firestoreService: fs,
    authService: as,
    databaseService: ds,
    analyticsService: ans,
    remoteConfigService: rcs,
    hiveService: hs,
    authStateStreamOverride: authStateStreamOverride ?? Stream<User?>.empty(),
  );
}