import 'dart:convert';
import 'dart:math' show log, pow;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../user_authentication/login.dart';
import '../pdf_preview/pdf_preview_screen.dart';
import '../pdf_preview/pdf_web_view_screen.dart';
import '../../admin_authentication/admin_login.dart';


class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Firebase instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for thumbnails to prevent reloading
  final Map<String, String> _thumbnailCache = {};

  String _selectedCategory = 'All';
  List<String> _categories = ['All']; // Will be populated from Firestore data

  // Google Drive setup for thumbnails only
  GoogleSignInAccount? _account;
  List<Map<String, dynamic>> _firestoreBooks = []; // Changed from _drivePdfBooks
  bool _isLoadingBooks = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.readonly',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  // Filtered books based on search and category
  List<Map<String, dynamic>> get _filteredBooks {
    List<Map<String, dynamic>> filtered = _firestoreBooks;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((book) =>
      book['category']?.toLowerCase() == _selectedCategory.toLowerCase()
      ).toList();
    }

    // Filter by search
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((book) =>
      book['title'].toLowerCase().contains(searchQuery) ||
          book['author'].toLowerCase().contains(searchQuery)
      ).toList();
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Load books from Firestore and initialize Google Sign-In for thumbnails
    _loadBooksFromFirestore();
    _initializeGoogleSignIn();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Initialize Google Sign-In for thumbnail generation
  Future<void> _initializeGoogleSignIn() async {
    try {
      _account = await _googleSignIn.signInSilently();
      if (_account == null) {
        print('Google Sign-In not available for thumbnails');
      } else {
        print('Signed in as: ${_account!.email} for thumbnails');
      }
    } catch (e) {
      print('Google Sign-In initialization failed: $e');
    }
  }

  // Load books from Firestore instead of Google Drive
  Future<void> _loadBooksFromFirestore() async {
    if (_isLoadingBooks) return;

    setState(() {
      _isLoadingBooks = true;
    });

    try {
      print('Loading books from Firestore...');

      QuerySnapshot querySnapshot = await _firestore
          .collection('Books')
          .orderBy('publishedAt', descending: true)
          .get();

      List<Map<String, dynamic>> loadedBooks = [];
      Set<String> categories = {'All'};

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> bookData = doc.data() as Map<String, dynamic>;
        bookData['id'] = doc.id;
        
        // Process the book data for display
        Map<String, dynamic> processedBook = _processBookForDisplay(bookData);
        loadedBooks.add(processedBook);
        
        // Collect categories
        if (processedBook['category'] != null && processedBook['category'].toString().trim().isNotEmpty) {
          categories.add(processedBook['category']);
        }
      }

      setState(() {
        _firestoreBooks = loadedBooks;
        _categories = categories.toList()..sort();
      });

      print('Loaded ${_firestoreBooks.length} books from Firestore');

    } catch (error) {
      print('Error loading books from Firestore: $error');
      _showSnackBar('Error loading books: ${error.toString()}');
    } finally {
      setState(() {
        _isLoadingBooks = false;
      });
    }
  }

  // Process book data for display
  Map<String, dynamic> _processBookForDisplay(Map<String, dynamic> bookData) {
    return {
      'id': bookData['id'],
      'title': bookData['title'] ?? 'No Title',
      'author': bookData['author'] ?? bookData['authorName'] ?? '',
      'category': bookData['bookType'] ?? bookData['category'] ?? 'General',
      'rating': bookData['rating']?.toDouble() ?? _generateRating(),
      'price': bookData['price']?.toDouble() ?? 0.0,
      'summary': bookData['summary'] ?? '',
      'language': bookData['language'] ?? 'English',
      'pdfUrl': bookData['pdfUrl'],
      'googleDriveFileId': bookData['googleDriveFileId'],
      'publishedAt': bookData['publishedAt'],
      'authorEmail': bookData['authorEmail'],
      'isAvailable': bookData['isAvailable'] ?? true,
      'views': bookData['views'] ?? 0,
      'downloads': bookData['downloads'] ?? 0,
      'reviewCount': bookData['reviewCount'] ?? 0,
      'fileName': bookData['title'] ?? 'Book',
      'size': '2.5MB', // Default size since we don't store file size
      'modifiedTime': bookData['publishedAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  double _generateRating() {
    return 3.5 + (DateTime.now().millisecondsSinceEpoch % 150) / 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeroSection(),
                  _buildCategoriesSection(),
                  if (_isLoadingBooks) _buildLoadingSection(),
                  if (_firestoreBooks.isNotEmpty) ...[
                    _buildFeaturedBooksSection(),
                    _buildPopularBooksSection(),
                    _buildNewArrivalsSection(),
                  ] else if (!_isLoadingBooks) _buildEmptyState(),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadBooksFromFirestore,
        backgroundColor: const Color(0xFF0096C7),
        child: _isLoadingBooks
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF0096C7),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading books from library...',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching books from Firestore database',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.library_books,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No books in library yet',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Authors can publish books to add them to the library',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0096C7).withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0096C7), Color(0xFF00B4D8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0096C7).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'Asset/images/icon.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.library_books,
                            color: Colors.white,
                            size: 28,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'TaleHive',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3748),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Digital Community ',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showLoginOptionsPopup(), // Change this from _navigateToLogin()
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0096C7),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0096C7).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Login',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0096C7).withOpacity(0.1),
            const Color(0xFF00B4D8).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0096C7).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: _buildSearchBox(),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search  books by title, author...',
          hintStyle: GoogleFonts.montserrat(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 24,
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0096C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              onPressed: () => _performSearch(),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: (value) {
          setState(() {
            // Trigger rebuild to update filtered results
          });
        },
        onSubmitted: (value) => _performSearch(),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Browse by Category',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _selectCategory(category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0096C7) : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0096C7) : Colors.grey[300]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFF0096C7).withOpacity(0.3)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF4A5568),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBooksSection() {
    final books = _filteredBooks.take(4).toList();
    if (books.isEmpty) return const SizedBox.shrink();

    return _buildBookSection(
      title: 'Featured Books',
      books: books,
      showViewAll: true,
    );
  }

  Widget _buildPopularBooksSection() {
    final books = _filteredBooks.skip(4).take(3).toList();
    if (books.isEmpty) return const SizedBox.shrink();

    return _buildBookSection(
      title: 'Popular This Week',
      books: books,
      showViewAll: true,
    );
  }

  Widget _buildNewArrivalsSection() {
    final books = _filteredBooks.skip(7).take(2).toList();
    if (books.isEmpty) return const SizedBox.shrink();

    return _buildBookSection(
      title: 'New Arrivals',
      books: books,
      showViewAll: false,
    );
  }

  Widget _buildBookSection({
    required String title,
    required List<Map<String, dynamic>> books,
    required bool showViewAll,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                if (showViewAll)
                  GestureDetector(
                    onTap: () => _showLoginOptionsPopup(), // Change this from _navigateToLogin()
                    child: Text(
                      'View All',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0096C7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: books.length,
              itemBuilder: (context, index) {
                return _buildBookCard(books[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _showBookDetails(book),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF0096C7).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: _buildThumbnailWidget(book),
              ),
              Expanded( // Add Expanded to prevent overflow
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'] ?? 'No Title',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D3748),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Only show author if it exists and is not empty
                      if (book['author'] != null && book['author'].toString().trim().isNotEmpty)
                        Text(
                          book['author'],
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(), // Push the bottom row to the bottom
                      // Fixed the overflow issue in this Row
                      Row(
                        children: [
                          // Category badge with flexible width
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6, // Reduced padding
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0096C7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10), // Smaller radius
                              ),
                              child: Text(
                                book['category'] ?? 'General',
                                style: GoogleFonts.montserrat(
                                  fontSize: 9, // Smaller font
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF0096C7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4), // Reduced spacing
                          // Rating with flexible width
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14, // Smaller icon
                                  color: Colors.amber[600],
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    book['rating'].toStringAsFixed(1),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11, // Smaller font
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4A5568),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
  }

  // Build thumbnail widget for Firestore books
  Widget _buildThumbnailWidget(Map<String, dynamic> book) {
    final fileId = book['googleDriveFileId'];
    
    if (fileId != null && fileId.toString().isNotEmpty && _account != null) {
      // Check cache first
      if (_thumbnailCache.containsKey(fileId)) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Image.network(
            _thumbnailCache[fileId]!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildDefaultThumbnail(),
          ),
        );
      }

      // Use FutureBuilder for non-cached thumbnails
      return _CachedFutureBuilder(
        fileId: fileId,
        thumbnailCache: _thumbnailCache,
        getPdfThumbnail: _getPdfThumbnail,
        buildDefaultThumbnail: _buildDefaultThumbnail,
      );
    }
    
    // Fallback to default thumbnail
    return _buildDefaultThumbnail();
  }

  Widget _buildDetailsThumbnailWidget(Map<String, dynamic> book) {
    final fileId = book['googleDriveFileId'];
    
    if (fileId != null && fileId.toString().isNotEmpty && _account != null) {
      // Check cache first
      if (_thumbnailCache.containsKey(fileId)) {
        return Image.network(
          _thumbnailCache[fileId]!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFF8FAFC),
            child: _buildDefaultThumbnail(),
          ),
        );
      }

      // Use FutureBuilder if not cached
      return _CachedDetailsFutureBuilder(
        fileId: fileId,
        thumbnailCache: _thumbnailCache,
        getPdfThumbnail: _getPdfThumbnail,
        buildDefaultThumbnail: _buildDefaultThumbnail,
      );
    }
    
    // Fallback to default thumbnail
    return Container(
      color: const Color(0xFFF8FAFC),
      child: _buildDefaultThumbnail(),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0096C7).withOpacity(0.8),
            const Color(0xFF0077B6),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'TaleHive Digital Communitiy',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Discover, Read, Share • ${_firestoreBooks.length} Books Available',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '© 2025 TaleHive Team. All rights reserved.',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Remove this method from main_page.dart:
  void _navigateToAuthorLogin() {
    // DELETE THIS ENTIRE METHOD
  }

  // Add this method to show the login options popup
  void _showLoginOptionsPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0096C7),
                        const Color(0xFF00B4D8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to TaleHive',
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose your login type',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Login options
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Readers option
                      _buildLoginOptionCard(
                        icon: Icons.book_outlined,
                        title: 'Readers',
                        subtitle: 'Explore and read amazing books',
                        gradient: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(  // Add direct navigation here
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const Login(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;
                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Authors option
                      _buildLoginOptionCard(
                        icon: Icons.edit_outlined,
                        title: 'Authors',
                        subtitle: 'Publish and share your stories',
                        gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(  // Use the same login page
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const Login(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;
                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // TaleHive Admin option
                      _buildLoginOptionCard(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'TaleHive',
                        subtitle: 'Manage platform and users',
                        gradient: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToAdminLogin();
                        },
                      ),
                    ],
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Select your role to continue',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to build login option cards
  Widget _buildLoginOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with gradient background
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToAdminLogin() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AdminLogin(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });

  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        // Trigger rebuild to show filtered results
      });
      final count = _filteredBooks.length;
      _showSnackBar('Found $count books matching "$query"');
    }
  }

  Widget _buildMetadataItem({required IconData icon, required String label, Color? iconColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor ?? const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(String sizeString) {
    try {
      final size = int.parse(sizeString);
      if (size < 1024) return '${size}B';
      if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
      if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    } catch (e) {
      return 'Unknown size';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${_getMonthName(date.month)} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildDefaultThumbnail() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 48,
            color: const Color(0xFF0096C7).withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'PDF',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0096C7).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showPdfPreview(Map<String, dynamic> book) async {
    Navigator.pop(context); // Close the book details modal

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
            Text(
              'Loading PDF preview...',
              style: GoogleFonts.montserrat(),
            ),
          ],
        ),
      ),
    );

    try {
      // Get the book ID to fetch fresh data from Firestore
      String bookId = book['id'] ?? '';
      
      if (bookId.isEmpty) {
        Navigator.pop(context);
        _showSnackBar('Book ID not found');
        return;
      }

      print('Fetching book data for ID: $bookId'); // Debug log

      // Fetch fresh data from Firestore to get the pdfLink
      DocumentSnapshot docSnapshot = await _firestore.collection('Books').doc(bookId).get();
      
      if (!docSnapshot.exists) {
        Navigator.pop(context);
        _showSnackBar('Book not found in database');
        return;
      }

      Map<String, dynamic> freshBookData = docSnapshot.data() as Map<String, dynamic>;
      
      // Get the PDF link from Firestore
      String? pdfLink = freshBookData['pdfLink'] ?? freshBookData['pdfUrl'];
      
      print('PDF Link from Firestore: $pdfLink'); // Debug log

      if (pdfLink == null || pdfLink.isEmpty) {
        Navigator.pop(context);
        _showSnackBar('PDF link not available for this book');
        return;
      }

      Navigator.pop(context); // Close loading dialog

      // Check if it's a Google Drive link
      if (pdfLink.contains('drive.google.com')) {
        // Extract file ID from Google Drive URL
        String fileId = '';
        
        if (pdfLink.contains('/file/d/')) {
          fileId = pdfLink.split('/file/d/')[1].split('/')[0];
        } else if (pdfLink.contains('id=')) {
          fileId = pdfLink.split('id=')[1].split('&')[0];
        }
        
        if (fileId.isNotEmpty) {
          // Use WebView for Google Drive PDFs (more reliable)
          final embedUrl = 'https://drive.google.com/file/d/$fileId/preview';
          print('Using WebView for Google Drive PDF: $embedUrl');
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfWebViewScreen(
                pdfUrl: embedUrl,
                bookTitle: book['title'] ?? 'Book Preview',
                author: book['author'] ?? '',
                isPreview: true,
                maxPages: 10, // Add this parameter
              ),
            ),
          );
          return;
        }
      }
      
      // For direct PDF URLs, try using SfPdfViewer
      print('Using SfPdfViewer for direct PDF: $pdfLink');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfUrl: pdfLink,
            bookTitle: book['title'] ?? 'Book Preview',
            author: book['author'] ?? '',
            maxPages: 10,
            isPreview: true,
          ),
        ),
      );

    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Error loading PDF: $e'); // Debug log
      _showSnackBar('Error loading PDF: ${e.toString()}');
    }
  }

  // Show snackbar with message
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF0096C7),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Get PDF thumbnail from Google Drive using file ID
  Future<String> _getPdfThumbnail(String fileId) async {
    // Check cache first
    if (_thumbnailCache.containsKey(fileId)) {
      return _thumbnailCache[fileId]!;
    }

    try {
      if (_account == null) {
        throw Exception('Not authenticated with Google Drive');
      }
      
      // Get the thumbnail URL from Google Drive
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
      throw Exception('Failed to load thumbnail');
    }
  }

  // Show book details with Firestore data
  void _showBookDetails(Map<String, dynamic> book) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: screenHeight * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Cover Image
                    Center(
                      child: Container(
                        width: 200,
                        height: 280,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildDetailsThumbnailWidget(book),
                        ),
                      ),
                    ),
                    
                    // Book Title and Author
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book['title'] ?? 'Untitled',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          if (book['author'] != null && book['author'].toString().trim().isNotEmpty)
                            Text(
                              'by ${book['author']}',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Rating, Category, and Price
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetadataItem(
                            icon: Icons.star,
                            label: '${book['rating']?.toStringAsFixed(1) ?? '4.5'}/5.0',
                            iconColor: const Color(0xFFF59E0B),
                          ),
                          Container(
                            height: 20,
                            width: 1,
                            color: const Color(0xFFE2E8F0),
                          ),
                          _buildMetadataItem(
                            icon: Icons.category_outlined,
                            label: book['category'] ?? 'General',
                          ),
                          Container(
                            height: 20,
                            width: 1,
                            color: const Color(0xFFE2E8F0),
                          ),
                          if (book['price'] != null && book['price'] > 0)
                            _buildMetadataItem(
                              icon: Icons.attach_money,
                              label: '\$${book['price']?.toStringAsFixed(2)}',
                              iconColor: Colors.green,
                            )
                          else
                            _buildMetadataItem(
                              icon: Icons.free_breakfast,
                              label: 'Free',
                              iconColor: Colors.green,
                            ),
                        ],
                      ),
                    ),
                    
                    // Summary Section
                    if (book['summary'] != null && book['summary'].toString().trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Summary',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              book['summary'],
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    
                    // Book Information
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book Information',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Language', book['language'] ?? 'English'),
                          if (book['publishedAt'] != null)
                            _buildInfoRow('Published', _formatDate(book['modifiedTime'])),
                          _buildInfoRow('Availability', book['isAvailable'] == true ? 'Available' : 'Not Available'),
                          if (book['views'] != null)
                            _buildInfoRow('Views', '${book['views']}'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Fixed bottom buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPdfPreview(book),
                      icon: const Icon(Icons.preview, size: 20, color: Colors.white),
                      label: Text(
                        'Preview',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B5563),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close book details first
                        _showLoginOptionsPopup(); // Then show login options
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0096C7),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Login to Read',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Cached future builder for thumbnails - same as before
class _CachedFutureBuilder extends StatefulWidget {
  final String fileId;
  final Map<String, String> thumbnailCache;
  final Future<String> Function(String) getPdfThumbnail;
  final Widget Function() buildDefaultThumbnail;

