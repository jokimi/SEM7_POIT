class Review {
  final String name;
  final String review;
  final double rating;
  final String avatarPath;

  Review({
    required this.name,
    required this.review,
    required this.rating,
    required this.avatarPath,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      name: map['name'] ?? '',
      review: map['review'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      avatarPath: map['avatarPath'] ?? 'assets/avatar.jpg',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'review': review,
      'rating': rating,
      'avatarPath': avatarPath,
    };
  }
}

