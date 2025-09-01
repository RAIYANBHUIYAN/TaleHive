import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'book_details.dart';

class MyBooksPage extends StatefulWidget {
  final VoidCallback? onBooksChanged;
  
  const MyBooksPage({Key? key, this.onBooksChanged}) : super(key: key);

  @override
  State<MyBooksPage> createState() => _MyBooksPageState();
}

class _MyBooksPageState extends State<MyBooksPage> {
  final supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _myBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyBooks();
  }

  Future<void> _loadMyBooks() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // First, load all borrow requests for this user
      final borrowRequestsResponse = await supabase
          .from('borrow_requests')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      print('📚 My Books Debug: Found ${borrowRequestsResponse.length} borrow requests');

      if (borrowRequestsResponse.isEmpty) {
        setState(() {
          _myBooks = [];
        });
        return;
      }

      // Extract all book IDs from borrow requests (not unique, to handle multiple requests for same book)
      final bookIds = borrowRequestsResponse
          .map((request) => request['book_id'])
          .where((id) => id != null)
          .toList();

      if (bookIds.isEmpty) {
        setState(() {
          _myBooks = [];
        });
        return;
      }

      // Get unique book IDs for fetching book details
      final uniqueBookIds = bookIds.toSet().toList();

      // Fetch book details for each unique book ID
      final List<Map<String, dynamic>> allBooks = [];
      for (final bookId in uniqueBookIds) {
        try {
          final bookResponse = await supabase
              .from('books')
              .select('*')
              .eq('id', bookId)
              .single();
          allBooks.add(bookResponse);
        } catch (e) {
          print('Error fetching book $bookId: $e');
          // Continue with other books even if one fails
        }
      }

      // Create a map of book ID to book data for easy lookup
      final booksMap = <String, Map<String, dynamic>>{};
      for (final book in allBooks) {
        booksMap[book['id'].toString()] = book;
      }

      setState(() {
        _myBooks = _processBookRequests(borrowRequestsResponse, booksMap);
        print('📚 My Books Debug: Processed ${_myBooks.length} books for display');
      });

    } catch (e) {
      print('Error loading my books: $e');
      _showSnackBar('Failed to load books: ${e.toString()}', backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _processBookRequests(List<dynamic> requests, Map<String, Map<String, dynamic>> booksMap) {
    return requests.map((request) {
      final bookId = request['book_id']?.toString() ?? '';
      final book = booksMap[bookId] ?? {};
      final status = request['status']?.toString() ?? 'unknown';
      
      print('📚 Processing book: ${book['title']} - Status: $status');
      
      return {
        'id': bookId,
        'title': book['title'] ?? 'Unknown Title',
        'author': book['author_name'] ?? 'Unknown Author',
        'cover_image': book['cover_image_url'],
        'description': book['description'] ?? '',
        'category': book['category'] ?? '',
        'request_date': request['created_at'],
        'status': status,
        'request_id': request['id'],
        'borrow_date': request['start_date'],
        'return_date': request['end_date'],
      };
    }).toList();
  }

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

  int _getGridCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) {
      return 2; // Mobile
    } else if (screenWidth < 900) {
      return 3; // Tablet portrait
    } else if (screenWidth < 1200) {
      return 4; // Tablet landscape
    } else {
      return 5; // Desktop
    }
  }

  double _getGridAspectRatio(double screenWidth) {
    if (screenWidth < 400) {
      return 0.65;
    } else if (screenWidth < 600) {
      return 0.68;
    } else if (screenWidth < 900) {
      return 0.72;
    } else {
      return 0.75;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22223b)),
          onPressed: () => Navigator.pop(context),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'My Books',
            style: GoogleFonts.montserrat(
              color: const Color(0xFF22223b),
              fontWeight: FontWeight.bold,
              fontSize: screenWidth < 400 ? 18 : 20,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF22223b)),
            onPressed: _loadMyBooks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0096C7)))
          : _myBooks.isEmpty
              ? _buildEmptyState(screenWidth)
              : _buildBooksGrid(_myBooks, screenWidth),
    );
  }

  Widget _buildBooksGrid(List<Map<String, dynamic>> books, double screenWidth) {
    if (books.isEmpty) {
      return _buildEmptyState(screenWidth);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getGridCrossAxisCount(screenWidth),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: _getGridAspectRatio(screenWidth),
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          return _buildBookCard(books[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          width: screenWidth,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.1,
            vertical: 60,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0096C7).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: Color(0xFF0096C7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Requested Books',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: screenWidth < 400 ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF22223b),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You haven\'t requested any books yet.\nBrowse the library and request books you\'d like to read!',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: screenWidth < 400 ? 14 : 16,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.explore),
                label: Text(
                  'Browse Library',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0096C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    final bookId = book['id']?.toString() ?? '';
    final status = book['status'] ?? 'unknown';
    
    return GestureDetector(
      onTap: () async {
        // Navigate to book details
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsPage(bookId: bookId),
          ),
        );
        
        // Reload books when returning
        if (widget.onBooksChanged != null) {
          widget.onBooksChanged!();
        }
        _loadMyBooks();
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
                  child: book['cover_image'] != null && book['cover_image'].isNotEmpty
                      ? Image.network(
                          book['cover_image'],
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
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
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
                      book['author'] ?? 'Unknown Author',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Request/Due Date
                    if (book['request_date'] != null || book['return_date'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _getDateText(book, status),
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

  Color _getStatusColor(String status) {
    final normalizedStatus = status.toLowerCase().trim();
    switch (normalizedStatus) {
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'accepted':
        return Colors.green;
      case 'borrowed':
        return const Color(0xFF0096C7);
      case 'returned':
        return Colors.grey;
      case 'rejected':
      case 'denied':
        return Colors.red;
      default:
        return Colors.purple; // Use purple for any unknown status to make it visible
    }
  }

  String _getStatusText(String status) {
    final normalizedStatus = status.toLowerCase().trim();
    switch (normalizedStatus) {
      case 'pending':
        return 'PENDING';
      case 'approved':
        return 'APPROVED';
      case 'borrowed':
        return 'BORROWED';
      case 'returned':
        return 'RETURNED';
      case 'rejected':
        return 'REJECTED';
      case 'accepted':
        return 'APPROVED';
      case 'denied':
        return 'REJECTED';
      default:
        return normalizedStatus.toUpperCase();
    }
  }

  String _getDateText(Map<String, dynamic> book, String status) {
    if (status == 'borrowed') {
      if (book['return_date'] != null) {
        try {
          final returnDate = DateTime.parse(book['return_date']);
          return 'Return by: ${returnDate.day}/${returnDate.month}/${returnDate.year}';
        } catch (e) {
          return 'Return by: ${book['return_date']}';
        }
      } else if (book['borrow_date'] != null) {
        try {
          final borrowDate = DateTime.parse(book['borrow_date']);
          return 'Borrowed: ${borrowDate.day}/${borrowDate.month}/${borrowDate.year}';
        } catch (e) {
          return 'Borrowed: ${book['borrow_date']}';
        }
      }
    } else if (status == 'approved') {
      if (book['borrow_date'] != null) {
        try {
          final startDate = DateTime.parse(book['borrow_date']);
          return 'Available from: ${startDate.day}/${startDate.month}/${startDate.year}';
        } catch (e) {
          return 'Available from: ${book['borrow_date']}';
        }
      }
      if (book['return_date'] != null) {
        try {
          final endDate = DateTime.parse(book['return_date']);
          return 'Until: ${endDate.day}/${endDate.month}/${endDate.year}';
        } catch (e) {
          return 'Until: ${book['return_date']}';
        }
      }
    } else if (book['request_date'] != null) {
      try {
        final requestDate = DateTime.parse(book['request_date']);
        return 'Requested: ${requestDate.day}/${requestDate.month}/${requestDate.year}';
      } catch (e) {
        return 'Requested: ${book['request_date']}';
      }
    }
    return '';
  }
}