  const _CachedFutureBuilder({
    required this.fileId,
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
          return Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF0096C7).withOpacity(0.5),
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return widget.buildDefaultThumbnail();
        }
        // Cache the thumbnail URL
        widget.thumbnailCache[widget.fileId] = snapshot.data!;
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Image.network(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => widget.buildDefaultThumbnail(),
          ),
        );
      },
    );
  }
}

// Cached future builder for details thumbnail - same as before
class _CachedDetailsFutureBuilder extends StatefulWidget {
  final String fileId;
  final Map<String, String> thumbnailCache;
  final Future<String> Function(String) getPdfThumbnail;
  final Widget Function() buildDefaultThumbnail;

  const _CachedDetailsFutureBuilder({
    required this.fileId,
    required this.thumbnailCache,
    required this.getPdfThumbnail,
    required this.buildDefaultThumbnail,
  });

  @override
  __CachedDetailsFutureBuilderState createState() => __CachedDetailsFutureBuilderState();
}

class __CachedDetailsFutureBuilderState extends State<_CachedDetailsFutureBuilder> {
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
            color: const Color(0xFFF8FAFC),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0096C7),
                strokeWidth: 2,
              ),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            color: const Color(0xFFF8FAFC),
            child: widget.buildDefaultThumbnail(),
          );
        }
        // Cache the thumbnail URL
        widget.thumbnailCache[widget.fileId] = snapshot.data!;
        return Image.network(
          snapshot.data!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFF8FAFC),
            child: widget.buildDefaultThumbnail(),
          ),
        );
      },
    );
  }
}