import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pdf_preview/pdf_viewer_page.dart';
import '../pdf_preview/pdf_service.dart';
import 'ai_chat_page.dart'; // Add AI chat page import
// Helper to fetch related books for BookDetails


Future<List<BookRecommendation>> fetchRelatedBooks(String bookId, String? category) async {
  try {
    if (category == null || category.isEmpty) {
      return [];
    }

    final response = await supabase
        .from('books')
        .select('id, title, cover_image_url, author_id, authors!inner(display_name)')
            .eq('category', category)
        .neq('id', bookId) // Exclude current book
        .eq('is_active', true)
        .limit(10);

    // Process each book to add author information and calculate ratings
    final List<BookRecommendation> relatedBooks = [];
    
    for (final bookData in response) {
      // Get author name from the joined authors table
      String authorName = 'Unknown Author';
      if (bookData['authors'] != null) {
        authorName = bookData['authors']['display_name'] ?? 'Unknown Author';
      }

      // Calculate average rating from reviews
      double avgRating = 0.0;
      int reviewCount = 0;
      try {
        final reviewsResponse = await supabase
            .from('reviews')
            .select('rating')
            .eq('book_id', bookData['id']);
        
        if (reviewsResponse.isNotEmpty) {
          final ratings = reviewsResponse.map((r) => r['rating'] as int).toList();
          avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
          reviewCount = ratings.length;
        }
      } catch (e) {
        print('Error fetching ratings for book ${bookData['id']}: $e');
      }

      relatedBooks.add(BookRecommendation(
        id: bookData['id'].toString(),
        title: bookData['title'] ?? 'Unknown Title',
        author: authorName,
        cover: bookData['cover_image_url'] ?? '',
        rating: avgRating,
        reviews: reviewCount,
      ));
    }

    return relatedBooks;
  } catch (e) {
    print('Error fetching related books: $e');
    return [];
  }
}

// Helper to fetch premium club books for premium book details
Future<List<BookRecommendation>> fetchPremiumClubBooks(String bookId, String? category) async {
  try {
    if (category == null || category.isEmpty) {
      return [];
    }

    // Query club_books table joined with books to get only premium club books
    final response = await supabase
        .from('club_books')
        .select('''
          book_id,
          books!club_books_book_id_fkey(id, title, cover_image_url, category, author_id, authors!inner(display_name)),
          clubs!club_books_club_id_fkey(is_premium)
        ''')
        .eq('books.category', category)
        .neq('book_id', bookId) // Exclude current book
        .eq('books.is_active', true)
        .eq('clubs.is_premium', true) // Only premium clubs
        .limit(10);

    // Extract unique books and process them to add author information and ratings
    final Map<String, BookRecommendation> uniqueBooks = {};
    
    for (var item in response) {
      final book = item['books'];
      if (book != null && book['id'] != null) {
        final bookIdStr = book['id'].toString();
        if (!uniqueBooks.containsKey(bookIdStr)) {
          
          // Get author name from the joined authors table
          String authorName = 'Unknown Author';
          if (book['authors'] != null) {
            authorName = book['authors']['display_name'] ?? 'Unknown Author';
          }

          // Calculate average rating from reviews
          double avgRating = 0.0;
          int reviewCount = 0;
          try {
            final reviewsResponse = await supabase
                .from('reviews')
                .select('rating')
                .eq('book_id', book['id']);
            
            if (reviewsResponse.isNotEmpty) {
              final ratings = reviewsResponse.map((r) => r['rating'] as int).toList();
              avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
              reviewCount = ratings.length;
            }
          } catch (e) {
            print('Error fetching ratings for premium book ${book['id']}: $e');
          }

          uniqueBooks[bookIdStr] = BookRecommendation(
            id: bookIdStr,
            title: book['title'] ?? 'Unknown Title',
            author: authorName,
            cover: book['cover_image_url'] ?? '',
            rating: avgRating,
            reviews: reviewCount,
          );
        }
      }
    }
    
    return uniqueBooks.values.toList();
  } catch (e) {
    print('Error fetching premium club books: $e');
    return [];
  }
}
// --- DownloadProgressDialog Widget ---
class DownloadProgressDialog extends StatefulWidget {
  final String pdfUrl;
  final String fileName;

  const DownloadProgressDialog({
    Key? key,
    required this.pdfUrl,
    required this.fileName,
  }) : super(key: key);

  @override
  _DownloadProgressDialogState createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double progress = 0.0;
  bool isCompleted = false;
  bool hasError = false;
  String? errorMessage;
  String? filePath;
  int downloadedBytes = 0;
  int totalBytes = 0;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      setState(() {
        hasError = false;
        isCompleted = false;
        progress = 0.0;
      });

      print('Starting download: ${widget.pdfUrl}');

      // Replace with your actual PDFService implementation
      final downloadedPath = await PDFService.downloadPDF(
        url: widget.pdfUrl,
        fileName: widget.fileName,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              downloadedBytes = received;
              totalBytes = total;
              progress = total > 0 ? received / total : 0.0;
            });
            print('Download progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );

      if (downloadedPath != null && mounted) {
        setState(() {
          isCompleted = true;
          filePath = downloadedPath;
        });
        print('Download completed: $downloadedPath');
      } else {
        setState(() {
          hasError = true;
          errorMessage = 'Download failed - file not created';
        });
      }
    } catch (e) {
      print('Download error: $e');
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = e.toString();
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    int i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        hasError ? 'Download Failed' : isCompleted ? 'Download Complete' : 'Downloading PDF',
        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCompleted && !hasError) ...[
            CircularProgressIndicator(
              value: progress,
              color: const Color(0xFF0096C7),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0096C7),
              ),
            ),
            const SizedBox(height: 8),
            if (totalBytes > 0)
              Text(
                '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Downloading "${widget.fileName}.pdf"',
              style: GoogleFonts.montserrat(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ] else if (isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'PDF downloaded successfully!',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'File saved to app documents',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (filePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Path: $filePath',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ] else if (hasError) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Download Failed',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error occurred',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        if (isCompleted) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.montserrat(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File saved to: $filePath'),
                  backgroundColor: const Color(0xFF0096C7),
                  duration: const Duration(seconds: 5),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0096C7),
            ),
            child: Text(
              'Show Location',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          ),
        ] else if (hasError) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.montserrat(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0096C7),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: Colors.grey[600]),
            ),
          ),
        ],
      ],
    );
  }
}

