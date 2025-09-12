import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/club_model.dart';
import '../../models/club_book_model.dart';
import '../../services/club_service.dart';
import '../pdf_preview/pdf_viewer_page.dart';
import 'package:path/path.dart' as path;

class ClubBooksPage extends StatefulWidget {
  final Club club;

  const ClubBooksPage({Key? key, required this.club}) : super(key: key);

  @override
  State<ClubBooksPage> createState() => _ClubBooksPageState();
}

class _ClubBooksPageState extends State<ClubBooksPage> {
  final ClubService _clubService = ClubService();
  final ImagePicker _imagePicker = ImagePicker();
  final supabase = Supabase.instance.client;
  List<ClubBook> _clubBooks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Add author data similar to author dashboard
  Map<String, dynamic>? authorData;
  final author = {
    'first_name': 'Club',
    'last_name': 'Admin',
    'bio': 'Club administrator',
    'avatar': 'Asset/images/loren.jpg',
    'email': 'admin@email.com',
  };

  @override
  void initState() {
    super.initState();
    _loadClubBooks();
    _loadAuthorData();
  }

  Future<void> _loadAuthorData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('authors')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (response != null) {
          setState(() {
            authorData = response;
          });
        }
      }
    } catch (e) {
      print('Error loading author data: $e');
    }
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
            tooltip: 'Upload New Book',
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (_filteredBooks.isEmpty)
                      ? Card(
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Icons.library_books, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('No books found', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('Start by publishing your first book!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        )
                      : Card(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredBooks.length,
                            separatorBuilder: (context, i) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final book = _filteredBooks[i];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildBookCover(book, 80, 120),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.bookTitle ?? 'No Title',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                  
                                          if (book.bookCategory != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[100],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                book.bookCategory!,
                                                style: TextStyle(color: Colors.blue[800], fontSize: 12, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              if (book.bookPrice != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green[100],
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '\$${book.bookPrice}',
                                                    style: TextStyle(color: Colors.green[800], fontSize: 14, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.green[200]!),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.picture_as_pdf, size: 12, color: Colors.green[700]),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'PDF',
                                                      style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.launch, color: Colors.green),
                                          tooltip: 'Open PDF',
                                          onPressed: () => _handleBookAction('view_pdf', book),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          tooltip: 'Edit Book',
                                          onPressed: () => _handleBookAction('edit_book', book),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Remove from Club',
                                          onPressed: () => _handleBookAction('remove_from_club', book),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
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

  // Build book cover from Supabase URL or placeholder (matching author dashboard)
  Widget _buildBookCover(ClubBook book, double width, double height) {
    final coverUrl = book.bookCoverUrl;
    
    if (coverUrl != null && coverUrl.toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          coverUrl.toString(),
          width: width,
          height: height,
          fit: BoxFit.cover,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            
            final progress = loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null;
            
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2,
                    ),
                    if (progress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, color: Colors.grey[600], size: width * 0.4),
                  const SizedBox(height: 4),
                  Text(
                    'No Cover',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, color: Colors.grey[600], size: width * 0.4),
            const SizedBox(height: 4),
            Text(
              'No Cover',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _handleBookAction(String action, ClubBook book) {
    switch (action) {
      case 'view_pdf':
        _handlePdfView(book);
        break;
      case 'edit_book':
        _showEditBookDialog(book);
        break;
      case 'remove_from_club':
        _showRemoveBookDialog(book);
        break;
    }
  }

  // Handle PDF viewing from Supabase URL
  Future<void> _handlePdfView(ClubBook book) async {
    final pdfUrl = book.bookPdfUrl;
    final bookTitle = book.bookTitle ?? 'Unknown Book';
    
    if (pdfUrl != null && pdfUrl.toString().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerPage(
            pdfUrl: pdfUrl.toString(),
            bookTitle: bookTitle,
            bookId: book.bookId, // Pass the required bookId argument
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF file available')),
      );
    }
  }

  // Show edit book dialog similar to author dashboard
  void _showEditBookDialog(ClubBook book) {
    final titleController = TextEditingController(text: book.bookTitle ?? '');
    final summaryController = TextEditingController(text: book.bookSummary ?? '');
    String? avatarUrl = book.bookCoverUrl;
    bool isUploading = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Book Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Book Cover
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                                ? Image.network(
                                    avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.book, size: 40, color: Colors.grey),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.book, size: 40, color: Colors.grey),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              setState(() => isUploading = true);
                              try {
                                final image = await _imagePicker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 400,
                                  maxHeight: 600,
                                  imageQuality: 85,
                                );
                                if (image != null) {
                                  final bytes = await image.readAsBytes();
                                  final user = supabase.auth.currentUser;
                                  if (user == null) throw Exception('User not authenticated');
                                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                                  final extension = path.extension(image.path).toLowerCase();
                                  final fileName = 'book_cover_${book.bookId}_$timestamp$extension';
                                  
                                  // Show progress indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const AlertDialog(
                                      content: SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                                    ),
                                  );
                                  
                                  await supabase.storage
                                      .from('book-covers')
                                      .uploadBinary(fileName, bytes,
                                        fileOptions: const FileOptions(upsert: false),
                                      );
                                  Navigator.pop(context); // Close progress dialog
                                  
                                  final publicUrl = supabase.storage
                                      .from('book-covers')
                                      .getPublicUrl(fileName);
                                  setState(() => avatarUrl = publicUrl);
                                }
                              } catch (e) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error uploading photo: $e'), backgroundColor: Colors.red),
                                );
                              } finally {
                                setState(() => isUploading = false);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                              ),
                              padding: const EdgeInsets.all(4),
                              child: isUploading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.edit, size: 20, color: Color(0xFF6C63FF)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController, 
                      decoration: const InputDecoration(labelText: 'Book Title'),
                    ),
                    TextField(
                      controller: summaryController, 
                      decoration: const InputDecoration(labelText: 'Summary'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Update book in database
                      await supabase.from('books').update({
                        'title': titleController.text,
                        'summary': summaryController.text,
                        'cover_image_url': avatarUrl,
                        'updated_at': DateTime.now().toIso8601String(),
                      }).eq('id', book.bookId);
                      
                      await _loadClubBooks(); // Refresh the list
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Book updated successfully')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating book: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRemoveBookDialog(ClubBook book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Delete Book'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this book?',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800]),
            ),
            const SizedBox(height: 8),
            Text('Title: ${book.bookTitle ?? 'Unknown'}'),
            const SizedBox(height: 4),
            Text('Category: ${book.bookCategory ?? 'Unknown'}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will permanently delete the book, PDF file, and cover image.',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Deleting "${book.bookTitle}"...'),
            ],
          ),
        ),
      );

      try {
        await _deleteBookCompletely(book);
        
        // Close loading dialog
        if (mounted) Navigator.pop(context);
        
        // Refresh books list
        await _loadClubBooks();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${book.bookTitle} deleted successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) Navigator.pop(context);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting book: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  // Delete book completely from database and storage
  Future<void> _deleteBookCompletely(ClubBook book) async {
    try {
      List<String> deletionErrors = [];

      // Delete storage files first
      // Delete PDF file if exists
      if (book.bookPdfUrl != null && book.bookPdfUrl!.isNotEmpty) {
        try {
          final pdfFileName = _extractFileNameFromUrl(book.bookPdfUrl!);
          if (pdfFileName != null) {
            await supabase.storage.from('book-pdfs').remove([pdfFileName]);
          }
        } catch (e) {
          deletionErrors.add('PDF file');
        }
      }

      // Delete cover image if exists
      if (book.bookCoverUrl != null && book.bookCoverUrl!.isNotEmpty) {
        try {
          final coverFileName = _extractFileNameFromUrl(book.bookCoverUrl!);
          if (coverFileName != null) {
            await supabase.storage.from('book-covers').remove([coverFileName]);
          }
        } catch (e) {
          deletionErrors.add('Cover image');
        }
      }

      // Delete from club_books table first (due to foreign key constraints)
      await supabase
          .from('club_books')
          .delete()
          .eq('book_id', book.bookId);

      // Then delete from books table
      await supabase
          .from('books')
          .delete()
          .eq('id', book.bookId);

      // Try to decrement books_published count in authors table
      if (book.bookAuthorId != null) {
        try {
          final authorResponse = await supabase
              .from('authors')
              .select('books_published')
              .eq('id', book.bookAuthorId!)
              .maybeSingle();

          if (authorResponse != null) {
            final currentCount = authorResponse['books_published'] ?? 0;
            final newCount = (currentCount > 0) ? currentCount - 1 : 0;
            
            await supabase
                .from('authors')
                .update({'books_published': newCount})
                .eq('id', book.bookAuthorId!);
          }
        } catch (e) {
          // Don't throw error for this, as it's not critical
        }
      }

    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  // Helper method to extract filename from Supabase URL
  String? _extractFileNameFromUrl(String url) {
    try {
      if (url.isEmpty) return null;
      
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // For Supabase storage URLs: /storage/v1/object/public/bucket-name/filename
      if (pathSegments.length >= 5 && pathSegments.contains('storage')) {
        final filename = pathSegments.last;
        return filename;
      }
      
      // Fallback: get last segment
      final filename = pathSegments.isNotEmpty ? pathSegments.last : null;
      return filename;
    } catch (e) {
      return null;
    }
  }

  void _showAddBookDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UploadBookDialog(
        clubId: widget.club.id,
        onBookAdded: _loadClubBooks,
      ),
    );
  }
}

