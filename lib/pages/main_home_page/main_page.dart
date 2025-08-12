import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../user_authentication/login.dart';
import '../pdf_preview/pdf_preview_screen.dart';

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

  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All', 'Fiction', 'Science', 'Technology', 'History',
    'Biography', 'Children', 'Romance', 'Mystery', 'Fantasy'
  ];

  // Google Drive setup - FIXED
  GoogleSignInAccount? _account;
  List<Map<String, dynamic>> _drivePdfBooks = [];
  bool _isLoadingBooks = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.readonly',
      'https://www.googleapis.com/auth/drive.file',
    ],
    // Remove clientId for Android - it's handled by google-services.json
  );

  final String folderId = '11WvDmk6I3h11tNLWAn-lFBJRcpqw1Sw7';

  // Filtered books based on search and category
  List<Map<String, dynamic>> get _filteredBooks {
    List<Map<String, dynamic>> filtered = _drivePdfBooks;

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

    // Auto-load books on init
    _loadBooksFromDrive();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBooksFromDrive() async {
    if (_isLoadingBooks) return;

    setState(() {
      _isLoadingBooks = true;
    });

    try {
      print('Starting Google Sign-In...');

      // Sign out first to ensure fresh sign-in
      await _googleSignIn.signOut();

      // Sign in with user interaction
      _account = await _googleSignIn.signIn();

      if (_account == null) {
        _showSnackBar('Sign-in was cancelled');
        return;
      }

      print('Signed in as: ${_account!.email}');

      // Get authentication headers
      final authHeaders = await _account!.authHeaders;
      print('Auth headers obtained');

      if (!authHeaders.containsKey('Authorization')) {
        _showSnackBar('Failed to get authorization token');
        return;
      }

      final client = http.Client();

      // First, let's check if we can access the folder
      print('Checking folder access...');
      final folderResponse = await client.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files/$folderId'),
        headers: {
          'Authorization': authHeaders['Authorization']!,
          'Content-Type': 'application/json',
        },
      );

      print('Folder check response: ${folderResponse.statusCode}');

      if (folderResponse.statusCode != 200) {
        _showSnackBar('Cannot access the folder. Please check permissions.');
        return;
      }

      // Fetch files from the specific folder
      print('Fetching files from folder...');
      final response = await client.get(
        Uri.parse(
            'https://www.googleapis.com/drive/v3/files?q=\'$folderId\'+in+parents+and+mimeType=\'application/pdf\'&fields=files(id,name,webViewLink,thumbnailLink,size,modifiedTime)'
        ),
        headers: {
          'Authorization': authHeaders['Authorization']!,
          'Content-Type': 'application/json',
        },
      );

      print('Files response status: ${response.statusCode}');
      print('Files response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final files = responseData['files'] as List? ?? [];

        print('Found ${files.length} PDF files');

        if (files.isEmpty) {
          _showSnackBar('No PDF files found in the specified folder');
          return;
        }

        setState(() {
          _drivePdfBooks = files.map((file) {
            final fileName = file['name'] as String;
            final bookInfo = _parseBookInfo(fileName);

            return {
              'id': file['id'],
              'title': bookInfo['title'],
              'author': bookInfo['author'],
              'category': bookInfo['category'],
              'rating': _generateRating(),
              'webViewLink': file['webViewLink'],
              'thumbnailLink': file['thumbnailLink'],
              'size': file['size'],
              'modifiedTime': file['modifiedTime'],
              'fileName': fileName,
            };
          }).toList();
        });

        _showSnackBar('Successfully loaded ${_drivePdfBooks.length} books!');
      } else {
        _showSnackBar('Failed to load books: HTTP ${response.statusCode}');
      }
    } catch (error) {
      print('Detailed error loading books: $error');
      _showSnackBar('Error: ${error.toString()}');
    } finally {
      setState(() {
        _isLoadingBooks = false;
      });
    }
  }

  Map<String, String> _parseBookInfo(String fileName) {
    // Remove .pdf extension
    String cleanName = fileName.replaceAll('.pdf', '');

    // Try to extract title and author from filename
    // Common patterns: "Title - Author", "Title by Author", "Author - Title"
    String title = cleanName;
    String author = 'Unknown Author';
    String category = _categories[1 + (cleanName.hashCode % (_categories.length - 1))]; // Random category except 'All'

    if (cleanName.contains(' - ')) {
      final parts = cleanName.split(' - ');
      if (parts.length >= 2) {
        title = parts[0].trim();
        author = parts[1].trim();
      }
    } else if (cleanName.contains(' by ')) {
      final parts = cleanName.split(' by ');
      if (parts.length >= 2) {
        title = parts[0].trim();
        author = parts[1].trim();
      }
    }

    return {
      'title': title,
      'author': author,
      'category': category,
    };
  }

  double _generateRating() {
    // Generate a random rating between 3.5 and 5.0
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
                  if (_drivePdfBooks.isNotEmpty) ...[
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
        onPressed: _loadBooksFromDrive,
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
            'Loading books from Google Drive...',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please sign in when prompted',
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
            'No books loaded yet',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the refresh button to sign in and load books from Google Drive',
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
                          'Discover your next great read',
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
                    onTap: () => _navigateToLogin(),
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
                        'My Books',
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
          hintText: 'Search by title, author...',
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
                    onTap: () => _navigateToLogin(),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0096C7).withOpacity(0.1),
                      Colors.grey[100]!,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        size: 48,
                        color: const Color(0xFF0096C7),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PDF',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              book['title'],
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3748),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              book['author'],
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            book['rating'].toStringAsFixed(1),
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4A5568),
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
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2D3748),
            const Color(0xFF1A202C),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0096C7), Color(0xFF00B4D8)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'Asset/images/icon.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.library_books,
                        color: Colors.white,
                        size: 24,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'TaleHive',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your gateway to our curated PDF book collection.',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              _buildFooterLink('About'),
              _buildFooterLink('Contact'),
              _buildFooterLink('Privacy'),
              _buildFooterLink('Terms'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '© 2025 Mr and His Team. All rights reserved.',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          color: Colors.grey[300],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.push(
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
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _showSnackBar('Showing books in $category category');
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        // Trigger rebuild to show filtered results
      });
      _showSnackBar('Searching for "$query"...');
    }
  }

  void _showBookDetails(Map<String, dynamic> book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0096C7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    size: 32,
                    color: const Color(0xFF0096C7),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'],
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${book['author']}',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 20),
                const SizedBox(width: 4),
                Text(
                  book['rating'].toStringAsFixed(1),
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Chip(
                  label: Text(
                    book['category'],
                    style: GoogleFonts.montserrat(fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFF0096C7).withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'File Info',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Original filename: ${book['fileName']}',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (book['size'] != null)
              Text(
                'File size: ${_formatFileSize(book['size'])}',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'About this book',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This PDF book is from our Google Drive collection. Login to read the full content and access our complete library.',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPdfPreview(book),
                    icon: const Icon(Icons.preview, color: Colors.white),
                    label: Text(
                      'Preview',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToLogin();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0096C7),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Login to Read',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      // Download PDF from Google Drive
      final pdfPath = await _downloadPdfFromDrive(book['id']);

      if (pdfPath != null) {
        Navigator.pop(context); // Close loading dialog

        // Navigate to PDF preview screen with 10-page limit
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfPath: pdfPath,
              bookTitle: book['title'],
              maxPages: 10,
            ),
          ),
        );
      } else {
        Navigator.pop(context); // Close loading dialog
        _showSnackBar('Failed to load PDF preview');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showSnackBar('Error loading PDF: ${e.toString()}');
    }
  }

  Future<String?> _downloadPdfFromDrive(String fileId) async {
    try {
      if (_account == null) {
        _showSnackBar('Please sign in to preview books');
        return null;
      }

      final authHeaders = await _account!.authHeaders;
      final client = http.Client();

      // Download the PDF file
      final response = await client.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media'),
        headers: {
          'Authorization': authHeaders['Authorization']!,
        },
      );

      if (response.statusCode == 200) {
        // Save to temporary directory
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/preview_$fileId.pdf');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        print('Failed to download PDF: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      return null;
    }
  }

  void _openBookInBrowser(Map<String, dynamic> book) async {
    final url = book['webViewLink'];
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open book');
      }
    }
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(),
        ),
        backgroundColor: const Color(0xFF0096C7),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}