// Review Model for the new reviews table
class ReviewModel {
  final String id;
  final String bookId;
  final String userId;
  final int rating;
  final String reviewText;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      bookId: json['book_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      reviewText: json['review']?.toString() ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'user_id': userId,
      'rating': rating,
      'review': reviewText,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
// --- Data Models ---
class BookDetails {
  final String id; // <-- Add id field
  final String title;
  final String author;
  final String cover;
  final double averageRating;
  final int reviewsCount;
  final String description;
  final List<String> genres;
  final String summary;
  final String language;
  final String category;
  final String accessType;
  final int price;
  final DateTime created_at;
  final List<String> formats;
  final List<Edition> editions;
  final int currentlyReading;
  final int wantToRead;
  final Author authorDetails;
  final List<Review> review;
  final List<BookRecommendation> alsoEnjoyed;
  final List<ReviewBreakdown> reviewBreakdown;
  

  BookDetails({
    required this.id, // <-- Add id to constructor
    required this.title,
    required this.author,
    required this.cover,
  required this.averageRating,
  required this.reviewsCount,
    required this.description,
    required this.genres,
    required this.summary,
    required this.language,
    required this.category,
  required this.accessType,
    required this.created_at,
    required this.price,
    required this.formats,
    required this.editions,
    required this.currentlyReading,
    required this.wantToRead,
    required this.authorDetails,
    required this.review,
    required this.alsoEnjoyed,
    required this.reviewBreakdown,
  });

  factory BookDetails.fromJson(Map<String, dynamic> json) {
    return BookDetails(
      id: json['id'].toString(),
      title: json['title'],
      author: json['author'],
      cover: json['cover'],
      averageRating: 0.0, // Will be calculated from reviews table
      reviewsCount: 0, // Will be calculated from reviews table
      description: json['description'],
      genres: List<String>.from(json['genres'] ?? []),
      summary: json['summary'] ?? 'No summary available.',
      language: json['language'] ?? 'English',
      category: json['category'] ?? 'General',
  accessType: json['access_type'] ?? json['access'] ?? 'free',
      created_at: DateTime.parse(json['created_at']),
      price: json['price'] ?? 0,
      formats: List<String>.from(json['formats'] ?? []),
      editions: (json['editions'] as List? ?? []).map((e) => Edition.fromJson(e)).toList(),
      currentlyReading: json['currentlyReading'],
      wantToRead: json['wantToRead'],
      authorDetails: Author.fromJson(json['authorDetails']),
      review: [], // Empty, will be populated from reviews table
      alsoEnjoyed: (json['alsoEnjoyed'] as List? ?? []).map((e) => BookRecommendation.fromJson(e)).toList(),
      reviewBreakdown: [], // Empty, will be calculated from reviews table
    );
  }

  BookDetails copyWith({
    List<BookRecommendation>? alsoEnjoyed,
  }) {
    return BookDetails(
      id: this.id,
      title: this.title,
      author: this.author,
      cover: this.cover,
      averageRating: this.averageRating,
      reviewsCount: this.reviewsCount,
      description: this.description,
      genres: this.genres,
      summary: this.summary,
      language: this.language,
      category: this.category,
  accessType: this.accessType,
      created_at: this.created_at,
      price: this.price,
      formats: this.formats,
      editions: this.editions,
      currentlyReading: this.currentlyReading,
      wantToRead: this.wantToRead,
      authorDetails: this.authorDetails,
      review: this.review,
      alsoEnjoyed: alsoEnjoyed ?? this.alsoEnjoyed,
      reviewBreakdown: this.reviewBreakdown,
    );
  }
}

class Edition {
  final String cover;
  final String type;
  final String year;
  Edition({required this.cover, required this.type, required this.year});
  factory Edition.fromJson(Map<String, dynamic> json) => Edition(
    cover: json['cover'],
    type: json['type'],
    year: json['year'],
  );
}

class Author {
  final String name;
  final String photo;
  final String bio;
  final int books;
  final int followers;
  Author({required this.name, required this.photo, required this.bio, required this.books, required this.followers});
  factory Author.fromJson(Map<String, dynamic> json) => Author(
    name: json['name'],
    photo: json['photo'],
    bio: json['bio'],
    books: json['books'],
    followers: json['followers'],
  );
}

class Review {
  final String user;
  final String photo;
  final String date;
  final String text;
  final int likes;
  final int rating;
  Review({required this.user, required this.photo, required this.date, required this.text, required this.likes, required this.rating});
  factory Review.fromJson(Map<String, dynamic> json) => Review(
    user: json['user'],
    photo: json['photo'],
    date: json['date'],
    text: json['text'],
    likes: json['likes'],
    rating: json['rating'],
  );
}

class BookRecommendation {
  final String id;
  final String title;
  final String author;
  final String cover;
  final double rating;
  final int reviews;
  BookRecommendation({
    required this.id,
    required this.title,
    required this.author,
    required this.cover,
    required this.rating,
    required this.reviews,
  });
  factory BookRecommendation.fromJson(Map<String, dynamic> json) => BookRecommendation(
    id: json['id'].toString(),
    title: json['title'] ?? 'Unknown Title',
    author: json['author_name'] ?? 'Unknown Author',
    cover: json['cover_image_url'] ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    reviews: json['review'] ?? 0,
  );
}

class ReviewBreakdown {
  final int stars;
  final int count;
  ReviewBreakdown({required this.stars, required this.count});
  factory ReviewBreakdown.fromJson(Map<String, dynamic> json) => ReviewBreakdown(
    stars: json['stars'],
    count: json['count'],
  );
}

// --- API Service ---


final supabase = Supabase.instance.client;

Future<BookDetails> fetchBookDetails(String bookId, {bool isFromPremiumClub = false}) async {
  try {
    if (bookId.isEmpty) {
      throw Exception('No bookId provided.');
    }

    // Fetch book data from Supabase
    final response = await supabase
        .from('books')
        .select('*')
        .eq('id', bookId)
        .eq('is_active', true)
        .single();

    // Fetch author data using author_id from books table
    var authorName = 'Unknown Author';
    var authorBio = 'Author biography not available.';
    var authorPhoto = 'https://randomuser.me/api/portraits/men/32.jpg';
    var authorBooks = 0;
    var authorFollowers = 0;
    try {
      final authorId = response['author_id'];
      if (authorId != null) {
        // Fetch author info
        final authorResponse = await supabase
            .from('authors')
            .select('id, first_name, last_name, display_name, bio, photo_url')
            .eq('id', authorId)
            .single();
        if (authorResponse != null) {
          // Use display_name if available, otherwise combine first_name and last_name
          if (authorResponse['display_name'] != null && authorResponse['display_name'].isNotEmpty) {
            authorName = authorResponse['display_name'];
          } else {
            final firstName = authorResponse['first_name'] ?? '';
            final lastName = authorResponse['last_name'] ?? '';
            authorName = (firstName + ' ' + lastName).trim();
            if (authorName.isEmpty) authorName = 'Unknown Author';
          }
          authorBio = authorResponse['bio'] ?? authorBio;
          authorPhoto = authorResponse['photo_url'] ?? authorPhoto;
        }
        // Count number of books for this author
        final booksCountResponse = await supabase
            .from('books')
            .select('id')
            .eq('author_id', authorId)
            .eq('is_active', true);
        if (booksCountResponse is List) {
          authorBooks = booksCountResponse.length;
        }
      }
    } catch (e) {
      print('Error fetching author info or books count: $e');
    }

    // Fetch reviews from the new reviews table with user information
    final reviewsResponse = await supabase
        .from('reviews')
        .select('*, users!fk_user(*)')
        .eq('book_id', bookId);

    // Convert reviews to Review objects
    final reviewList = (reviewsResponse as List).map((reviewData) {
      final userData = reviewData['users'];
      final userName = userData != null && userData is Map 
          ? ((userData['first_name'] ?? '') + ' ' + (userData['last_name'] ?? '')).trim().isEmpty
              ? 'Reader'
              : ((userData['first_name'] ?? '') + ' ' + (userData['last_name'] ?? '')).trim()
          : 'Reader';
      final userPhoto = userData != null && userData is Map && userData['photo_url'] != null
          ? userData['photo_url']
          : 'https://randomuser.me/api/portraits/women/30.jpg';
      return Review(
        user: userName,
        photo: userPhoto,
        date: reviewData['created_at'] != null 
            ? DateFormat('yyyy-MM-dd').format(DateTime.parse(reviewData['created_at']))
            : 'Recent',
        text: reviewData['review']?.toString() ?? '',
        likes: 0,
        rating: (reviewData['rating'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    // Calculate average rating
    final ratings = reviewList.where((r) => r.rating > 0).map((r) => r.rating).toList();
    final averageRating = ratings.isNotEmpty ? ratings.reduce((a, b) => a + b) / ratings.length : 0.0;

    // Calculate review breakdown
    final reviewBreakdown = List.generate(5, (index) {
      final star = 5 - index;
      final count = reviewList.where((r) => r.rating == star).length;
      return ReviewBreakdown(stars: star, count: count);
    });

    // Convert Supabase data to BookDetails
    final bookDetails = BookDetails(
      id: bookId,
      title: response['title'] ?? 'Unknown Title',
      author: authorName,
      cover: response['cover_image_url'] ?? 'https://via.placeholder.com/180x240',
      averageRating: averageRating,
      reviewsCount: reviewList.length,
      description: response['description'] ?? 'No description available.',
      genres: response['genre'] != null ? [response['genre']] : ['General'],
      summary: response['summary'] ?? 'No summary available.',
      language: response['language'] ?? 'English',
      category: response['category'] ?? 'General',
      created_at: DateTime.parse(response['created_at']),
      price: (response['price'] as num?)?.toInt() ?? 0,
      formats: ['eBook', 'PDF'],
      editions: [
        Edition(
          cover: response['cover_image_url'] ?? '',
          type: 'Digital',
          year: response['publication_date']?.substring(0, 4) ?? '2024',
        ),
      ],
      currentlyReading: response['currentlyReading'] ?? 0,
      wantToRead: response['wantToRead'] ?? 0,
      authorDetails: Author(
        name: authorName,
        photo: authorPhoto,
        bio: authorBio,
        books: authorBooks,
        followers: authorFollowers,
      ),
      review: reviewList,
      alsoEnjoyed: [],
      reviewBreakdown: reviewBreakdown,
  accessType: response['access_type'] ?? response['access'] ?? 'free',
    );

    // Fetch related books - use premium club books if this is a premium club book
    List<BookRecommendation> relatedBooks;
    
    if (isFromPremiumClub) {
      // For premium club books, show only other premium club books
      relatedBooks = await fetchPremiumClubBooks(bookId, response['category']);
      print('Fetched ${relatedBooks.length} premium club books for premium book');
    } else {
      // For regular books, show regular related books
      relatedBooks = await fetchRelatedBooks(bookId, response['category']);
      print('Fetched ${relatedBooks.length} regular related books');
    }

    print('Current book category: ${response['category']}');
    print('Related books found: ${relatedBooks.length}');
    for (var b in relatedBooks) {
      print('Related book: ${b.title} (${b.id}) - category: ${response['category']}');
    }

    // Return book with related books
    return bookDetails.copyWith(alsoEnjoyed: relatedBooks);

  } catch (e) {
    print('Error fetching book details: $e');
    
    // Return a fallback with the bookId for debugging
    return BookDetails(
      id: bookId,
      title: 'Book Not Found',
      author: 'Unknown Author',
      cover: 'https://via.placeholder.com/180x240',
      averageRating: 0.0,
      reviewsCount: 0,
      description: 'Could not load book details. Book ID: $bookId',
      genres: ['Unknown'],
      summary: 'No summary available.',
      language: 'Unknown',
      category: 'General',
      created_at: DateTime.now(),
      price: 0,
      formats: [],
      editions: [],
      currentlyReading: 0,
      wantToRead: 0,
      authorDetails: Author(
        name: 'Unknown Author',
        photo: 'https://via.placeholder.com/64x64',
        bio: 'No information available.',
        books: 0,
        followers: 0,
      ),
      review: [],
      alsoEnjoyed: [],
      reviewBreakdown: [],
  accessType: 'free',
    );
  }
}

class BookDetailsPage extends StatefulWidget {
  final String bookId;
  final VoidCallback? onFavoriteChanged; // Add this callback
  final bool? isFromPremiumClub; // New parameter to identify premium club books
  final String? clubId; // Club ID for context
  final String? bookTitle; // Book title for AI context
  final String? authorName; // Author name for AI context
  final String? bookCategory; // Book category for AI context
  
  const BookDetailsPage({
    Key? key, 
    required this.bookId,
    this.onFavoriteChanged,
    this.isFromPremiumClub = false,
    this.clubId,
    this.bookTitle,
    this.authorName,
    this.bookCategory,
  }) : super(key: key);

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  
  // Add refresh key for FutureBuilder
  Key _futureBuilderKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ✅ Check if the book is in the user's favorites
  Future<void> _checkFavoriteStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('users')
          .select('Favourites')
          .eq('id', user.id)
          .single();

      final favorites = response['Favourites'];
      Set<String> favoriteIds = {};
      
      if (favorites != null && favorites.isNotEmpty) {
        if (favorites is String) {
          favoriteIds = favorites.split(',').where((id) => id.isNotEmpty).toSet();
        } else if (favorites is List) {
          favoriteIds = favorites.map((id) => id.toString()).toSet();
        }
      }

      setState(() {
        _isFavorite = favoriteIds.contains(widget.bookId);
      });
    } catch (e) {
      print('Error fetching favorite status: $e');
    }
  }

  // ✅ Toggle favorite status
  Future<void> _toggleFavorite() async {
    setState(() => _isLoadingFavorite = true);
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showSnackBar('Please login to add favorites', backgroundColor: Colors.orange);
        return;
      }

      // Get current favorites
      final userResponse = await supabase
          .from('users')
          .select('Favourites')
          .eq('id', user.id)
          .single();

      final favorites = userResponse['Favourites'];
      Set<String> favoriteIds = {};
      
      if (favorites != null && favorites.isNotEmpty) {
        if (favorites is String) {
          favoriteIds = favorites.split(',').where((id) => id.isNotEmpty).toSet();
        } else if (favorites is List) {
          favoriteIds = favorites.map((id) => id.toString()).toSet();
        }
      }

      // Toggle favorite
      if (_isFavorite) {
        favoriteIds.remove(widget.bookId);
        _showSnackBar('Removed from favorites', backgroundColor: Colors.orange);
      } else {
        favoriteIds.add(widget.bookId);
        _showSnackBar('Added to favorites', backgroundColor: Colors.green);
      }

      // Update database
      final favoritesString = favoriteIds.join(',');
      await supabase.from('users')
          .update({'Favourites': favoritesString})
          .eq('id', user.id);

      setState(() {
        _isFavorite = !_isFavorite;
      });

      // ✅ Notify parent about the change
      if (widget.onFavoriteChanged != null) {
        widget.onFavoriteChanged!();
      }

    } catch (e) {
      print('Error toggling favorite: $e');
      _showSnackBar('Failed to update favorites', backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoadingFavorite = false);
    }
  }

  // ✅ Add refresh functionality
  Future<void> _refreshBookDetails() async {
    try {
      setState(() {
        _futureBuilderKey = UniqueKey(); // This will trigger FutureBuilder to rebuild
      });
      
      // Also refresh favorite status
      await _checkFavoriteStatus();
      
      // Optional: Show a subtle feedback
   
    } catch (e) {
      
    }
  }

  // ✅ Add the missing _showSnackBar method
  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat()),
        backgroundColor: backgroundColor ?? const Color(0xFF0096C7),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ Add the missing build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22223b)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Book Details',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF22223b),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          // ✅ Add favorite button to app bar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _isLoadingFavorite
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0096C7),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : const Color(0xFF22223b),
                      size: 28,
                    ),
                    onPressed: _toggleFavorite,
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshBookDetails,
          color: const Color(0xFF0096C7),
          backgroundColor: Colors.white,
          child: FutureBuilder<BookDetails>(
            key: _futureBuilderKey,
            future: fetchBookDetails(widget.bookId, isFromPremiumClub: widget.isFromPremiumClub ?? false),
            builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0096C7)),
                    SizedBox(height: 16),
                    Text('Loading book details...'),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No book data found'));
            }
            
            final book = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              children: [
                // Book Main Info Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Flex(
                          direction: isWide ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BookCoverActions(
                              book: book,
                              bookId: widget.bookId,
                              isFavorite: _isFavorite, // ✅ Pass favorite status
                              onFavoriteToggle: _toggleFavorite, // ✅ Pass toggle function
                              isLoadingFavorite: _isLoadingFavorite, // ✅ Pass loading state
                            ),
                            const SizedBox(width: 32, height: 32),
                            if (isWide)
                              SizedBox(
                                width: 400,
                                child: _BookInfoSection(book: book),
                              )
                            else
                              _BookInfoSection(book: book),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 18),
