import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

class AuthorDashboardPage extends StatefulWidget {
  const AuthorDashboardPage({Key? key}) : super(key: key);

  @override
  State<AuthorDashboardPage> createState() => _AuthorDashboardPageState();
}

class _AuthorDashboardPageState extends State<AuthorDashboardPage> {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Google Drive setup - EXACTLY like main_page.dart
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.readonly',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );
  GoogleSignInAccount? _account;

  // Cache for thumbnails to prevent reloading - EXACTLY like main_page.dart
  final Map<String, String> _thumbnailCache = {};

  final author = {
    'name': 'Md Raiyan Buhiyan',
    'bio': 'Award-winning author of modern fiction. Passionate about storytelling and inspiring readers.',
    'avatar': 'Asset/images/loren.jpg',
    'email': 'loreen@email.com',
  };

  List<Map<String, dynamic>> books = [];
  bool _isLoadingBooks = false;

  String search = '';

  @override
  void initState() {
    super.initState();
    _loadBooksFromFirebase();
    _initializeGoogleSignIn();
  }

  // Initialize Google Sign-In - EXACTLY like main_page.dart
  Future<void> _initializeGoogleSignIn() async {
    try {
      // Sign out first to ensure fresh sign-in
      await _googleSignIn.signOut();
      _account = await _googleSignIn.signIn();
      if (_account == null) {
        print('Google Sign-In was cancelled');
      } else {
        print('Signed in as: ${_account!.email}');
      }
    } catch (e) {
      print('Google Sign-In initialization failed: $e');
    }
  }

  // Load books from Firebase
  Future<void> _loadBooksFromFirebase() async {
    setState(() {
      _isLoadingBooks = true;
    });

    try {
      QuerySnapshot querySnapshot = await _firestore.collection('Books').get();
      List<Map<String, dynamic>> loadedBooks = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> bookData = doc.data() as Map<String, dynamic>;
        bookData['id'] = doc.id;
        loadedBooks.add(bookData);
      }

      setState(() {
        books = loadedBooks;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading books: $e')),
      );
    } finally {
      setState(() {
        _isLoadingBooks = false;
      });
    }
  }

  // Validate URL format
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Extract Google Drive file ID from URL
  String? _extractGoogleDriveFileId(String originalLink) {
    String? fileId;
    
    if (originalLink.contains('/file/d/')) {
      // Format: https://drive.google.com/file/d/FILE_ID/view
      final match = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(originalLink);
      fileId = match?.group(1);
    } else if (originalLink.contains('id=')) {
      // Format: https://drive.google.com/open?id=FILE_ID
      final match = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(originalLink);
      fileId = match?.group(1);
    }
    
    return fileId;
  }

