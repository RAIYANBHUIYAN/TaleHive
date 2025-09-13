enum MembershipType { free, premium }

enum MembershipStatus { active, expired, cancelled, pending }

class ClubMembership {
  final String id;
  final String clubId;
  final String userId;
  final MembershipType membershipType;
  final MembershipStatus status;
  final DateTime joinedAt;
  final DateTime? expiresAt;

  // User info (joined from users table)
  final String? userFirstName;
  final String? userLastName;
  final String? userEmail;
  final String? userPhotoUrl;

  // Club info (joined from clubs table)
  final String? clubName;
  final String? clubCoverUrl;
  final bool? clubIsPremium;

  ClubMembership({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.membershipType,
    required this.status,
    required this.joinedAt,
    this.expiresAt,
    this.userFirstName,
    this.userLastName,
    this.userEmail,
    this.userPhotoUrl,
    this.clubName,
    this.clubCoverUrl,
    this.clubIsPremium,
  });

  factory ClubMembership.fromJson(Map<String, dynamic> json) {
    return ClubMembership(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      userId: json['user_id'] as String,
      membershipType: _membershipTypeFromString(json['membership_type'] as String),
      status: _statusFromString(json['status'] as String),
      joinedAt: DateTime.parse(json['joined_at']),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      userFirstName: json['user_first_name'] as String?,
      userLastName: json['user_last_name'] as String?,
      userEmail: json['user_email'] as String?,
      userPhotoUrl: json['user_photo_url'] as String?,
      clubName: json['club_name'] as String?,
      clubCoverUrl: json['club_cover_url'] as String?,
      clubIsPremium: json['club_is_premium'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'club_id': clubId,
      'user_id': userId,
      'membership_type': _membershipTypeToString(membershipType),
      'status': _statusToString(status),
      'joined_at': joinedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  static MembershipType _membershipTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'premium':
        return MembershipType.premium;
      case 'free':
      default:
        return MembershipType.free;
    }
  }

  static String _membershipTypeToString(MembershipType type) {
    switch (type) {
      case MembershipType.premium:
        return 'premium';
      case MembershipType.free:
        return 'free';
    }
  }

  static MembershipStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'expired':
        return MembershipStatus.expired;
      case 'cancelled':
        return MembershipStatus.cancelled;
      case 'pending':
        return MembershipStatus.pending;
      case 'active':
      default:
        return MembershipStatus.active;
    }
  }

  static String _statusToString(MembershipStatus status) {
    switch (status) {
      case MembershipStatus.expired:
        return 'expired';
      case MembershipStatus.cancelled:
        return 'cancelled';
      case MembershipStatus.pending:
        return 'pending';
      case MembershipStatus.active:
        return 'active';
    }
  }

  String get userFullName {
    if (userFirstName != null && userLastName != null) {
      return '$userFirstName $userLastName';
    }
    return 'Unknown User';
  }

  bool get isActive => status == MembershipStatus.active;
  bool get isPremium => membershipType == MembershipType.premium;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isPending => status == MembershipStatus.pending;

  ClubMembership copyWith({
    String? id,
    String? clubId,
    String? userId,
    MembershipType? membershipType,
    MembershipStatus? status,
    DateTime? joinedAt,
    DateTime? expiresAt,
    String? userFirstName,
    String? userLastName,
    String? userEmail,
    String? userPhotoUrl,
    String? clubName,
    String? clubCoverUrl,
    bool? clubIsPremium,
  }) {
    return ClubMembership(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      userId: userId ?? this.userId,
      membershipType: membershipType ?? this.membershipType,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      userFirstName: userFirstName ?? this.userFirstName,
      userLastName: userLastName ?? this.userLastName,
      userEmail: userEmail ?? this.userEmail,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      clubName: clubName ?? this.clubName,
      clubCoverUrl: clubCoverUrl ?? this.clubCoverUrl,
      clubIsPremium: clubIsPremium ?? this.clubIsPremium,
    );
  }

  @override
  String toString() {
    return 'ClubMembership{id: $id, clubId: $clubId, userId: $userId, type: $membershipType, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClubMembership && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