//                 Card(
//                   elevation: 2,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
// color: Colors.white,
//                   // child: Padding(
//                   //   padding: const EdgeInsets.all(16),
//                   //   child: _BookEditionsSection(book: book),
//                   // ),
//                 ),
//                 const SizedBox(height: 18),
                _BookStatsSection(currentlyReading: book.currentlyReading, bookId: widget.bookId),
                const SizedBox(height: 18),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: _AboutAuthorSection(author: book.authorDetails),
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: _RatingReviewsSection(
                      book: book,
                      reviewBreakdown: book.reviewBreakdown,
                      reviews: book.review,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionHeader(
                  title: 'Readers also Enjoyed',
                  icon: Icons.recommend,
                ),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: Colors.white,
                  child: Container(
                    height: 280,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: book.alsoEnjoyed.isEmpty
                        ? _buildEmptyRelatedBooks()
                        : _AlsoEnjoyedSection(books: book.alsoEnjoyed),
                  ),
                ),
                const SizedBox(height: 28),
                _Footer(),
                const SizedBox(height: 18),
              ],
            );
          },
        ), // This closes the FutureBuilder
      ), // This closes the RefreshIndicator
      ), // This closes the SafeArea
      floatingActionButton: widget.isFromPremiumClub == true 
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => AIChatPage(
                      bookTitle: widget.bookTitle ?? 'Unknown Title',
                      clubId: widget.clubId ?? '',
                      category: widget.bookCategory,
                    ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end).chain(
                        CurveTween(curve: curve),
                      );

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
              backgroundColor: const Color(0xFF0077B6),
              icon: const Icon(Icons.smart_toy, color: Colors.white),
              label: Text(
                'Ask AI',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyRelatedBooks() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No related books found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try exploring other genres',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Components ---



class _BookCoverActions extends StatelessWidget {
  final BookDetails book;
  final String bookId;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final bool isLoadingFavorite;
  
  const _BookCoverActions({
    required this.book,
    required this.bookId,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.isLoadingFavorite,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ✅ Clean book cover without love icon
        Container(
          width: 180,
          height: 240,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0096C7).withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Hero(
              tag: 'book_cover_${book.cover}',
              child: Image.network(
                book.cover,
                width: 180,
                height: 240,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 180,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.book, size: 40, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Abstract Button (always shown)
            _ActionChipButton(
              icon: Icons.summarize,
              label: 'Abstract',
              color: const Color(0xFFB5179E),
              minWidth: 140,
              onPressed: () => _showAbstract(context),
            ),

            // Free access: show Read, Download
            if (book.accessType.toLowerCase() == 'free') ...[
              _ActionChipButton(
          icon: Icons.menu_book,
          label: 'Read',
          color: const Color(0xFF0096C7),
          minWidth: 140,
          onPressed: () => _handleReadBook(context),
              ),
              Center(
                child: _ActionChipButton(
                          icon: Icons.picture_as_pdf,
                          label: 'Download PDF',
                          color: const Color(0xFF43AA8B),
                          minWidth: 140,
                          onPressed: () => _handleDownloadPDF(context),
                ),
              ),
            ]
            // Borrow access: show Borrow or Read based on borrow status
          else if (book.accessType.toLowerCase() == 'borrow') ...[
            FutureBuilder<Map<String, dynamic>?>(
              future: supabase.auth.currentUser?.id != null
                ? supabase
                    .from('borrow_requests')
                    .select()
                    .eq('book_id', bookId)
                    .eq('user_id', supabase.auth.currentUser!.id)
                    .eq('status', 'accepted')
                    .order('end_date', ascending: false)
                    .limit(1)
                    .maybeSingle()
                : Future.value(null),
              builder: (context, snapshot) {
                final borrow = snapshot.data;
                final now = DateTime.now();
                final endDate = borrow != null && borrow['end_date'] != null
                    ? DateTime.tryParse(borrow['end_date'])
                    : null;
                final startDate = borrow != null && borrow['start_date'] != null
                    ? DateTime.tryParse(borrow['start_date'])
                    : null;
                if (borrow != null &&
                    endDate != null &&
                    startDate != null &&
                    now.isAfter(startDate) &&
                    now.isBefore(endDate)) {
                  // Show Read button only if accepted and within borrow period
                  return _ActionChipButton(
                    icon: Icons.menu_book,
                    label: 'Read',
                    color: const Color(0xFF0096C7),
                    minWidth: 140,
                    onPressed: () => _handleReadBook(context),
                  );
                } else {
                  // Not borrowed or expired, show Borrow button
                  return _ActionChipButton(
                    icon: Icons.shopping_cart,
                    label: 'Borrow',
                    color: const Color(0xFFF3722C),
                    minWidth: 140,
                    onPressed: () {
                      _showBorrowDialog(context, bookId, book.title, book.author);
                    },
                  );
                }
              },
            ),
          ],
          ],
        ),
        const SizedBox(height: 10),
      //   ElevatedButton(
      //     onPressed: () {},
      //     style: ElevatedButton.styleFrom(
      //       backgroundColor: Colors.white,
      //       foregroundColor: const Color(0xFF0096C7),
      //       shape: RoundedRectangleBorder(
      //         borderRadius: BorderRadius.circular(8),
      //       ),
      //       side: const BorderSide(color: Color(0xFF0096C7)),
      //       padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      //     ),
      //  //   child: const Text('Book Status'),
      //   ),
      ],
    );
  }

  // Handle Read Book functionality
  void _handleReadBook(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0096C7)),
              const SizedBox(height: 16),
              Text('Loading PDF...', style: GoogleFonts.montserrat()),
            ],
          ),
        ),
      );

      final bookId = (context.findAncestorWidgetOfExactType<BookDetailsPage>())?.bookId;
      
      if (bookId == null) {
        Navigator.pop(context);
        _showErrorDialog(context, 'Book ID not available');
        return;
      }

      // Increment currently_reading using Supabase RPC (atomic)
      await supabase.rpc(
        'increment_currently_reading',
        params: {'book_id': bookId},
      );

      final pdfUrl = await PDFService.getPDFUrl(bookId);
      
      Navigator.pop(context);

      if (pdfUrl != null && pdfUrl.isNotEmpty) {
        // Open PDF and decrement currently_reading when closed
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerPage(
              pdfUrl: pdfUrl,
              bookTitle: book.title,
              bookId: bookId,
            ),
          ),
        );
        // Decrement currently_reading using Supabase RPC (atomic)
        await supabase.rpc(
          'decrement_currently_reading',
          params: {'book_id': bookId},
        );
      } else {
        _showErrorDialog(context, 'PDF not available for this book');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog(context, 'Failed to open PDF: ${e.toString()}');
    }
  }

  // Handle Download PDF functionality
  void _handleDownloadPDF(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0096C7)),
              const SizedBox(height: 16),
              Text('Preparing download...', style: GoogleFonts.montserrat()),
            ],
          ),
        ),
      );

      final bookId = (context.findAncestorWidgetOfExactType<BookDetailsPage>())?.bookId;
      
      if (bookId == null) {
        Navigator.pop(context);
        _showErrorDialog(context, 'Book ID not available');
        return;
      }

      final pdfUrl = await PDFService.getPDFUrl(bookId);
      
      if (pdfUrl == null || pdfUrl.isEmpty) {
        Navigator.pop(context);
        _showErrorDialog(context, 'PDF not available for this book');
        return;
      }

      Navigator.pop(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DownloadProgressDialog(
          pdfUrl: pdfUrl,
          fileName: book.title.replaceAll(RegExp(r'[^\w\s-]'), ''),
        ),
      );

    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog(context, 'Failed to download PDF: ${e.toString()}');
    }
  }

  // Show Abstract
  void _showAbstract(BuildContext context) {
    // Check if description contains a PDF URL (abstract PDF)
    final description = book.description;
    final bool isAbstractPDF = description != null && 
        description.isNotEmpty && 
        description.contains('book-pdfs') && 
        description.contains('.pdf');

    if (isAbstractPDF) {
      // Show abstract PDF options
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Abstract - ${book.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: Colors.red[700],
              ),
              const SizedBox(height: 16),
              Text(
                'This book has an abstract PDF available.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose an option below:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openAbstractPDF(context, description);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0096C7),
                foregroundColor: Colors.white,
              ),
              child: const Text('Read Abstract'),
            ),
          ],
        ),
      );
    } else {
      // Show regular description
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Description - ${book.title}'),
          content: SingleChildScrollView(
            child: Text(
              description?.isNotEmpty == true ? description! : 'No description available.',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  // Open Abstract PDF
  void _openAbstractPDF(BuildContext context, String abstractUrl) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0096C7)),
              const SizedBox(height: 16),
              Text('Opening abstract...', style: GoogleFonts.montserrat()),
            ],
          ),
        ),
      );

      // Navigate to PDF viewer with abstract URL
      Navigator.pop(context); // Close loading dialog
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerPage(
            pdfUrl: abstractUrl,
            bookTitle: '${book.title} - Abstract',
            bookId: book.id,
          ),
        ),
      );

    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog(context, 'Failed to open abstract: ${e.toString()}');
    }
  }

  // Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double minWidth;
  final VoidCallback? onPressed;
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.color,
    this.minWidth = 120,
    this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: minWidth,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 2,
          shadowColor: color.withOpacity(0.15),
        ),
        onPressed: onPressed ?? () {},
      ),
    );
  }
}

