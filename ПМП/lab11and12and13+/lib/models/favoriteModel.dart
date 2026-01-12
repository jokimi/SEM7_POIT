import 'package:hive/hive.dart';

part 'favoriteModel.g.dart';

@HiveType(typeId: 3)
class Favorite {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String bookId;

  @HiveField(3)
  final DateTime addedAt;

  Favorite({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.addedAt,
  });
}