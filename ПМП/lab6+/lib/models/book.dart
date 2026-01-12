import 'dart:ui';

class Review {
  final String name;
  final String review;
  final double rating;
  final String avatarPath;

  const Review({
    required this.name,
    required this.review,
    required this.rating,
    required this.avatarPath,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'review': review,
    'rating': rating,
    'avatarPath': avatarPath,
  };

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      name: json['name'],
      review: json['review'],
      rating: json['rating'],
      avatarPath: json['avatarPath'],
    );
  }
}

class Book {
  final String id;
  final String title;
  final String author;
  final double rating;
  final int reviewsCount;
  final List<String> categories;
  final Color coverColor;
  final String coverImage;
  final String description;
  final List<Review> reviews;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.rating,
    required this.reviewsCount,
    required this.categories,
    required this.coverColor,
    required this.coverImage,
    required this.description,
    required this.reviews,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'rating': rating,
    'reviewsCount': reviewsCount,
    'categories': categories,
    'coverColor': coverColor.value,
    'coverImage': coverImage,
    'description': description,
    'reviews': reviews.map((review) => review.toJson()).toList(),
  };

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      rating: json['rating'],
      reviewsCount: json['reviewsCount'],
      categories: List<String>.from(json['categories']),
      coverColor: Color(json['coverColor']),
      coverImage: json['coverImage'],
      description: json['description'],
      reviews: List<Review>.from(json['reviews'].map((x) => Review.fromJson(x))),
    );
  }
}