Future<bool> _hasActiveBorrow(BuildContext context, String bookId) async {
  final user = supabase.auth.currentUser;
  if (user == null) return false;
  final now = DateTime.now().toIso8601String();
  final response = await supabase
      .from('borrow_requests')
      .select()
      .eq('book_id', bookId)
      .eq('user_id', user.id)
      .eq('status', 'accepted')
      .lte('start_date', now)
      .gte('end_date', now)
      .maybeSingle();
  return response != null;
}

void _showBorrowDialog(BuildContext context, String bookId, String bookTitle, String authorName) {
  showDialog(
    context: context,
    builder: (context) {
      DateTime startDate = DateTime.now();
      DateTime endDate = startDate.add(Duration(days: 7));
      final reasonController = TextEditingController();
      bool isSubmitting = false;
      
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Borrow Request', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Book: $bookTitle', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                  Text('Author: $authorName', style: GoogleFonts.montserrat(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  
                  // Reason field
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: 'Reason for borrowing',
                      hintText: 'Why do you want to borrow this book?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Collection Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Collection Date', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(startDate)),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked;
                          // Auto-set return date to 7 days after collection
                          endDate = startDate.add(Duration(days: 7));
                        });
                      }
                    },
                  ),
                  
                  // Return Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Return Date', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(endDate)),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: startDate.add(Duration(days: 1)),
                        lastDate: startDate.add(Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() {
                          endDate = picked;
                        });
                      }
                    },
                  ),
                  
                  if (isSubmitting) 
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please provide a reason for borrowing')),
                    );
                    return;
                  }
                  
                  setState(() => isSubmitting = true);
                  
                  final success = await _submitBorrowRequest(
                    context: context,
                    bookId: bookId,
                    reason: reasonController.text.trim(),
                    startDate: startDate,
                    endDate: endDate,
                  );
                  
                  setState(() => isSubmitting = false);
                  
                  if (success) {
                    Navigator.pop(context);
                    _showBorrowSuccessDialog(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0096C7),
                ),
                child: Text('Submit Request', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  );
}

