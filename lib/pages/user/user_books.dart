import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class UserBooksPage extends StatefulWidget {
  const UserBooksPage({Key? key}) : super(key: key);

  @override
  State<UserBooksPage> createState() => _UserBooksPageState();
}

class _UserBooksPageState extends State<UserBooksPage> with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  bool isLoading = true;
  String error = '';
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> readedBooks = [];
  List<Map<String, dynamic>> requestedBooks = [];
  List<Map<String, dynamic>> downloadedBooks = [];

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingBooks = false;
  List<Map<String, dynamic>> _supabaseBooks = [];

  @override
  void initState() {
    super.initState();
    fetchAllBooks();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMoreBooks();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchAllBooks([String? query]) async {
    setState(() {
      isLoading = true;
      error = '';
    });
    try {
      final readed = await fetchBooks('readed', query);
      final requested = await fetchBooks('requested', query);
      final downloaded = await fetchBooks('downloaded', query);
      setState(() {
        readedBooks = readed;
        requestedBooks = requested;
        downloadedBooks = downloaded;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchBooks(String category, [String? query]) async {
    final searchQuery = query != null && query.isNotEmpty ? query : category;
    try {
      final response = await http.get(
        Uri.parse('https://openlibrary.org/search.json?q=${Uri.encodeComponent(searchQuery)}'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List docs = data['docs'] ?? [];
        return docs.take(25).map<Map<String, dynamic>>((doc) => {
          'title': doc['title'] ?? 'Unknown Title',
          'author': (doc['author_name'] != null && doc['author_name'].isNotEmpty) 
              ? doc['author_name'][0] 
              : 'Unknown Author',
          'cover': doc['cover_i'] != null 
              ? 'https://covers.openlibrary.org/b/id/${doc['cover_i']}-M.jpg' 
              : null,
          'rating': (3.5 + (doc['cover_i'] ?? 0) % 15 / 10).toDouble(),
          'reviews': (doc['edition_count'] ?? 0) * 10 + 100,
        }).toList();
      } else {
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching books: $e');
      throw Exception('Network error: $e');
    }
  }

  List<Map<String, dynamic>> get currentBooks {
    switch (_selectedTab) {
      case 0:
        return readedBooks;
      case 1:
        return requestedBooks;
      case 2:
        return downloadedBooks;
      default:
        return [];
    }
  }

  void _onSearch() {
    if (_searchText.trim().isNotEmpty) {
      fetchAllBooks(_searchText.trim());
    } else {
      fetchAllBooks();
    }
  }

  Future<void> _loadBooksFromSupabase() async {
    setState(() {
      _isLoadingBooks = true;
    });
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      
      // TODO: Replace with actual data fetching logic
      final newBooks = List.generate(10, (index) => {
        'title': 'Supabase Book ${_supabaseBooks.length + index + 1}',
        'author': 'Author ${_supabaseBooks.length + index + 1}',
        'cover': 'https://via.placeholder.com/150',
        'rating': 3.5 + (_supabaseBooks.length + index) % 15 / 10,
        'reviews': (_supabaseBooks.length + index) * 10 + 100,
      });
      
      setState(() {
        _supabaseBooks.addAll(newBooks);
        _isLoadingBooks = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBooks = false;
      });
      // Handle error
    }
  }

  void _loadMoreBooks() {
    if (!_isLoadingBooks) {
      _loadBooksFromSupabase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabTitles = [
      'Read Books',
      'Requested Books',
      'Downloaded Books',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(), // Ensure scrolling
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeroSection(),
                  _buildCategoriesSection(),
                  if (_isLoadingBooks) 
                    Container(
                      height: 100, // Fixed height for loading
                      child: _buildLoadingSection(),
                    ),
                  if (_supabaseBooks.isNotEmpty) ...[
                    _buildFeaturedBooksSection(),
                    _buildPopularBooksSection(),
                    _buildNewArrivalsSection(),
                  ] else if (!_isLoadingBooks) 
                    Container(
                      height: 200, // Fixed height for empty state
                      child: _buildEmptyState(),
                    ),
                  _buildFooter(),
                  const SizedBox(height: 100), // Increased bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadBooksFromSupabase,
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

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      floating: true,
      title: Text(
        'My Books',
        style: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2D3748),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF0096C7)),
          onPressed: () {
            showSearch(
              context: context,
              delegate: BookSearchDelegate(),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_list, color: Color(0xFF0096C7)),
          onPressed: () {
            // TODO: Implement filter action
          },
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 150, // Reduced from 200
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0096C7),
            Color(0xFF00B4D8),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Discover Your Next Great Read',
            style: GoogleFonts.montserrat(
              fontSize: 20, // Reduced from 24
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      'All',
      'Fiction',
      'Non-Fiction',
      'Science',
      'History',
      'Biography',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12), // Reduced from 16
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Categories',
              style: GoogleFonts.montserrat(
                fontSize: 18, // Reduced from 20
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40, // Reduced from 50
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final isSelected = false;
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Implement category filter
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0096C7)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF0096C7),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, // Reduced from 16
                        vertical: 6,    // Reduced from 10
                      ),
                      child: Center(
                        child: Text(
                          categories[index],
                          style: GoogleFonts.montserrat(
                            fontSize: 12, // Reduced from 14
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF0096C7),
                          ),
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

  Widget _buildLoadingSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF0096C7)),
            const SizedBox(height: 16),
            Text(
              'Loading more books...',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0096C7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedBooksSection() {
    return _buildBookSection(
      title: 'Featured Books',
      books: _supabaseBooks,
      showViewAll: true,
    );
  }

  Widget _buildPopularBooksSection() {
    return _buildBookSection(
      title: 'Popular Books',
      books: _supabaseBooks,
      showViewAll: true,
    );
  }

  Widget _buildNewArrivalsSection() {
    return _buildBookSection(
      title: 'New Arrivals',
      books: _supabaseBooks,
      showViewAll: true,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No books found',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for different keywords',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            'TaleHive Team © 2025. All Rights Reserved',
            style: GoogleFonts.montserrat(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
                    fontSize: 20, // Reduced from 24
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                if (showViewAll)
                  GestureDetector(
                    onTap: () => _showLoginOptionsPopup(context),
                    child: Text(
                      'View All',
                      style: GoogleFonts.montserrat(
                        fontSize: 14, // Reduced from 16
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0096C7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12), // Reduced from 16
          // Fixed height container - significantly reduced
          SizedBox(
            height: 260, // Reduced from 280 (160 + 100)
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
              // Book Cover - Fixed height
              Container(
                height: 160, // Reduced height
                decoration: BoxDecoration(
                  color: const Color(0xFF0096C7).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: _buildBookCover(book),
                ),
              ),
              
              // Book Info - Fixed height container
              Container(
                height: 100, // Fixed height for info section
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title - Fixed height
                    Container(
                      height: 28, // Fixed height for title
                      child: Text(
                        book['title'] ?? 'No Title',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D3748),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Author - Fixed height
                    Container(
                      height: 14,
                      child: Text(
                        book['author'] ?? 'Unknown Author',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Rating row - Fixed height
                    Container(
                      height: 18,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0096C7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                book['category'] ?? 'General',
                                style: GoogleFonts.montserrat(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF0096C7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber[600],
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    book['rating'].toStringAsFixed(1),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 9,
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ));
    }
  }

  Widget _buildBookCover(Map<String, dynamic> book) {
    return book['cover'] != null
        ? Image.network(
            book['cover'],
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0096C7),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.book,
                size: 32,
                color: Colors.grey,
              ),
            ),
          )
        : Container(
            color: Colors.grey[200],
            child: const Icon(
              Icons.book,
              size: 32,
              color: Colors.grey,
            ),
          );
  }

  void _showBookDetails(Map<String, dynamic> book) {
    // Navigate to book details page
    // Implement navigation to book details screen
  }

  void _showLoginOptionsPopup(BuildContext context) {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All Books',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Implement view all action
                  },
                  child: Text(
                    'View All Featured Books',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0096C7),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Implement view all action
                  },
                  child: Text(
                    'View All Popular Books',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0096C7),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Implement view all action
                  },
                  child: Text(
                    'View All New Arrivals',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0096C7),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }


class BookSearchDelegate extends SearchDelegate {
  final List<String> _bookSuggestions = [
    'The Great Gatsby',
    'To Kill a Mockingbird',
    '1984',
    'Pride and Prejudice',
    'The Catcher in the Rye',
    'The Hobbit',
    'Fahrenheit 451',
    'Brave New World',
    'The Grapes of Wrath',
    'The Picture of Dorian Gray',
  ];

  @override
  String get searchFieldLabel => 'Search books, authors, genres...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: Implement search results
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? _bookSuggestions
        : _bookSuggestions.where((book) => book.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            suggestions[index],
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D3748),
            ),
          ),
          onTap: () {
            // TODO: Implement book selection
          },
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            'TaleHive Team © 2025. All Rights Reserved',
            style: GoogleFonts.montserrat(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
