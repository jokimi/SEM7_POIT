import 'dart:ffi';

import 'package:hive/hive.dart';

part 'userModel.g.dart';

@HiveType(typeId: 1)
class User {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final int role; // 0 = user, 1 = admin

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String avatarPath;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.avatarPath = 'assets/avatar.jpg',
  });

  bool get isAdmin => role == 1;
  bool get isUser => role == 0;

  String get roleName {
    switch (role) {
      case 1:
        return 'Admin';
      default:
        return 'User';
    }
  }
}