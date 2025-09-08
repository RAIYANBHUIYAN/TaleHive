import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/club_model.dart';
import '../../models/club_book_model.dart';
import '../../services/club_service.dart';

class ClubBooksPage extends StatefulWidget {
  final Club club;

  const ClubBooksPage({Key? key, required this.club}) : super(key: key);

  @override
  State<ClubBooksPage> createState() => _ClubBooksPageState();
}

class _ClubBooksPageState extends State<ClubBooksPage> {
  final ClubService _clubService = ClubService();
  List<ClubBook> _clubBooks = [];
  List<Map<String, dynamic>> _availableBooks = [];
  bool _isLoading = true;
  bool _isLoadingAvailableBooks = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadClubBooks();
  }

  Future<void> _loadClubBooks() async {
    setState(() => _isLoading = true);
    try {
      final books = await _clubService.getClubBooks(widget.club.id);
      setState(() {
        _clubBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading club books: $e')),
      );
    }
  }

  Future<void> _loadAvailableBooks() async {
    setState(() => _isLoadingAvailableBooks = true);
    try {
      // Get all books from the books table that aren't already in this club
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('books')
          .select('*')
          .order('created_at', ascending: false);

      // Filter out books that are already in the club
      final clubBookIds = _clubBooks.map((cb) => cb.bookId).toSet();
      final availableBooks = (response as List)
          .where((book) => !clubBookIds.contains(book['id']))
          .toList();

      setState(() {
        _availableBooks = availableBooks.cast<Map<String, dynamic>>();
        _isLoadingAvailableBooks = false;
      });
    } catch (e) {
      setState(() => _isLoadingAvailableBooks = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading available books: $e')),
      );
    }
  }

  List<ClubBook> get _filteredBooks {
    if (_searchQuery.isEmpty) return _clubBooks;
    return _clubBooks.where((book) =>
        book.bookTitle?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
        book.bookAuthorId?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
        book.bookCategory?.toLowerCase().contains(_searchQuery.toLowerCase()) == true
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${widget.club.name} - Books'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBookDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClubBooks,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Books',
                        _clubBooks.length.toString(),
                        Icons.menu_book,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Added This Month',
                        _clubBooks.where((book) {
                          final now = DateTime.now();
                          return book.addedAt.month == now.month && 
                                 book.addedAt.year == now.year;
                        }).length.toString(),
                        Icons.add_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Categories',
                        _clubBooks.map((b) => b.bookCategory ?? 'Other').toSet().length.toString(),
                        Icons.category,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search bar
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search books...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF1F5F9),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ],
            ),
          ),

          // Books list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No books in this club yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap the + button to add books',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = _filteredBooks[index];
                          return _buildBookCard(book);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(ClubBook book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Book cover placeholder
            Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: book.bookCoverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        book.bookCoverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.book, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.book, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            
            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.bookTitle ?? 'Unknown Title',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (book.bookAuthorId != null)
                    Text(
                      'Author ID: ${book.bookAuthorId}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (book.bookCategory != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            book.bookCategory!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Added ${_formatDate(book.addedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleBookAction(value, book),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view_details',
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 16),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove_from_club',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove from Club', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleBookAction(String action, ClubBook book) {
    switch (action) {
      case 'view_details':
        // TODO: Show book details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing details for ${book.bookTitle}')),
        );
        break;
      case 'remove_from_club':
        _showRemoveBookDialog(book);
        break;
    }
  }

  void _showRemoveBookDialog(ClubBook book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Book'),
        content: Text(
          'Are you sure you want to remove "${book.bookTitle}" from ${widget.club.name}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final success = await _clubService.removeBookFromClub(
                  widget.club.id,
                  book.bookId,
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${book.bookTitle} removed from club')),
                  );
                  _loadClubBooks(); // Refresh the list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to remove book')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddBookDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Books to Club'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search available books...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            // TODO: Implement search filtering
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _loadAvailableBooks();
                          setDialogState(() {});
                        },
                        child: const Text('Load Books'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: _isLoadingAvailableBooks
                        ? const Center(child: CircularProgressIndicator())
                        : _availableBooks.isEmpty
                            ? const Center(
                                child: Text('No books available to add'),
                              )
                            : ListView.builder(
                                itemCount: _availableBooks.length,
                                itemBuilder: (context, index) {
                                  final book = _availableBooks[index];
                                  return ListTile(
                                    leading: const Icon(Icons.book),
                                    title: Text(book['name'] ?? 'Unknown Title'),
                                    subtitle: Text(book['author'] ?? 'Unknown Author'),
                                    trailing: ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          final success = await _clubService.addBookToClub(
                                            widget.club.id,
                                            book['id'],
                                          );
                                          if (success) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${book['name']} added to club')),
                                            );
                                            _loadClubBooks(); // Refresh the list
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Failed to add book')),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e')),
                                          );
                                        }
                                      },
                                      child: const Text('Add'),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}
