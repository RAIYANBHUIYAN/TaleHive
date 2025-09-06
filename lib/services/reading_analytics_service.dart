import 'package:supabase_flutter/supabase_flutter.dart';

class ReadingAnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current readers (Reading Books tab)
  Future<List<Map<String, dynamic>>> getCurrentReadings() async {
    try {
      final response = await _supabase.rpc('get_current_readings');
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error fetching current readings: $e');
      return [];
    }
  }

  // Get most popular books (Most Readable Books tab)
  Future<List<Map<String, dynamic>>> getMostPopularBooks() async {
    try {
      final response = await _supabase.rpc('get_most_popular_books');
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error fetching most popular books: $e');
      return [];
    }
  }

  // Extend due date (updates borrow_requests end_date)
  // This is the main admin action since books auto-expire after end_date
  Future<bool> extendDueDate(String readingId, DateTime newDueDate) async {
    try {
      final response = await _supabase.rpc('extend_due_date', params: {
        'reading_id': readingId,
        'new_due_date': newDueDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
      });
      return response == true;
    } catch (e) {
      print('Error extending due date: $e');
      return false;
    }
  }

  // Get active books for a user (books that haven't expired yet)
  Future<List<Map<String, dynamic>>> getUserActiveBooks(String userId) async {
    try {
      final response = await _supabase.rpc('get_user_active_books', params: {
        'user_uuid': userId,
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error fetching user active books: $e');
      return [];
    }
  }

  // Get statistics for dashboard
  Future<Map<String, int>> getSimpleStats() async {
    try {
      // Get total current readers (borrow_requests with status 'accepted')
      final currentReadings = await getCurrentReadings();
      final totalReaders = currentReadings.length;
      final overdueBooks = currentReadings.where((r) => r['status'] == 'overdue').length;
      
      // Get total books in popularity table
      final popularBooks = await getMostPopularBooks();
      final totalPopularBooks = popularBooks.length;

      return {
        'total_current_readers': totalReaders,
        'overdue_books': overdueBooks,
        'popular_books_count': totalPopularBooks,
      };
    } catch (e) {
      print('Error fetching stats: $e');
      return {
        'total_current_readers': 0,
        'overdue_books': 0,
        'popular_books_count': 0,
      };
    }
  }
}
