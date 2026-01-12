import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/bookModel.dart';
import '../models/favoriteModel.dart';
import '../models/reviewModel.dart';
import '../models/userModel.dart' as models;

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> enableOfflinePersistence() async {
    if (kIsWeb) {
      await _firestore.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );
      return;
    }

    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // CRUD для книг

  Stream<List<Book>> getBooksStream() {
    return _firestore
        .collection('books')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _bookFromFirestore(doc))
            .toList());
  }

  Future<List<Book>> getBooks() async {
    final snapshot = await _firestore
        .collection('books')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => _bookFromFirestore(doc)).toList();
  }

  Future<Book?> getBook(String id) async {
    final doc = await _firestore.collection('books').doc(id).get();
    if (doc.exists) {
      return _bookFromFirestore(doc);
    }
    return null;
  }

  Future<void> addBook(Book book) async {
    await _firestore.collection('books').doc(book.id).set(_bookToFirestore(book));
  }

  Future<void> updateBook(Book book) async {
    await _firestore.collection('books').doc(book.id).update(_bookToFirestore(book));
  }

  Future<void> deleteBook(String bookId) async {
    await _firestore.collection('books').doc(bookId).delete();
  }

  // CRUD для избранного

  Stream<List<Favorite>> getFavoritesStream(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _favoriteFromFirestore(doc))
            .toList());
  }

  Future<List<Favorite>> getFavorites(String userId) async {
    final snapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => _favoriteFromFirestore(doc)).toList();
  }

  Future<void> addToFavorites(String userId, String bookId) async {
    final favorite = Favorite(
      id: '${userId}_$bookId',
      userId: userId,
      bookId: bookId,
      addedAt: DateTime.now(),
    );
    await _firestore
        .collection('favorites')
        .doc(favorite.id)
        .set(_favoriteToFirestore(favorite));
  }

  Future<void> removeFromFavorites(String userId, String bookId) async {
    await _firestore.collection('favorites').doc('${userId}_$bookId').delete();
  }

  Future<bool> isBookInFavorites(String userId, String bookId) async {
    final doc = await _firestore
        .collection('favorites')
        .doc('${userId}_$bookId')
        .get();
    return doc.exists;
  }

  // CRUD для пользователей

  Future<void> addUser(models.User user) async {
    await _firestore.collection('users').doc(user.id).set(_userToFirestore(user));
  }

  Future<models.User?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return _userFromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUser(models.User user) async {
    await _firestore.collection('users').doc(user.id).update(_userToFirestore(user));
  }

  // Конвертация данных

  Book _bookFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Конвертируем reviews из Firestore
    List<Review> reviews = [];
    if (data['reviews'] != null && data['reviews'] is List) {
      reviews = (data['reviews'] as List)
          .map((reviewData) => Review.fromMap(reviewData as Map<String, dynamic>))
          .toList();
    }
    
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      description: data['description'] ?? '',
      imagePath: data['imagePath'] ?? 'assets/default_book.jpg',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewsCount: data['reviewsCount'] ?? 0,
      categories: List<String>.from(data['categories'] ?? []),
      isLiked: data['isLiked'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      coverColor: data['coverColor']?.toString() ?? Book.defaultCoverColor,
      reviews: reviews,
    );
  }

  Map<String, dynamic> _bookToFirestore(Book book) {
    return {
      'title': book.title,
      'author': book.author,
      'description': book.description,
      'imagePath': book.imagePath,
      'rating': book.rating,
      'reviewsCount': book.reviewsCount,
      'categories': book.categories,
      'isLiked': book.isLiked,
      'createdAt': Timestamp.fromDate(book.createdAt),
      'createdBy': book.createdBy,
      'reviews': book.reviews.map((review) => review.toMap()).toList(),
      'coverColor': book.coverColor,
    };
  }

  Favorite _favoriteFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Favorite(
      id: doc.id,
      userId: data['userId'] ?? '',
      bookId: data['bookId'] ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _favoriteToFirestore(Favorite favorite) {
    return {
      'userId': favorite.userId,
      'bookId': favorite.bookId,
      'addedAt': Timestamp.fromDate(favorite.addedAt),
    };
  }

  models.User _userFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return models.User(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      avatarPath: data['avatarPath'] ?? 'assets/avatar.jpg',
    );
  }

  Map<String, dynamic> _userToFirestore(models.User user) {
    return {
      'name': user.name,
      'email': user.email,
      'role': user.role,
      'createdAt': Timestamp.fromDate(user.createdAt),
      'avatarPath': user.avatarPath,
    };
  }
}