  // Convert Google Drive link to direct download link
  String _convertGoogleDriveLink(String originalLink) {
    // If it's already a direct link, return as is
    if (originalLink.contains('drive.google.com/uc?')) {
      return originalLink;
    }
    
    String? fileId = _extractGoogleDriveFileId(originalLink);
    
    if (fileId != null) {
      // Convert to direct download link
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    
    // If we can't extract file ID, return original link
    return originalLink;
  }

  // SINGLE getPdfThumbnail method with caching - EXACTLY like main_page.dart
  Future<String> _getPdfThumbnail(String fileId) async {
    // Check cache first
    if (_thumbnailCache.containsKey(fileId)) {
      return _thumbnailCache[fileId]!;
    }

    try {
      if (_account == null) {
        throw Exception('Not authenticated');
      }
      
      // Get the thumbnail URL from Google Drive - SAME AS MAIN_PAGE.DART
      final thumbnailUrl = 'https://drive.google.com/thumbnail?id=$fileId&sz=w400-h500';
      
      // Verify the thumbnail is accessible
      final response = await http.head(Uri.parse(thumbnailUrl));
      if (response.statusCode == 200) {
        // Cache the successful URL
        _thumbnailCache[fileId] = thumbnailUrl;
        return thumbnailUrl;
      }
      
      throw Exception('Thumbnail not available');
    } catch (e) {
      // If we can't get the thumbnail, throw an exception to trigger the error builder
      throw Exception('Failed to load thumbnail');
    }
  }

  // Save book to Firebase with PDF link and file ID
  Future<bool> _saveBookToFirebase(Map<String, dynamic> bookData) async {
    try {
      print('📚 Starting book save process...');
      
      // Process PDF link
      if (bookData['pdfLink'] != null && bookData['pdfLink'].toString().isNotEmpty) {
        String pdfLink = bookData['pdfLink'].toString().trim();
        
        // Validate URL
        if (!_isValidUrl(pdfLink)) {
          throw Exception('Invalid PDF link format. Please enter a valid URL.');
        }
        
        // Extract Google Drive file ID
        String? fileId = _extractGoogleDriveFileId(pdfLink);
        if (fileId == null) {
          throw Exception('Could not extract Google Drive file ID from the link.');
        }
        
        // Convert Google Drive link if needed
        String processedLink = _convertGoogleDriveLink(pdfLink);
        
        bookData['pdfUrl'] = processedLink;
        bookData['originalPdfLink'] = pdfLink;
        bookData['googleDriveFileId'] = fileId; // Store file ID for thumbnail generation
        bookData['pdfType'] = 'google_drive_link';
        bookData['pdfStatus'] = 'link_provided';
        bookData['pdfMessage'] = 'PDF available via Google Drive link';
        bookData['hasThumbnail'] = true; // We can generate thumbnails from Google Drive
        
        print('✅ PDF link processed: $processedLink');
        print('✅ Google Drive File ID: $fileId');
      }

      // Remove cover image path since we're not using it anymore
      bookData.remove('coverImagePath');

      // Add metadata
      bookData['publishedAt'] = FieldValue.serverTimestamp();
      bookData['authorId'] = author['email'];
      bookData['authorName'] = author['name'];
      bookData['authorEmail'] = author['email'];
      bookData['createdBy'] = author['email'];
      bookData['lastModified'] = FieldValue.serverTimestamp();
      bookData['status'] = 'published';
      bookData['isAvailable'] = true;
      bookData['views'] = 0;
      bookData['downloads'] = 0;
      bookData['storageMethod'] = 'google_drive_with_thumbnails';

      print('💾 Saving book data to Firestore...');
      
      // Save to Firestore
      DocumentReference docRef = await _firestore.collection('Books').add(bookData);
      bookData['id'] = docRef.id;

      print('✅ Book saved successfully with ID: ${docRef.id}');

      // Update local books list
      setState(() {
        books = [bookData, ...books];
      });

      return true;
    } catch (e) {
      print('❌ Error saving book: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving book: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Build book cover from Google Drive thumbnail - EXACTLY like main_page.dart
  Widget _buildBookCover(Map<String, dynamic> book, double width, double height) {
    final fileId = book['googleDriveFileId'];
    
    if (fileId != null && fileId.toString().isNotEmpty) {
      return _buildThumbnailWidget(fileId, width, height);
    }
    
    // Fallback to placeholder
    return _buildDefaultThumbnail(width, height);
  }

  // Build thumbnail widget with caching - EXACTLY like main_page.dart
  Widget _buildThumbnailWidget(String fileId, double width, double height) {
    // Always check cache first and return immediately if found
    if (_thumbnailCache.containsKey(fileId)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _thumbnailCache[fileId]!,
          width: width,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF6C63FF).withOpacity(0.5),
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildDefaultThumbnail(width, height),
        ),
      );
    }

    // Use FutureBuilder if not cached - EXACTLY like main_page.dart
    return _CachedFutureBuilder(
      fileId: fileId,
      width: width,
      height: height,
      thumbnailCache: _thumbnailCache,
      getPdfThumbnail: _getPdfThumbnail,
      buildDefaultThumbnail: () => _buildDefaultThumbnail(width, height),
    );
  }

  // Build default thumbnail placeholder - EXACTLY like main_page.dart
  Widget _buildDefaultThumbnail(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: width * 0.3,
            color: const Color(0xFF6C63FF).withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'PDF',
            style: TextStyle(
              fontSize: width * 0.08,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6C63FF).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Handle PDF viewing from link
  Future<void> _handlePdfView(Map<String, dynamic> book) async {
    if (book['pdfUrl'] != null && book['pdfUrl'].toString().isNotEmpty) {
      try {
        final url = book['pdfUrl'].toString();
        final uri = Uri.parse(url);
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Show PDF details with copy option
          _showPdfDetailsDialog(book);
        }
      } catch (e) {
        print('Error opening PDF: $e');
        _showPdfDetailsDialog(book);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF link available')),
      );
    }
  }

  void _showPdfDetailsDialog(Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('PDF Details - ${book['title'] ?? 'Book'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📄 Type: ${book['pdfType'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('✅ Status: ${book['pdfStatus'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            if (book['googleDriveFileId'] != null)
              Text('🆔 File ID: ${book['googleDriveFileId']}'),
            const SizedBox(height: 8),
            if (book['pdfUrl'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔗 PDF Link:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      book['pdfUrl'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            const Text(
              'Cover image is automatically generated from the PDF\'s first page via Google Drive.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (book['pdfUrl'] != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF link displayed above')),
                );
              }
            },
            child: const Text('Copy Link'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Get unique categories
  Set<String> _getUniqueCategories() {
    return books.map((book) => book['bookType']?.toString() ?? 'Unknown').toSet();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBooks = books
        .where((b) => (b['title'] ?? '').toLowerCase().contains(search.toLowerCase()))
        .toList();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        title: const Text(
          'Author Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Books',
            onPressed: _loadBooksFromFirebase,
          ),
          // Add Google Sign-In status button
          IconButton(
            icon: Icon(
              _account != null ? Icons.account_circle : Icons.account_circle_outlined,
              color: _account != null ? Colors.green : Colors.white,
            ),
            tooltip: _account != null ? 'Signed in: ${_account!.email}' : 'Sign in to Google Drive',
            onPressed: _initializeGoogleSignIn,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit Profile',
            onPressed: () => _showEditProfileDialog(context),
          ),
        ],
      ),
      body: _isLoadingBooks
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading books...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundImage: AssetImage(author['avatar']!),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  author['name']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  author['bio']!,
                                  style: const TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 16, color: Colors.blueGrey),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        author['email']!,
                                        style: const TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Google Drive Status Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _account != null ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _account != null ? Colors.green[200]! : Colors.orange[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _account != null ? Icons.cloud_done : Icons.cloud_off,
                          color: _account != null ? Colors.green[700] : Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _account != null
                                ? 'Google Drive connected: ${_account!.email}. PDF thumbnails will load from first page.'
                                : 'Google Drive not connected. Tap the account icon to sign in for PDF thumbnails.',
                            style: TextStyle(
                              color: _account != null ? Colors.green[700] : Colors.orange[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Publish Book Button
                  ElevatedButton.icon(
                    onPressed: _showPublishBookDialog,
                    icon: const Icon(Icons.add_box_rounded),
                    label: const Text('Publish Book'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Analytics
                  Text(
                    'Analytics Overview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Cards
                  Row(
                    children: [
                      _statCard('Total Books', '${books.length}', Icons.menu_book, Colors.blue),
                      const SizedBox(width: 8),
                      _statCard('Published', '${books.length}', Icons.publish, Colors.green),
                      const SizedBox(width: 8),
                      _statCard('Categories', '${_getUniqueCategories().length}', Icons.category, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Books List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Published Books',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search books...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() => search = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Books List
                  if (filteredBooks.isEmpty)
                    Card(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.library_books, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No books found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start by publishing your first book!',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredBooks.length,
                        separatorBuilder: (context, i) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final book = filteredBooks[i];
                          return Container(
                            padding: const EdgeInsets.all(12), // Add padding around each book item
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Larger book cover with better proportions
                                _buildBookCover(book, 80, 120), // Increased from 48x64 to 80x120
                                const SizedBox(width: 16), // More spacing
                                
                                // Book details - taking up remaining space
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Book title
                                      Text(
                                        book['title'] ?? 'No Title',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Author and details
                                      if (book['author'] != null)
                                        Text(
                                          'Author: ${book['author']}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      
                                      if (book['bookType'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            book['bookType'],
                                            style: TextStyle(
                                              color: Colors.blue[800],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      
                                      // Price and status row
                                      Row(
                                        children: [
                                          if (book['price'] != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '\$${book['price']}',
                                                style: TextStyle(
                                                  color: Colors.green[800],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          
                                          if (book['pdfUrl'] != null)
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
                                                  Icon(Icons.link, size: 12, color: Colors.green[700]),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'PDF',
                                                    style: TextStyle(
                                                      color: Colors.green[700],
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Thumbnail status
                                      if (book['googleDriveFileId'] != null)
                                        Text(
                                          '🖼️ Cover: ${_thumbnailCache.containsKey(book['googleDriveFileId']) ? 'Loaded' : 'Loading...'}',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                
                                // Action buttons column
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (book['pdfUrl'] != null)
                                      IconButton(
                                        icon: const Icon(Icons.launch, color: Colors.green),
                                        tooltip: 'Open PDF',
                                        onPressed: () => _handlePdfView(book),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editBook(book),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteBook(book['id']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  void _editBook(Map<String, dynamic> book) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality to be implemented')),
    );
  }

  Future<void> _deleteBook(String bookId) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('Books').doc(bookId).delete();
        await _loadBooksFromFirebase();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book deleted successfully'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting book: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: author['name']);
        final bioController = TextEditingController(text: author['bio']);
        final emailController = TextEditingController(text: author['email']);
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: bioController, decoration: const InputDecoration(labelText: 'Bio')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  author['name'] = nameController.text;
                  author['bio'] = bioController.text;
                  author['email'] = emailController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showPublishBookDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final authorNameController = TextEditingController(text: author['name']);
    final priceController = TextEditingController();
    final aboutAuthorController = TextEditingController(text: author['bio']);
    final languageController = TextEditingController(text: 'English');
    final summaryController = TextEditingController();
    final pdfLinkController = TextEditingController();

    String selectedBookType = 'Fiction';
    bool isPublishing = false;
    
    final List<String> bookTypes = [
      'Fiction', 'Non-Fiction', 'Science Fiction', 'Fantasy', 'Mystery', 
      'Romance', 'Thriller', 'Biography', 'Self-Help', 'History', 'Science', 'Technology', 'Other'
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Publish New Book'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Upload your book to Google Drive and paste the sharing link below. Cover image will be auto-generated from PDF first page.',
                            style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Google Drive Auth Status
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _account != null ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _account != null ? Colors.green[200]! : Colors.red[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _account != null ? Icons.check_circle : Icons.warning,
                          color: _account != null ? Colors.green[700] : Colors.red[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _account != null
                                ? 'Google Drive connected. Thumbnails will be generated.'
                                : 'Google Drive not connected. Sign in for thumbnails.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _account != null ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ),
                        if (_account == null)
                          TextButton(
                            onPressed: () async {
                              await _initializeGoogleSignIn();
                              setDialogState(() {});
                            },
                            child: const Text('Sign In'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PDF Link Input
                  TextField(
                    controller: pdfLinkController,
                    decoration: InputDecoration(
                      labelText: 'Google Drive PDF Link',
                      hintText: 'https://drive.google.com/file/d/.../view',
                      prefixIcon: const Icon(Icons.link),
                      border: const OutlineInputBorder(),
                      helperText: 'Paste your Google Drive PDF link here',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Form fields
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Book Title')),
                  const SizedBox(height: 8),
                  TextField(controller: authorNameController, decoration: const InputDecoration(labelText: 'Author Name')),
                  const SizedBox(height: 8),
                  TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                  const SizedBox(height: 8),
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price (\$)'), keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  TextField(controller: languageController, decoration: const InputDecoration(labelText: 'Language')),
                  const SizedBox(height: 8),
                  TextField(controller: summaryController, decoration: const InputDecoration(labelText: 'Summary'), maxLines: 2),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: selectedBookType,
                    decoration: const InputDecoration(labelText: 'Book Type'),
                    items: bookTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) => setDialogState(() => selectedBookType = value!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isPublishing ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isPublishing ? null : () async {
                  // Validation
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a book title')),
                    );
                    return;
                  }

                  if (pdfLinkController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a Google Drive PDF link')),
                    );
                    return;
                  }

                  // Validate if it's a Google Drive link
                  final pdfLink = pdfLinkController.text.trim();
                  if (!pdfLink.contains('drive.google.com')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid Google Drive link')),
                    );
                    return;
                  }

                  setDialogState(() => isPublishing = true);

                  final bookData = {
                    'title': titleController.text.trim(),
                    'author': authorNameController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'aboutAuthor': aboutAuthorController.text.trim(),
                    'language': languageController.text.trim(),
                    'summary': summaryController.text.trim(),
                    'bookType': selectedBookType,
                    'pdfLink': pdfLink,
                    'rating': 0.0,
                    'reviewCount': 0,
                  };

                  final success = await _saveBookToFirebase(bookData);

                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📚 Book published successfully! Cover will be auto-generated from PDF first page.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                child: isPublishing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Publish Book', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Cached future builder for thumbnails - EXACTLY like main_page.dart
class _CachedFutureBuilder extends StatefulWidget {
  final String fileId;
  final double width;
  final double height;
  final Map<String, String> thumbnailCache;
  final Future<String> Function(String) getPdfThumbnail;
  final Widget Function() buildDefaultThumbnail;

  const _CachedFutureBuilder({
    required this.fileId,
    required this.width,
    required this.height,
    required this.thumbnailCache,
    required this.getPdfThumbnail,
    required this.buildDefaultThumbnail,
  });

  @override
  __CachedFutureBuilderState createState() => __CachedFutureBuilderState();
}

class __CachedFutureBuilderState extends State<_CachedFutureBuilder> {
  late Future<String> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = widget.getPdfThumbnail(widget.fileId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF6C63FF).withOpacity(0.5),
              ),
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return widget.buildDefaultThumbnail();
        }
        
        // Cache the thumbnail URL
        widget.thumbnailCache[widget.fileId] = snapshot.data!;
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => widget.buildDefaultThumbnail(),
          ),
        );
      },
    );
  }
}