class _UploadBookDialog extends StatefulWidget {
  final String clubId;
  final VoidCallback onBookAdded;

  const _UploadBookDialog({
    required this.clubId,
    required this.onBookAdded,
  });

  @override
  State<_UploadBookDialog> createState() => _UploadBookDialogState();
}

class _UploadBookDialogState extends State<_UploadBookDialog> 
    with TickerProviderStateMixin {
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final summaryController = TextEditingController();
  final languageController = TextEditingController(text: 'English');

  String selectedCategory = 'Fiction';
  bool isPublishing = false;
  String? pdfUrl;
  String? coverImageUrl;
  bool isDropdownOpen = false;

  AnimationController? _dropdownAnimationController;
  Animation<double>? _dropdownAnimation;

  final List<String> categories = [
    'Fiction', 'Non-Fiction', 'Politics & Public Affairs', 'Business', 'Classic',
    'Philosophy', 'Thriller', 'Religion & Spirituality', 'Horror', 
    'Historical Fiction/Novels/Poetry', 'Science', 'IT & Computers', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _dropdownAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dropdownAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dropdownAnimationController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _dropdownAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.upload_file,
                      color: Color(0xFF6C63FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        'Upload New Book',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Add a new book to your club library',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Content
            Expanded(
              child: _buildUploadContent(),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildUploadContent() {
    return Column(
      children: [
        // Form content with scrolling
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Title
                const Text(
                  'Book Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: titleController,
                  label: 'Book Title',
                  hint: 'Enter the book title',
                  required: true,
                  icon: Icons.book,
                ),
                const SizedBox(height: 16),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: priceController,
                        label: 'Price (Optional)',
                        hint: '0.00',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        value: selectedCategory,
                        label: 'Category',
                        items: categories,
                        icon: Icons.category,
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: languageController,
                  label: 'Language',
                  hint: 'Book language',
                  icon: Icons.language,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: summaryController,
                  label: 'Summary (Optional)',
                  hint: 'Brief description of the book',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                
                const SizedBox(height: 24),
                
                // File Upload Section
                const Text(
                  'File Uploads',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                
                // PDF Upload
                _buildFileUploadCard(
                  title: 'PDF File',
                  subtitle: 'Upload your book in PDF format',
                  icon: Icons.picture_as_pdf,
                  color: Colors.red,
                  isUploaded: pdfUrl != null,
                  fileName: pdfUrl != null ? 'PDF uploaded successfully' : null,
                  required: true,
                  onUpload: () async {
                    final url = await _uploadPdfFile();
                    if (url != null) {
                      setState(() {
                        pdfUrl = url;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Cover Image Upload
                _buildFileUploadCard(
                  title: 'Cover Image',
                  subtitle: 'Upload book cover (optional)',
                  icon: Icons.image,
                  color: Colors.green,
                  isUploaded: coverImageUrl != null,
                  fileName: coverImageUrl != null ? 'Cover image uploaded' : null,
                  required: false,
                  onUpload: () async {
                    final url = await _uploadCoverImage();
                    if (url != null) {
                      setState(() {
                        coverImageUrl = url;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        
        // Action Buttons
        Container(
          padding: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: isPublishing ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: (titleController.text.isEmpty || pdfUrl == null || isPublishing)
                      ? null
                      : () async {
                          setState(() {
                            isPublishing = true;
                          });
                          
                          try {
                            final bookData = {
                              'title': titleController.text.trim(),
                              'category': selectedCategory,
                              'price': priceController.text.isNotEmpty 
                                  ? double.tryParse(priceController.text) 
                                  : null,
                              'summary': summaryController.text.trim().isNotEmpty 
                                  ? summaryController.text.trim() 
                                  : null,
                              'language': languageController.text.trim(),
                              'pdf_url': pdfUrl,
                              'cover_image_url': coverImageUrl,
                            };
                            
                            final success = await _saveBookToSupabase(bookData);
                            if (success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Book published and added to club successfully!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              widget.onBookAdded(); // Refresh the list
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            setState(() {
                              isPublishing = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isPublishing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Publish & Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: const Color(0xFF6B7280)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            if (required) ...[
              const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: const Color(0xFF6B7280)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: (newValue) {
              setState(() {
                isDropdownOpen = false;
              });
              _dropdownAnimationController?.reverse();
              onChanged(newValue);
            },
            onTap: () {
              setState(() {
                isDropdownOpen = !isDropdownOpen;
              });
              if (isDropdownOpen) {
                _dropdownAnimationController?.forward();
              } else {
                _dropdownAnimationController?.reverse();
              }
            },
            isExpanded: true,
            selectedItemBuilder: (BuildContext context) {
              return items.map<Widget>((String item) {
                return Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList();
            },
            icon: _dropdownAnimation != null 
                ? AnimatedBuilder(
                    animation: _dropdownAnimation!,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _dropdownAnimation!.value * 3.14159, // 180 degrees in radians
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: isDropdownOpen ? const Color(0xFF6C63FF) : Colors.grey[600],
                        ),
                      );
                    },
                  )
                : Icon(
                    Icons.keyboard_arrow_down,
                    color: isDropdownOpen ? const Color(0xFF6C63FF) : Colors.grey[600],
                  ),
            dropdownColor: Colors.white,
            elevation: 8,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 14,
            ),
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: item == value 
                      ? const Color(0xFF6C63FF).withOpacity(0.1) 
                      : Colors.transparent,
                ),
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: item == value 
                        ? const Color(0xFF6C63FF) 
                        : const Color(0xFF374151),
                    fontWeight: item == value 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                  ),
                ),
              ),
            )).toList(),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDropdownOpen 
                      ? const Color(0xFF6C63FF).withOpacity(0.5) 
                      : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            menuMaxHeight: 200,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isUploaded,
    String? fileName,
    required bool required,
    required VoidCallback onUpload,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isUploaded ? color.withOpacity(0.3) : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: isUploaded ? color.withOpacity(0.05) : Colors.grey[50],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (required) ...[
                            const Text(' *', style: TextStyle(color: Colors.red)),
                          ],
                          if (isUploaded) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.check_circle, color: color, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (isUploaded && fileName != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: onUpload,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Replace',
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onUpload,
                  icon: Icon(Icons.upload_file, size: 16),
                  label: Text(
                    'Upload $title',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final fileName = 'books/${DateTime.now().millisecondsSinceEpoch}_${result.files.first.name}';
        
        final uploadResponse = await Supabase.instance.client.storage
            .from('book-pdfs')
            .upload(fileName, file);

        if (uploadResponse.isNotEmpty) {
          final url = Supabase.instance.client.storage
              .from('book-pdfs')
              .getPublicUrl(fileName);
          return url;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading PDF: $e'), backgroundColor: Colors.red),
      );
    }
    return null;
  }

  Future<String?> _uploadCoverImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final file = File(image.path);
        final fileName = 'book-covers/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        
        final uploadResponse = await Supabase.instance.client.storage
            .from('book-covers')
            .upload(fileName, file);

        if (uploadResponse.isNotEmpty) {
          final url = Supabase.instance.client.storage
              .from('book-covers')
              .getPublicUrl(fileName);
          return url;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e'), backgroundColor: Colors.red),
      );
    }
    return null;
  }

  Future<bool> _saveBookToSupabase(Map<String, dynamic> bookData) async {
    try {
      // Get current user
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Add book to books table
      final bookResponse = await Supabase.instance.client
          .from('books')
          .insert({
            'title': bookData['title'],
            'category': bookData['category'],
            'price': bookData['price'],
            'summary': bookData['summary'],
            'language': bookData['language'],
            'pdf_url': bookData['pdf_url'],
            'cover_image_url': bookData['cover_image_url'],
            'author_id': currentUser.id,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final bookId = bookResponse['id'];

      // Add book to club_books table
      final clubBookResponse = await Supabase.instance.client
          .from('club_books')
          .insert({
            'club_id': widget.clubId,
            'book_id': bookId,
            'access_level': 'free', // or 'premium' based on your business logic
            // added_at will be set automatically by the default value
          });

      if (clubBookResponse != null) {
        throw Exception('Failed to add book to club');
      }

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving book: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }
}
