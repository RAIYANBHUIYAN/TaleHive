class Author {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? contactNo;
  final String? photoUrl;
  final String? role;
  final int booksPublished;
  final int totalViews;
  final int totalDownloads;
  final String? bio;
  final String verificationStatus;
  final DateTime? createdAt;
  final String? displayName;
  final bool isActive;

  Author({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.contactNo,
    this.photoUrl,
    this.role = 'author',
    this.booksPublished = 0,
    this.totalViews = 0,
    this.totalDownloads = 0,
    this.bio,
    this.verificationStatus = 'pending',
    this.createdAt,
    this.displayName,
    this.isActive = true,
  });

  // Helper method to get display name with fallback
  String get fullDisplayName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!;
    }
    
    final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return name.isNotEmpty ? name : 'Unknown Author';
  }

  // Check if author is verified
  bool get isVerified => verificationStatus == 'verified';

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

  // Create Author from database map
  factory Author.fromMap(Map<String, dynamic> map) {
    return Author(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      firstName: map['first_name']?.toString(),
      lastName: map['last_name']?.toString(),
      contactNo: map['contact_no']?.toString(),
      photoUrl: map['photo_url']?.toString(),
      role: map['role']?.toString() ?? 'author',
      booksPublished: map['books_published'] != null 
          ? int.tryParse(map['books_published'].toString()) ?? 0 
          : 0,
      totalViews: map['total_views'] != null 
          ? int.tryParse(map['total_views'].toString()) ?? 0 
          : 0,
      totalDownloads: map['total_downloads'] != null 
          ? int.tryParse(map['total_downloads'].toString()) ?? 0 
          : 0,
      bio: map['bio']?.toString(),
      verificationStatus: map['verification_status']?.toString() ?? 'pending',
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      displayName: map['display_name']?.toString(),
      isActive: _toBool(map['is_active']),
    );
  }

  // Convert Author to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'contact_no': contactNo,
      'photo_url': photoUrl,
      'role': role,
      'books_published': booksPublished,
      'total_views': totalViews,
      'total_downloads': totalDownloads,
      'bio': bio,
      'verification_status': verificationStatus,
      'created_at': createdAt?.toIso8601String(),
      'display_name': displayName,
      'is_active': isActive,
    };
  }

  // Create a copy with updated fields
  Author copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? contactNo,
    String? photoUrl,
    String? role,
    int? booksPublished,
    int? totalViews,
    int? totalDownloads,
    String? bio,
    String? verificationStatus,
    DateTime? createdAt,
    String? displayName,
    bool? isActive,
  }) {
    return Author(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      contactNo: contactNo ?? this.contactNo,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      booksPublished: booksPublished ?? this.booksPublished,
      totalViews: totalViews ?? this.totalViews,
      totalDownloads: totalDownloads ?? this.totalDownloads,
      bio: bio ?? this.bio,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Author(id: $id, displayName: $fullDisplayName, email: $email, isActive: $isActive, verificationStatus: $verificationStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Author && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
