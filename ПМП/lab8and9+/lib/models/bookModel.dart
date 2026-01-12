import 'package:hive/hive.dart';

part 'bookModel.g.dart';

@HiveType(typeId: 2)
class Book {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String author;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final String imagePath;

  @HiveField(6)
  final double rating;

  @HiveField(7)
  final int reviewsCount;

  @HiveField(8)
  final List<String> categories;

  @HiveField(9)
  final bool isLiked;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final String? createdBy;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.imagePath,
    required this.rating,
    required this.reviewsCount,
    required this.categories,
    required this.isLiked,
    required this.createdAt,
    this.createdBy,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? imagePath,
    double? rating,
    int? reviewsCount,
    List<String>? categories,
    bool? isLiked,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      categories: categories ?? this.categories,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}