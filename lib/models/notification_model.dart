class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    print('🔄 Parsing notification from JSON: $json');
    try {
      final notification = AppNotification(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        type: json['type'],
        title: json['title'],
        body: json['body'],
        data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at']),
      );
      print('✅ Successfully parsed notification: ${notification.title}');
      return notification;
    } catch (e) {
      print('❌ Error parsing notification JSON: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
