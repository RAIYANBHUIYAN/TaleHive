import 'package:supabase_flutter/supabase_flutter.dart';

class ReadingHistoryService {
  static final supabase = Supabase.instance.client;

  // Track when a user actually READS a book (opens PDF)
  static Future<bool> trackBookReading(String userId, String bookId) async {
    try {
      // First, check if record already exists
      final existingRecord = await supabase
          .from('reading_history')
          .select('read_count')
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .maybeSingle();

      if (existingRecord != null) {
        // Record exists, increment read count
        final currentReadCount = existingRecord['read_count'] ?? 1;
        await supabase
            .from('reading_history')
            .update({
              'read_count': currentReadCount + 1,
              'last_read_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('book_id', bookId);
        
        print('📖 Reading History Debug: Updated existing record, new count: ${currentReadCount + 1}');
      } else {
        // New record, create with read_count = 1 (default)
        await supabase
            .from('reading_history')
            .insert({
              'user_id': userId,
              'book_id': bookId,
              'first_read_at': DateTime.now().toIso8601String(),
              'last_read_at': DateTime.now().toIso8601String(),
              // read_count will default to 1 from database schema
            });
        
        print('📖 Reading History Debug: Created new reading record with count: 1');
      }

      return true;
    } catch (e) {
      print('Error tracking book reading: $e');
      return false;
    }
  }

  // Get all books read by a user (for Reading History)
  static Future<List<Map<String, dynamic>>> getUserReadBooks(String userId) async {
    try {
      print('📖 Reading History Debug: Fetching books for user: $userId');
      
      // First, get reading history records
      final readingHistoryResponse = await supabase
          .from('reading_history')
          .select('*')
          .eq('user_id', userId)
          .order('last_read_at', ascending: false);

      print('📖 Reading History Debug: Reading history records: $readingHistoryResponse');

      if (readingHistoryResponse.isEmpty) {
        print('📖 Reading History Debug: No reading history found for user');
        return [];
      }

      // Get all unique book IDs
      final bookIds = readingHistoryResponse
          .map((record) => record['book_id'].toString())
          .toSet()
          .toList();
      
      print('📖 Reading History Debug: Book IDs to fetch: $bookIds');

      // Get books data separately - let's try a different approach
      final result = <Map<String, dynamic>>[];
      
      for (final historyRecord in readingHistoryResponse) {
        final bookId = historyRecord['book_id'].toString();
        
        // Get book data for this specific book with author info
        final bookResponse = await supabase
            .from('books')
            .select('''
              id, 
              title, 
              author_id,
              cover_image_url, 
              published_at, 
              category, 
              access_type, 
              description,
              authors:author_id (
                id,
                first_name,
                last_name,
                display_name
              )
            ''')
            .eq('id', bookId)
            .maybeSingle();
        
        print('📖 Reading History Debug: Book data for ID $bookId: $bookResponse');
        
        if (bookResponse != null) {
          // Extract author name from authors table
          String authorName = 'Unknown Author';
          if (bookResponse['authors'] != null) {
            final author = bookResponse['authors'];
            if (author['display_name'] != null && author['display_name'].toString().trim().isNotEmpty) {
              authorName = author['display_name'];
            } else if (author['first_name'] != null || author['last_name'] != null) {
              final firstName = author['first_name'] ?? '';
              final lastName = author['last_name'] ?? '';
              authorName = '$firstName $lastName'.trim();
            }
          }
          
          // Create book data with proper author name
          final bookData = Map<String, dynamic>.from(bookResponse);
          bookData['author_name'] = authorName;
          bookData.remove('authors'); // Remove the nested authors object
          
          result.add({
            'book': bookData,
            'reading_info': {
              'read_count': historyRecord['read_count'],
              'first_read_at': historyRecord['first_read_at'],
              'last_read_at': historyRecord['last_read_at'],
              'created_at': historyRecord['created_at'],
            },
          });
        } else {
          print('📖 Reading History Debug: No book found for ID: $bookId');
        }
      }

      print('📖 Reading History Debug: Final combined result: $result');
      return result;
    } catch (e) {
      print('📖 Reading History Error: $e');
      return [];
    }
  }

  // Get recently read books (last N books)
  static Future<List<Map<String, dynamic>>> getRecentlyReadBooks(String userId, {int limit = 10}) async {
    try {
      final readingHistoryResponse = await supabase
          .from('reading_history')
          .select('*')
          .eq('user_id', userId)
          .order('last_read_at', ascending: false)
          .limit(limit);

      if (readingHistoryResponse.isEmpty) {
        return [];
      }

      final result = <Map<String, dynamic>>[];
      
      for (final historyRecord in readingHistoryResponse) {
        final bookId = historyRecord['book_id'].toString();
        
        final bookResponse = await supabase
            .from('books')
            .select('''
              id, 
              title, 
              author_id,
              cover_image_url, 
              published_at, 
              category, 
              access_type,
              authors:author_id (
                id,
                first_name,
                last_name,
                display_name
              )
            ''')
            .eq('id', bookId)
            .maybeSingle();
        
        if (bookResponse != null) {
          // Extract author name
          String authorName = 'Unknown Author';
          if (bookResponse['authors'] != null) {
            final author = bookResponse['authors'];
            if (author['display_name'] != null && author['display_name'].toString().trim().isNotEmpty) {
              authorName = author['display_name'];
            } else if (author['first_name'] != null || author['last_name'] != null) {
              final firstName = author['first_name'] ?? '';
              final lastName = author['last_name'] ?? '';
              authorName = '$firstName $lastName'.trim();
            }
          }
          
          final bookData = Map<String, dynamic>.from(bookResponse);
          bookData['author_name'] = authorName;
          bookData.remove('authors');
          
          result.add({
            'book': bookData,
            'reading_info': {
              'read_count': historyRecord['read_count'],
              'first_read_at': historyRecord['first_read_at'],
              'last_read_at': historyRecord['last_read_at'],
              'created_at': historyRecord['created_at'],
            },
          });
        }
      }

      return result;
    } catch (e) {
      print('Error fetching recently read books: $e');
      return [];
    }
  }

  // Get books read today
  static Future<List<Map<String, dynamic>>> getBooksReadToday(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

      final readingHistoryResponse = await supabase
          .from('reading_history')
          .select('*')
          .eq('user_id', userId)
          .gte('last_read_at', startOfDay)
          .lte('last_read_at', endOfDay)
          .order('last_read_at', ascending: false);

      if (readingHistoryResponse.isEmpty) {
        return [];
      }

      final result = <Map<String, dynamic>>[];
      
      for (final historyRecord in readingHistoryResponse) {
        final bookId = historyRecord['book_id'].toString();
        
        final bookResponse = await supabase
            .from('books')
            .select('''
              id, 
              title, 
              author_id,
              cover_image_url, 
              published_at, 
              category, 
              access_type,
              authors:author_id (
                id,
                first_name,
                last_name,
                display_name
              )
            ''')
            .eq('id', bookId)
            .maybeSingle();
        
        if (bookResponse != null) {
          // Extract author name
          String authorName = 'Unknown Author';
          if (bookResponse['authors'] != null) {
            final author = bookResponse['authors'];
            if (author['display_name'] != null && author['display_name'].toString().trim().isNotEmpty) {
              authorName = author['display_name'];
            } else if (author['first_name'] != null || author['last_name'] != null) {
              final firstName = author['first_name'] ?? '';
              final lastName = author['last_name'] ?? '';
              authorName = '$firstName $lastName'.trim();
            }
          }
          
          final bookData = Map<String, dynamic>.from(bookResponse);
          bookData['author_name'] = authorName;
          bookData.remove('authors');
          
          result.add({
            'book': bookData,
            'reading_info': {
              'read_count': historyRecord['read_count'],
              'first_read_at': historyRecord['first_read_at'],
              'last_read_at': historyRecord['last_read_at'],
              'created_at': historyRecord['created_at'],
            },
          });
        }
      }

      return result;
    } catch (e) {
      print('Error fetching books read today: $e');
      return [];
    }
  }

  // Get reading statistics for a user
  static Future<Map<String, dynamic>> getUserReadingStats(String userId) async {
    try {
      final response = await supabase
          .from('reading_history')
          .select('read_count')
          .eq('user_id', userId);

      if (response.isEmpty) {
        return {
          'total_books_read': 0,
          'total_reading_sessions': 0,
          'average_reads_per_book': 0.0,
        };
      }

      final totalBooksRead = response.length;
      final totalReadingSessions = response.fold<int>(
        0, (sum, item) => sum + (item['read_count'] as int),
      );
      final averageReadsPerBook = totalReadingSessions / totalBooksRead;

      return {
        'total_books_read': totalBooksRead,
        'total_reading_sessions': totalReadingSessions,
        'average_reads_per_book': averageReadsPerBook.toStringAsFixed(1),
      };
    } catch (e) {
      print('Error fetching reading stats: $e');
      return {
        'total_books_read': 0,
        'total_reading_sessions': 0,
        'average_reads_per_book': '0.0',
      };
    }
  }

  // Check if user has read a specific book
  static Future<Map<String, dynamic>?> getUserBookReadingInfo(String userId, String bookId) async {
    try {
      final response = await supabase
          .from('reading_history')
          .select('*')
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error checking book reading info: $e');
      return null;
    }
  }

  // Get reading activity for the past week
  static Future<List<Map<String, dynamic>>> getWeeklyReadingActivity(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7)).toIso8601String();

      final response = await supabase
          .from('reading_history')
          .select('last_read_at, read_count')
          .eq('user_id', userId)
          .gte('last_read_at', weekAgo)
          .order('last_read_at', ascending: false);

      return response;
    } catch (e) {
      print('Error fetching weekly reading activity: $e');
      return [];
    }
  }
}
