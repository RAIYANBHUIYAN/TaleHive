import 'package:supabase_flutter/supabase_flutter.dart';

class Club {
  final String id;
  final String name;
  final String description;
  final String authorId;
  final String? coverImageUrl;
  final bool isPremium;
  final double membershipPrice;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Author info (joined from authors table)
  final String? authorFirstName;
  final String? authorLastName;
  final String? authorPhotoUrl;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.authorId,
    this.coverImageUrl,
    required this.isPremium,
    required this.membershipPrice,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.authorFirstName,
    this.authorLastName,
    this.authorPhotoUrl,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      authorId: json['author_id'] as String,
      coverImageUrl: json['cover_image_url'] as String?,
      isPremium: json['is_premium'] as bool,
      membershipPrice: (json['membership_price'] as num).toDouble(),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      authorFirstName: json['author_first_name'] as String?,
      authorLastName: json['author_last_name'] as String?,
      authorPhotoUrl: json['author_photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'author_id': authorId,
      'cover_image_url': coverImageUrl,
      'is_premium': isPremium,
      'membership_price': membershipPrice,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get authorFullName {
    if (authorFirstName != null && authorLastName != null) {
      return '$authorFirstName $authorLastName';
    }
    return 'Unknown Author';
  }

  Club copyWith({
    String? id,
    String? name,
    String? description,
    String? authorId,
    String? coverImageUrl,
    bool? isPremium,
    double? membershipPrice,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorFirstName,
    String? authorLastName,
    String? authorPhotoUrl,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isPremium: isPremium ?? this.isPremium,
      membershipPrice: membershipPrice ?? this.membershipPrice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorFirstName: authorFirstName ?? this.authorFirstName,
      authorLastName: authorLastName ?? this.authorLastName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
    );
  }

  @override
  String toString() {
    return 'Club{id: $id, name: $name, authorId: $authorId, isPremium: $isPremium}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Club && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
