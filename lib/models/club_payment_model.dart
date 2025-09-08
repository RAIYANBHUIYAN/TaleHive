enum PaymentStatus { pending, completed, failed, refunded }

enum PaymentMethod { bkash, nagad, rocket, card, bank_transfer }

class ClubPayment {
  final String id;
  final String membershipId;
  final String userId;
  final String clubId;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod paymentMethod;
  final String? transactionId;
  final Map<String, dynamic>? paymentData;
  final DateTime createdAt;
  final DateTime? completedAt;

  // User info (joined from users table)
  final String? userFirstName;
  final String? userLastName;
  final String? userEmail;

  // Club info (joined from clubs table)
  final String? clubName;

  ClubPayment({
    required this.id,
    required this.membershipId,
    required this.userId,
    required this.clubId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.transactionId,
    this.paymentData,
    required this.createdAt,
    this.completedAt,
    this.userFirstName,
    this.userLastName,
    this.userEmail,
    this.clubName,
  });

  factory ClubPayment.fromJson(Map<String, dynamic> json) {
    return ClubPayment(
      id: json['id'] as String,
      membershipId: json['membership_id'] as String,
      userId: json['user_id'] as String,
      clubId: json['club_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: _statusFromString(json['status'] as String),
      paymentMethod: _paymentMethodFromString(json['payment_method'] as String),
      transactionId: json['transaction_id'] as String?,
      paymentData: json['payment_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      userFirstName: json['user_first_name'] as String?,
      userLastName: json['user_last_name'] as String?,
      userEmail: json['user_email'] as String?,
      clubName: json['club_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'membership_id': membershipId,
      'user_id': userId,
      'club_id': clubId,
      'amount': amount,
      'status': _statusToString(status),
      'payment_method': _paymentMethodToString(paymentMethod),
      'transaction_id': transactionId,
      'payment_data': paymentData,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  static PaymentStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  static String _statusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.refunded:
        return 'refunded';
      case PaymentStatus.pending:
        return 'pending';
    }
  }

  static PaymentMethod _paymentMethodFromString(String method) {
    switch (method.toLowerCase()) {
      case 'bkash':
        return PaymentMethod.bkash;
      case 'nagad':
        return PaymentMethod.nagad;
      case 'rocket':
        return PaymentMethod.rocket;
      case 'card':
        return PaymentMethod.card;
      case 'bank_transfer':
        return PaymentMethod.bank_transfer;
      default:
        return PaymentMethod.bkash;
    }
  }

  static String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bkash:
        return 'bkash';
      case PaymentMethod.nagad:
        return 'nagad';
      case PaymentMethod.rocket:
        return 'rocket';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.bank_transfer:
        return 'bank_transfer';
    }
  }

  String get userFullName {
    if (userFirstName != null && userLastName != null) {
      return '$userFirstName $userLastName';
    }
    return 'Unknown User';
  }

  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case PaymentMethod.bkash:
        return 'bKash';
      case PaymentMethod.nagad:
        return 'Nagad';
      case PaymentMethod.rocket:
        return 'Rocket';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bank_transfer:
        return 'Bank Transfer';
    }
  }

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isRefunded => status == PaymentStatus.refunded;

  ClubPayment copyWith({
    String? id,
    String? membershipId,
    String? userId,
    String? clubId,
    double? amount,
    PaymentStatus? status,
    PaymentMethod? paymentMethod,
    String? transactionId,
    Map<String, dynamic>? paymentData,
    DateTime? createdAt,
    DateTime? completedAt,
    String? userFirstName,
    String? userLastName,
    String? userEmail,
    String? clubName,
  }) {
    return ClubPayment(
      id: id ?? this.id,
      membershipId: membershipId ?? this.membershipId,
      userId: userId ?? this.userId,
      clubId: clubId ?? this.clubId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      paymentData: paymentData ?? this.paymentData,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      userFirstName: userFirstName ?? this.userFirstName,
      userLastName: userLastName ?? this.userLastName,
      userEmail: userEmail ?? this.userEmail,
      clubName: clubName ?? this.clubName,
    );
  }

  @override
  String toString() {
    return 'ClubPayment{id: $id, amount: $amount, status: $status, method: $paymentMethod}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClubPayment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
