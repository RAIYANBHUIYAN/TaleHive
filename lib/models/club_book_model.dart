class ClubBook {
  final String id;
  final String clubId;
  final String bookId;
  final DateTime addedAt;

  // Book info (joined from books table)
  final String? bookTitle;
  final String? bookCoverUrl;
  final String? bookPdfUrl;
  final String? bookAuthorId;
  final String? bookCategory;
  final double? bookPrice;
  final String? bookSummary;

  ClubBook({
    required this.id,
    required this.clubId,
    required this.bookId,
    required this.addedAt,
    this.bookTitle,
    this.bookCoverUrl,
    this.bookPdfUrl,
    this.bookAuthorId,
    this.bookCategory,
    this.bookPrice,
    this.bookSummary,
  });

  factory ClubBook.fromJson(Map<String, dynamic> json) {
    return ClubBook(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      bookId: json['book_id'] as String,
      addedAt: DateTime.parse(json['added_at']),
      bookTitle: json['book_title'] as String?,
      bookCoverUrl: json['book_cover_url'] as String?,
      bookPdfUrl: json['book_pdf_url'] as String?,
      bookAuthorId: json['book_author_id'] as String?,
      bookCategory: json['book_category'] as String?,
      bookPrice: json['book_price'] != null ? (json['book_price'] as num).toDouble() : null,
      bookSummary: json['book_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'club_id': clubId,
      'book_id': bookId,
      'added_at': addedAt.toIso8601String(),
    };
  }

  ClubBook copyWith({
    String? id,
    String? clubId,
    String? bookId,
    DateTime? addedAt,
    String? bookTitle,
    String? bookCoverUrl,
    String? bookPdfUrl,
    String? bookAuthorId,
    String? bookCategory,
    double? bookPrice,
    String? bookSummary,
  }) {
    return ClubBook(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      bookId: bookId ?? this.bookId,
      addedAt: addedAt ?? this.addedAt,
      bookTitle: bookTitle ?? this.bookTitle,
      bookCoverUrl: bookCoverUrl ?? this.bookCoverUrl,
      bookPdfUrl: bookPdfUrl ?? this.bookPdfUrl,
      bookAuthorId: bookAuthorId ?? this.bookAuthorId,
      bookCategory: bookCategory ?? this.bookCategory,
      bookPrice: bookPrice ?? this.bookPrice,
      bookSummary: bookSummary ?? this.bookSummary,
    );
  }

  @override
  String toString() {
    return 'ClubBook{id: $id, clubId: $clubId, bookId: $bookId, bookTitle: $bookTitle}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClubBook && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
