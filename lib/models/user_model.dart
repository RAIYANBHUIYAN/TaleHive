class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? contactNo;
  final String? photoUrl;
  final String role;
  final int booksRead;
  final String? favoriteGenres;
  final bool isActive;
  final DateTime? createdAt;
  final String? favourites; // Note: keeping the exact column name "Favourites"

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.contactNo,
    this.photoUrl,
    this.role = 'reader',
    this.booksRead = 0,
    this.favoriteGenres,
    this.isActive = true,
    this.createdAt,
    this.favourites,
  });

  // Helper method to get full name
  String get fullName {
    final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return name.isNotEmpty ? name : (username ?? 'Unknown User');
  }

  // Safely convert database values to boolean
  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      final s = value.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes' || s == 'y' || s == 't';
    }
    if (value is num) return value != 0;
    return false;
  }

  // Create User from database map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      firstName: map['first_name']?.toString(),
      lastName: map['last_name']?.toString(),
      username: map['username']?.toString(),
      contactNo: map['contact_no']?.toString(),
      photoUrl: map['photo_url']?.toString(),
      role: map['role']?.toString() ?? 'reader',
      booksRead: map['books_read'] != null 
          ? int.tryParse(map['books_read'].toString()) ?? 0 
          : 0,
      favoriteGenres: map['favorite_genres']?.toString(),
      isActive: _toBool(map['is_active']),
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      favourites: map['Favourites']?.toString(), // Note the capital F
    );
  }

  // Convert User to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'contact_no': contactNo,
      'photo_url': photoUrl,
      'role': role,
      'books_read': booksRead,
      'favorite_genres': favoriteGenres,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'Favourites': favourites,
    };
  }

  // Create a copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    String? contactNo,
    String? photoUrl,
    String? role,
    int? booksRead,
    String? favoriteGenres,
    bool? isActive,
    DateTime? createdAt,
    String? favourites,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      contactNo: contactNo ?? this.contactNo,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      booksRead: booksRead ?? this.booksRead,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      favourites: favourites ?? this.favourites,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, email: $email, isActive: $isActive, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
