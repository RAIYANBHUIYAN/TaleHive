class AuthorEarnings {
  final String authorId;
  final double totalEarnings;
  final double monthlyEarnings;
  final int totalMembers;
  final int premiumMembers;
  final int activeClubs;
  final Map<String, double> earningsByClub;
  final Map<String, int> membersByClub;
  final List<EarningsTransaction> recentTransactions;

  AuthorEarnings({
    required this.authorId,
    required this.totalEarnings,
    required this.monthlyEarnings,
    required this.totalMembers,
    required this.premiumMembers,
    required this.activeClubs,
    required this.earningsByClub,
    required this.membersByClub,
    required this.recentTransactions,
  });

  factory AuthorEarnings.fromJson(Map<String, dynamic> json) {
    return AuthorEarnings(
      authorId: json['author_id'] as String,
      totalEarnings: (json['total_earnings'] as num).toDouble(),
      monthlyEarnings: (json['monthly_earnings'] as num).toDouble(),
      totalMembers: json['total_members'] as int,
      premiumMembers: json['premium_members'] as int,
      activeClubs: json['active_clubs'] as int,
      earningsByClub: Map<String, double>.from(json['earnings_by_club'] ?? {}),
      membersByClub: Map<String, int>.from(json['members_by_club'] ?? {}),
      recentTransactions: (json['recent_transactions'] as List<dynamic>?)
              ?.map((e) => EarningsTransaction.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author_id': authorId,
      'total_earnings': totalEarnings,
      'monthly_earnings': monthlyEarnings,
      'total_members': totalMembers,
      'premium_members': premiumMembers,
      'active_clubs': activeClubs,
      'earnings_by_club': earningsByClub,
      'members_by_club': membersByClub,
      'recent_transactions': recentTransactions.map((e) => e.toJson()).toList(),
    };
  }

  double get averageEarningsPerClub {
    return activeClubs > 0 ? totalEarnings / activeClubs : 0.0;
  }

  double get averageEarningsPerMember {
    return totalMembers > 0 ? totalEarnings / totalMembers : 0.0;
  }
}

class EarningsTransaction {
  final String id;
  final String clubId;
  final String clubName;
  final String userId;
  final String userName;
  final double amount;
  final DateTime date;
  final String type; // 'membership', 'renewal', etc.

  EarningsTransaction({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.date,
    required this.type,
  });

  factory EarningsTransaction.fromJson(Map<String, dynamic> json) {
    return EarningsTransaction(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      clubName: json['club_name'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'club_id': clubId,
      'club_name': clubName,
      'user_id': userId,
      'user_name': userName,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
    };
  }
}