// Submit borrow request to database
Future<bool> _submitBorrowRequest({
  required BuildContext context,
  required String bookId,
  required String reason,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login to submit a borrow request')),
      );
      return false;
    }

    // Check if user already has an active or pending request for this book
    final existingRequest = await supabase
        .from('borrow_requests')
        .select()
        .eq('book_id', bookId)
        .eq('user_id', user.id)
        .or('status.eq.pending,status.eq.accepted')
        .maybeSingle();

    if (existingRequest != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You already have a pending or active request for this book')),
      );
      return false;
    }

    // Insert the borrow request with 'pending' status
    final response = await supabase.from('borrow_requests').insert({
      'book_id': bookId,
      'user_id': user.id,
      'reason': reason,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': 'pending',
    }).select();

    if (response is List && response.isNotEmpty) {
      return true;
    } else {
      throw Exception('Failed to insert borrow request');
    }
  } catch (e) {
    print('Error submitting borrow request: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to submit request: ${e.toString()}')),
    );
    return false;
  }
}

// Show success dialog after borrow request submission
void _showBorrowSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Request Submitted!', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          Text(
            'Your borrow request has been submitted successfully.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(),
          ),
          const SizedBox(height: 8),
          Text(
            'You will be notified when an admin approves your request.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0096C7)),
          child: Text('OK', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

class _BookInfoSection extends StatelessWidget {
  final BookDetails book;
  const _BookInfoSection({required this.book});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Color(0xFF0096C7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          book.author,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            Text(
              book.averageRating > 0
                ? book.averageRating.toStringAsFixed(1)
                : 'No ratings',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Text(
              '${book.reviewsCount} reviews',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ExpandableSummary(
          summary: book.summary,
          maxLines: 6, // Show 4-8 lines, you can adjust this value
        ),
        const SizedBox(height: 10),
        // Wrap(
        //   spacing: 8,
        //   runSpacing: 4,
        //   children: [
        //     ...book.genres.map<Widget>(
        //           (g) => Chip(
        //         label: Text(g),
        //         backgroundColor: const Color(0xFFE0EAFc),
        //       ),
        //     ),
        //   ],
        // ),
        const SizedBox(height: 10),
        _MetaItem(label: 'Category', value: book.category),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              
              _MetaItem(label: 'Language', value: book.language),
             
              _MetaItem(label: 'Published Date', value: DateFormat('yyyy-MM-dd').format(book.created_at)),
            ],
          ),
        ),
      ],
    );
  }
}

