// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookModel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 2;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      description: fields[4] as String,
      imagePath: fields[5] as String,
      rating: fields[6] as double,
      reviewsCount: fields[7] as int,
      categories: (fields[8] as List).cast<String>(),
      isLiked: fields[9] as bool,
      createdAt: fields[11] as DateTime,
      createdBy: fields[12] as String?,
      coverColor: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.imagePath)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.reviewsCount)
      ..writeByte(8)
      ..write(obj.categories)
      ..writeByte(9)
      ..write(obj.isLiked)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.createdBy)
      ..writeByte(13)
      ..write(obj.coverColor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
