import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/reading_history_service.dart';
import 'book_details.dart';

class ReadingHistoryPage extends StatefulWidget {
  const ReadingHistoryPage({Key? key}) : super(key: key);

  @override
  State<ReadingHistoryPage> createState() => _ReadingHistoryPageState();
}

class _ReadingHistoryPageState extends State<ReadingHistoryPage> {
  final supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _readBooks = [];
  Map<String, dynamic> _readingStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReadingHistory();
  }

  Future<void> _loadReadingHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        _showSnackBar('Please login to view reading history', backgroundColor: Colors.orange);
        return;
      }

      print('📖 Reading History Debug: Loading data for user: ${user.id}');

      // Load all read books and stats
      final results = await Future.wait([
        ReadingHistoryService.getUserReadBooks(user.id),
        ReadingHistoryService.getUserReadingStats(user.id),
      ]);

      setState(() {
        _readBooks = results[0] as List<Map<String, dynamic>>;
        _readingStats = results[1] as Map<String, dynamic>;
      });

      print('📖 Reading History Debug: Loaded ${_readBooks.length} total read books');
      print('📖 Reading History Debug: Books data: $_readBooks');
      print('📖 Reading History Debug: Stats: $_readingStats');
      
      if (_readBooks.isEmpty) {
        print('📖 Reading History Debug: No books found, checking database...');
        await _debugCheckDatabase(user.id);
      }

      // Show refresh feedback (only if not initial load)
      if (mounted && !_isLoading) {
        _showSnackBar('📚 Reading history refreshed', backgroundColor: const Color(0xFF0096C7));
      }
      
    } catch (e) {
      print('📖 Reading History Error loading: $e');
      _showSnackBar('Failed to load reading history: ${e.toString()}', backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
          'Reading History',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF22223b),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReadingHistory,
        color: const Color(0xFF0096C7),
        backgroundColor: Colors.white,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0096C7)),
                    SizedBox(height: 16),
                    Text('Loading your reading history...'),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  // Statistics Section as a sliver
                  SliverToBoxAdapter(
                    child: _buildStatisticsSection(MediaQuery.of(context).size.width),
                  ),
                  
                  // Books Grid as a sliver
                  _buildBookGridSliver(_readBooks),
                ],
              ),
      ),
    );
  }

  Widget _buildStatisticsSection(double screenWidth) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0096C7), Color(0xFF00B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Reading Journey',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.menu_book,
                  title: 'Books Read',
                  value: (_readingStats['total_books_read'] ?? 0).toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.auto_stories,
                  title: 'Reading Sessions',
                  value: (_readingStats['total_reading_sessions'] ?? 0).toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,
                  title: 'Avg Reads',
                  value: (_readingStats['average_reads_per_book'] ?? '0.0').toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.bookmark,
                  title: 'Total Books',
                  value: _readBooks.length.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookGridSliver(List<Map<String, dynamic>> books) {
    if (books.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book,
                size: 64,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 16),
              Text(
                'No books in your reading history yet',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start reading books to see them here!',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getGridCrossAxisCount(MediaQuery.of(context).size.width),
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildBookCard(books[index]);
          },
          childCount: books.length,
        ),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> bookData) {
    final book = bookData['book'] as Map<String, dynamic>;
    final readingInfo = bookData['reading_info'] as Map<String, dynamic>;
    final bookId = book['id']?.toString() ?? '';
    
    return GestureDetector(
      onTap: () async {
        // Navigate to book details
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsPage(
              bookId: bookId,
              onFavoriteChanged: () {
                // Handle favorite changes if needed
                print('📖 Favorite status changed for book: $bookId');
              },
            ),
          ),
        );
        
        // Reload history when returning
        _loadReadingHistory();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: book['cover_image_url'] != null && book['cover_image_url'].isNotEmpty
                      ? Image.network(
                          book['cover_image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderCover(),
                        )
                      : _buildPlaceholderCover(),
                ),
              ),
            ),
            // Book Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reading Info Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0096C7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${readingInfo['read_count'] ?? 1}x read',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Expanded(
                      child: Text(
                        book['title'] ?? 'Unknown Title',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF22223b),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Author
                    Text(
                      book['author_name'] ?? 'Unknown Author',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Last read time
                    if (readingInfo['last_read_at'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _formatReadTime(readingInfo['last_read_at']),
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.book,
          size: 40,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  String _formatReadTime(String isoTime) {
    try {
      final readTime = DateTime.parse(isoTime);
      final now = DateTime.now();
      final difference = now.difference(readTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(readTime);
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Future<void> _debugCheckDatabase(String userId) async {
    try {
      print('📖 Reading History Debug: Checking reading_history table directly...');
      
      // Check reading_history table
      final readingHistoryData = await supabase
          .from('reading_history')
          .select('*')
          .eq('user_id', userId);
      
      print('📖 Reading History Debug: Direct reading_history query result: $readingHistoryData');
      
      // Check books table
      final booksData = await supabase
          .from('books')
          .select('id, title, author_name')
          .limit(5);
          
      print('📖 Reading History Debug: Sample books in database: $booksData');
      
    } catch (e) {
      print('📖 Reading History Debug Error: $e');
    }
  }

  int _getGridCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) {
      return 2; // Mobile
    } else if (screenWidth < 900) {
      return 3; // Tablet portrait
    } else {
      return 4; // Desktop/Tablet landscape
    }
  }
}