// Add the missing _ExpandableSummary widget
class _ExpandableSummary extends StatefulWidget {
  final String summary;
  final int maxLines;
  const _ExpandableSummary({
    required this.summary,
    this.maxLines = 4,
  });

  @override
  State<_ExpandableSummary> createState() => _ExpandableSummaryState();
}

class _ExpandableSummaryState extends State<_ExpandableSummary> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: expanded ? null : widget.maxLines,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        if (text.length > 120)
          TextButton(
            onPressed: () => setState(() => expanded = !expanded),
            child: Text(expanded ? 'Show less' : 'Show more'),
          ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetaItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18, bottom: 4),
      child: Chip(
        label: Text('$label: $value', style: const TextStyle(fontSize: 13)),
        backgroundColor: const Color(0xFFE0EAFc),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }
}

// class _BookEditionsSection extends StatelessWidget {
//   final BookDetails book;
//   const _BookEditionsSection({required this.book});
//   @override
//   Widget build(BuildContext context) {
//     final editions = (book.editions as List?) ?? [];
//     if (editions.isEmpty) {
//       return const SizedBox(height: 120);
//     }
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const _SectionHeader(title: 'More Edition'),
//         SizedBox(
//           height: 120,
//           child: ListView.separated(
//             scrollDirection: Axis.horizontal,
//             itemCount: editions.length,
//             separatorBuilder: (context, i) => const SizedBox(width: 14),
//             itemBuilder: (context, i) {
//               final ed = editions[i];
//               if (ed == null) {
//                 return const SizedBox(width: 70, height: 120);
//               }
//               return SizedBox(
//                 width: 70,
//                 child: Column(
//                   children: [
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.network(
//                         ed.cover ?? '',
//                         width: 60,
//                         height: 80,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) => Container(
//                           width: 60, // match width
//                           height: 80, // match height
//                           color: Colors.grey[300],
//                           child: const Icon(Icons.book, size: 30, color: Colors.grey),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       ed.type ?? '',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12,
//                       ),
//                     ),
//                     Text(
//                       ed.year ?? '',
//                       style: const TextStyle(
//                         color: Colors.blueGrey,
//                         fontSize: 11,
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//         const SizedBox(height: 6),
//         TextButton(onPressed: () {}, child: const Text('Show all Editions')),
//       ],
//     );
//   }
// }



class _RatingReviewsSection extends StatefulWidget {
  final BookDetails book;
  final List<ReviewBreakdown> reviewBreakdown;
  final List<Review> reviews;

  const _RatingReviewsSection({
    required this.book,
    required this.reviewBreakdown,
    required this.reviews,
  });

  @override
  State<_RatingReviewsSection> createState() => _RatingReviewsSectionState();
}

class _RatingReviewsSectionState extends State<_RatingReviewsSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final reviews = widget.reviews;
    final reviewsToShow = expanded ? reviews : (reviews.isNotEmpty ? [reviews.first] : []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Rating & Reviews', icon: Icons.star),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Review Submission
              Container(
                width: 260,
                margin: const EdgeInsets.only(right: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                            supabase.auth.currentUser?.userMetadata?['avatar_url'] ?? 'https://randomuser.me/api/portraits/men/31.jpg',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'What do you think?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        5,
                        (i) => const Icon(Icons.star_border, color: Colors.amber),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.rate_review, size: 18),
                      label: const Text('Write a Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0096C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) => WriteReviewDialog(
                            bookCover: widget.book.cover,
                            bookName: widget.book.title,
                            authorName: widget.book.author,
                            bookId: widget.book.id,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Statistics Chart
              SizedBox(
                width: 320,
                child: _CommunityReviewsChart(
                  rating: widget.book.averageRating,
                  count: widget.book.reviewsCount,
                  breakdown: widget.reviewBreakdown,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Readers Reviews',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (reviewsToShow.isEmpty)
          Center(child: Text('No reviews available', style: TextStyle(color: Colors.grey))),
        ...reviewsToShow.map((r) => _ReviewItem(review: r)),
        if (reviews.length > 1)
          TextButton(
            onPressed: () => setState(() => expanded = !expanded),
            child: Text(expanded ? 'Show Less Reviews' : 'Show More Reviews'),
          ),
      ],
    );
  }
}
Widget _BookStatsSection({required int currentlyReading, required String bookId}) {
  return FutureBuilder<int>(
    future: _fetchWantToReadCount(bookId),
    builder: (context, wantToReadSnapshot) {
      final wantToRead = wantToReadSnapshot.data ?? 0;
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.blueGrey[400]),
                    const SizedBox(width: 6),
                    Text(
                      '$currentlyReading people are currently reading',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Row(
                  children: [
                    Icon(Icons.bookmark, color: Colors.orange[400]),
                    const SizedBox(width: 6),
                    Text(
                      '$wantToRead want to Read',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Add this function somewhere above in your file (for example, after supabase definition)
Future<int> _fetchWantToReadCount(String bookId) async {
  try {
    // Fetch all users whose Favourites contains this bookId
    final response = await supabase
        .from('users')
        .select('Favourites');

    if (response is! List) return 0;

    int count = 0;
    for (var user in response) {
      final favs = user['Favourites'];
      if (favs == null) continue;
      if (favs is String) {
        final ids = favs.split(',').map((id) => id.trim()).toSet();
        if (ids.contains(bookId)) count++;
      } else if (favs is List) {
        final ids = favs.map((id) => id.toString()).toSet();
        if (ids.contains(bookId)) count++;
      }
    }
    return count;
  } catch (e) {
    print('Error fetching wantToRead count: $e');
    return 0;
  }
}


class _AboutAuthorSection extends StatelessWidget {
  final Author author;
  const _AboutAuthorSection({required this.author});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'About the Author'),
        Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ClipOval(
                child: Image.network(
                  author.photo,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, size: 32, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${author.books} Books ',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(author.bio, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}



class _CommunityReviewsChart extends StatelessWidget {
  final double rating;
  final int count;
  final List<ReviewBreakdown> breakdown;
  
  const _CommunityReviewsChart({
    required this.rating,
    required this.count,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    final counts = breakdown.map((b) => b.count).toList();
    final maxCount = counts.isNotEmpty ? counts.reduce((a, b) => a > b ? a : b) : 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: Color(0xFFFFB703),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Color(0xFFFFB703), size: 28),
              const SizedBox(width: 8),
              Text('$count ratings', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ...breakdown.map((b) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text('${b.stars}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Icon(Icons.star, color: Color(0xFFFFB703), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: LinearProgressIndicator(
                    value: maxCount > 0 ? b.count / maxCount : 0,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFFFFB703),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${b.count}', style: const TextStyle(fontSize: 13)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}

class BorrowSuccessDialog extends StatelessWidget {
  const BorrowSuccessDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 16,
                    padding: const EdgeInsets.all(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Thank you for the book borrow request',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: const Color(0xFF0096C7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Please, wait for the Admin's Approval",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: const Color(0xFF0096C7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(
              thickness: 1,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final Review review;
  final bool isOwnReview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _ReviewItem({required this.review, this.isOwnReview = false, this.onEdit, this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(review.photo),
                      radius: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(review.user, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (isOwnReview) Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(review.rating.toString(), style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Text(review.date, style: GoogleFonts.montserrat(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.text, style: GoogleFonts.montserrat()),
          ],
        ),
      ),
    );
  }
}
class _AlsoEnjoyedSection extends StatelessWidget {
  final List<BookRecommendation> books;
  const _AlsoEnjoyedSection({required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Center(
        child: Text('No related books found', style: TextStyle(color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, i) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final book = books[i];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailsPage(bookId: book.id),
                ),
              );
            },
            child: SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book.cover,
                      width: 100,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 140,
                        color: Colors.grey[300],
                        child: const Icon(Icons.book, size: 30, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    book.author,
                    style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      Text(book.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  const _SectionHeader({required this.title, this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF0096C7),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        if (icon != null) Icon(icon, color: Color(0xFF0096C7)),
        if (icon != null) const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF22223b),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(thickness: 1, color: Colors.grey)),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: const [
          Divider(),
          SizedBox(height: 8),
          Text(
            'Mr. and His Team COPYRIGHT (C) - 2025. ALL RIGHTS RESERVED',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          SizedBox(height: 4),

        ],
      ),
    );
  }
}

class WriteReviewDialog extends StatefulWidget {
  final String bookCover;
  final String bookName;
  final String authorName;
  final String bookId;

  const WriteReviewDialog({
    Key? key,
    required this.bookCover,
    required this.bookName,
    required this.authorName,
    required this.bookId,
  }) : super(key: key);

  @override
  State<WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<WriteReviewDialog> {
  int rating = 0;
  final TextEditingController reviewController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  Future<void> _submitReviewAndRating(BuildContext context) async {
    if (_formKey.currentState?.validate() != true) return;
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a rating.')),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please login to submit a review.')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Insert review into the new reviews table
      final response = await supabase
        .from('reviews')
        .insert({
          'book_id': widget.bookId,
          'user_id': user.id,
          'rating': rating,
          'review': reviewController.text.isNotEmpty ? reviewController.text : null,
        })
        .select();

      if (response is List && response.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to insert review');
      }
      setState(() => _isSubmitting = false);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF8BC7DB),
      child: Container(
        width: MediaQuery.of(context).size.width > 500 ? 500 : double.infinity,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Close button in top right
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 16,
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                ],
              ),

              // Title
              Text(
                'Write a Review',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: const Color(0xFF22223b),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Book cover
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.bookCover,
                  width: 120,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 120,
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.book, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Book title
              Text(
                widget.bookName,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: const Color(0xFF22223b),
                ),
                textAlign: TextAlign.center,
              ),

              // Author name
              Text(
                widget.authorName,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFF6B35),
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      rating = i + 1;
                    });
                  },
                  splashRadius: 20,
                )),
              ),
              const SizedBox(height: 20),

              // Reviews label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reviews',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF22223b),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Review text field
              Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: reviewController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Write your review about this book',
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a review';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitReviewAndRating(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0096C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Review'),
                ),
              ),
            ],
          ),
        ),
      ));
  }
}

class BorrowRequestDialog extends StatefulWidget {
  final String bookCover;
  final String bookName;
  final String authorName;
  const BorrowRequestDialog({
    required this.bookCover,
    required this.bookName,
    required this.authorName,
  });

  @override
  State<BorrowRequestDialog> createState() => _BorrowRequestDialogState();
}

class _BorrowRequestDialogState extends State<BorrowRequestDialog> {
  int step = 1;
  int rating = 0;
  final TextEditingController reasonController = TextEditingController();
  DateTime? collectionDate;
  DateTime? returnDate;
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: step == 1 ? const Color(0xFFBFE6FB) : Colors.white,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: MediaQuery.of(context).size.width > 500 ? 500 : double.infinity,
        padding: const EdgeInsets.all(32),
        child: step == 1 ? _buildStep1(context) : _buildStep2(context),
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Close button positioned at top right
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 16,
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ],
          ),
          // Title centered below
          Text('Borrow Request',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: const Color(0xFF22223b),
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              widget.bookCover,
              width: 120,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 120,
                height: 150,
                color: Colors.grey[300],
                child: const Icon(Icons.book, size: 40, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(widget.bookName,
              style: GoogleFonts.montserrat(

                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: const Color(0xFF22223b),
              )),
         
          const SizedBox(height: 13),
         
          Align(

            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4),
              child: Text(
                'Write Why You Want To Borrow This Book',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: reasonController,
              minLines: 3,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your reason to borrow',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a reason';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      step = 2;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38B000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 36, color: Color(0xFF0096C7)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Borrow Date\nDetails',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: const Color(0xFF0096C7),
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 16,
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ],
          ),
          const Divider(thickness: 1, height: 28),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Book Collection\nDate',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: collectionDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            collectionDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0096C7)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          collectionDate != null ? _dateFormat.format(collectionDate!) : 'Enter Date',
                          style: TextStyle(
                            color: collectionDate != null ? Colors.black : Colors.blueGrey,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Book Return\nDate',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: returnDate ?? (collectionDate ?? DateTime.now()),
                          firstDate: collectionDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (picked != null) {
                          setState(() {
                            returnDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0096C7)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          returnDate != null ? _dateFormat.format(returnDate!) : 'Enter Date',
                          style: TextStyle(
                            color: returnDate != null ? Colors.black : Colors.blueGrey,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBFE6FB),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Validate dates and show confirmation dialog
                    if (collectionDate != null && returnDate != null) {
                      showDialog(
                        context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Borrow Request'),
                  content: Text(
                    'Book: ${widget.bookName}\n'
                    'Author: ${widget.authorName}\n'
                    'Collection Date: ${_dateFormat.format(collectionDate!)}\n'
                    'Return Date: ${_dateFormat.format(returnDate!)}\n\n'
                    'Do you want to proceed with the request?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Handle the borrow request submission
                        // For now, just show a success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Borrow request submitted!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.of(context).pop(); // Close the dialog
                        Navigator.of(context).pop(); // Close the BorrowRequestDialog
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              );
             } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select both dates.')),
              );
              }
            },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0096C7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          child: const Text('CONFIRM'),
        ),
      ),

            ],
          ),
        ],
      ),
    );
  }


}
