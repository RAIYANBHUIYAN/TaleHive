import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

// --- ENUMS for State Management ---
// Using enums for state management improves type safety and readability
// compared to using booleans or integers.

/// Represents the current data fetching state of the page.
enum PageState {
  loading,
  success,
  error,
  empty,
}

/// Represents the categories of books a user can view.
enum BookCategory {
  readed,
  requested,
  downloaded,
}

// --- DATA MODEL ---
// A dedicated data model for books. This makes the code type-safe and
// prevents potential runtime errors that can occur when using raw Maps.
class BookModel {
  final String title;
  final String author;
  final String? coverUrl;
  final double rating;
  final int reviews;

  /// Constructs a [BookModel].
  BookModel({
    required this.title,
    required this.author,
    this.coverUrl,
    required this.rating,
    required this.reviews,
  });

  /// A factory constructor to create a [BookModel] instance from a JSON map.
  ///
  /// This is a robust way to parse data from an API response. It handles
  /// missing fields gracefully by providing default values.
  factory BookModel.fromApiJson(Map<String, dynamic> doc) {
    // Safely extract the title.
    final String title = doc['title'] ?? 'Untitled';

    // Safely extract the author's name from a list of authors.
    final String author = (doc['author_name'] != null &&
            (doc['author_name'] as List).isNotEmpty)
        ? doc['author_name'][0]
        : 'Unknown Author';

    // Construct the cover image URL if a cover ID is available.
    final String? coverUrl = doc['cover_i'] != null
        ? 'https://covers.openlibrary.org/b/id/${doc['cover_i']}-L.jpg'
        : null;

    // Provide default values for rating and reviews as they are not in the API.
    const double rating = 4.0;
    const int reviews = 3318;

    return BookModel(
      title: title,
      author: author,
      coverUrl: coverUrl,
      rating: rating,
      reviews: reviews,
    );
  }
}

// --- SERVICE LAYER ---
// A dedicated service class for handling API requests. This separates the
// data fetching logic from the UI logic, making the code cleaner and easier
// to test and maintain.
class OpenLibraryService {
  /// The base URL for the Open Library Search API.
  static const String _baseUrl = 'https://openlibrary.org/search.json';

  /// Fetches a list of books from the Open Library API based on a search query.
  ///
  /// [query] is the search term used to find books.
  /// Returns a `Future` that completes with a list of [BookModel].
  /// Throws an [Exception] if the network request fails.
  Future<List<BookModel>> fetchBooksByQuery(String query) async {
    // If the query is empty, it's better to return an empty list
    // than to make a network request that will likely fail or return junk.
    if (query.isEmpty) {
      return [];
    }

    // Construct the final URL with the encoded search query.
    final Uri requestUri =
        Uri.parse('$_baseUrl?q=${Uri.encodeComponent(query)}');

    try {
      // Make the HTTP GET request.
      final http.Response response = await http.get(requestUri);

      // Check if the request was successful.
      if (response.statusCode == 200) {
        // Decode the JSON response body.
        final Map<String, dynamic> data = json.decode(response.body);
        // Safely access the 'docs' list from the response.
        final List docs = data['docs'] ?? [];
        // Map the list of JSON objects to a list of BookModel instances.
        return docs.map((doc) => BookModel.fromApiJson(doc)).toList();
      } else {
        // If the server did not return a 200 OK response, throw an exception.
        throw Exception(
            'Failed to load books. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Catch any other exceptions (e.g., network errors) and re-throw.
      throw Exception('Failed to fetch books: $e');
    }
  }
}

/// The main page that displays a user's book collections.
///
/// This stateful widget manages the fetching of book data, the selection
/// of book categories (tabs), and the display of books in a responsive grid.
class UserBooksPage extends StatefulWidget {
  const UserBooksPage({Key? key}) : super(key: key);

  @override
  State<UserBooksPage> createState() => _UserBooksPageState();
}

class _UserBooksPageState extends State<UserBooksPage> {
  // --- State Variables ---

  /// The service responsible for fetching book data.
  final OpenLibraryService _bookService = OpenLibraryService();

  /// The current state of the page (loading, success, error, etc.).
  PageState _pageState = PageState.loading;

  /// An error message to display if data fetching fails.
  String _errorMessage = '';

  /// The currently selected book category tab.
  BookCategory _selectedCategory = BookCategory.readed;

  /// Controller for the search input field.
  final TextEditingController _searchController = TextEditingController();

  /// A map to hold the lists of books for each category.
  final Map<BookCategory, List<BookModel>> _bookLists = {
    BookCategory.readed: [],
    BookCategory.requested: [],
    BookCategory.downloaded: [],
  };

  @override
  void initState() {
    super.initState();
    // Fetch initial data when the widget is first created.
    _fetchAllBookCategories();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is removed from the tree.
    _searchController.dispose();
    super.dispose();
  }

  // --- Data Fetching Logic ---

  /// Fetches book data for all categories concurrently.
  ///
  /// Optionally accepts a [searchQuery] to fetch specific books. If the
  /// query is null, it fetches default content for each category.
  Future<void> _fetchAllBookCategories([String? searchQuery]) async {
    // Set the page state to loading before starting the network requests.
    setState(() {
      _pageState = PageState.loading;
      _errorMessage = '';
    });

    try {
      // Use Future.wait to run all API calls in parallel for better performance.
      final results = await Future.wait([
        _bookService.fetchBooksByQuery(
            searchQuery ?? BookCategory.readed.name),
        _bookService.fetchBooksByQuery(
            searchQuery ?? BookCategory.requested.name),
        _bookService.fetchBooksByQuery(
            searchQuery ?? BookCategory.downloaded.name),
      ]);

      // After fetching, update the state with the new data.
      setState(() {
        _bookLists[BookCategory.readed] = results[0];
        _bookLists[BookCategory.requested] = results[1];
        _bookLists[BookCategory.downloaded] = results[2];
        _pageState = PageState.success;
      });
    } catch (e) {
      // If any error occurs, update the state to show the error message.
      setState(() {
        _pageState = PageState.error;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  // --- Getters and Event Handlers ---

  /// Returns the list of books for the currently selected tab.
  /// It also limits the number of books displayed to 25.
  List<BookModel> get _currentVisibleBooks {
    final List<BookModel> bookList = _bookLists[_selectedCategory] ?? [];
    return bookList.length > 25 ? bookList.sublist(0, 25) : bookList;
  }

  /// Handles the search action.
  ///
  /// Triggers a new data fetch using the text from the search controller.
  void _onSearch() {
    // Hide the keyboard.
    FocusScope.of(context).unfocus();
    // Fetch books based on the search text.
    _fetchAllBookCategories(_searchController.text.trim());
  }

  /// Handles tab selection.
  ///
  /// Updates the [_selectedCategory] state when a user taps on a new tab.
  void _onTabSelected(BookCategory category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  // --- Build Method and UI Helpers ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          // Using a ListView to allow the content to be scrollable.
          child: ListView(
            children: [
              // The search bar at the top of the page.
              _buildSearchBar(),
              const SizedBox(height: 18),

              // The horizontally scrollable tab bar.
              _buildTabBar(),
              const SizedBox(height: 24),

              // The main content body, which shows a loader, error, or book grid.
              _buildContentBody(),

              // The footer at the bottom of the page.
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the search bar widget.
  Widget _buildSearchBar() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _onSearch(),
                decoration: InputDecoration(
                  hintText: 'Search books by title, author, or genre',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF0096C7)),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0096C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              child: const Icon(Icons.search),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the horizontally scrollable tab bar for book categories.
  Widget _buildTabBar() {
    final Map<BookCategory, String> tabTitles = {
      BookCategory.readed: 'Readed Books',
      BookCategory.requested: 'Requested Books',
      BookCategory.downloaded: 'Downloaded Books',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: BookCategory.values.map((category) {
          return _buildTabItem(
            title: tabTitles[category]!,
            category: category,
            isSelected: _selectedCategory == category,
          );
        }).toList(),
      ),
    );
  }

  /// Builds a single item for the tab bar.
  Widget _buildTabItem({
    required String title,
    required BookCategory category,
    required bool isSelected,
  }) {
    // Define colors based on selection state for better visual feedback.
    final Color selectedColor = const Color(0xFF38B000);
    final Color defaultColor = const Color(0xFF0096C7);
    final Color activeColor = isSelected ? selectedColor : defaultColor;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _onTabSelected(category),
        child: Container(
          decoration: BoxDecoration(
            color: activeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: activeColor, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            title,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: activeColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the main content area based on the current page state.
  Widget _buildContentBody() {
    switch (_pageState) {
      case PageState.loading:
        return _buildLoadingIndicator();
      case PageState.error:
        return _buildErrorState();
      case PageState.success:
        return _currentVisibleBooks.isEmpty
            ? _buildEmptyState()
            : _buildBookGrid();
      case PageState.empty:
        return _buildEmptyState();
    }
  }

  /// Builds the loading indicator widget.
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 50.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Builds the widget to display when an error occurs.
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50.0),
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Builds the widget to display when no books are found.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50.0),
        child: Text(
          'No books found in this category.',
          style: TextStyle(color: Colors.blueGrey[400], fontSize: 18),
        ),
      ),
    );
  }

  /// Builds the grid of book cards.
  Widget _buildBookGrid() {
    // Use a LayoutBuilder to make the grid responsive to screen width.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine the number of columns based on the available width.
        final int crossAxisCount = constraints.maxWidth < 600 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _currentVisibleBooks.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 0.6, // Adjust this for desired card proportions
          ),
          itemBuilder: (context, index) {
            final book = _currentVisibleBooks[index];
            return _BookCard(book: book);
          },
        );
      },
    );
  }
}

/// A card widget to display a single book's information.
class _BookCard extends StatelessWidget {
  final BookModel book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Book Cover Image ---
            _buildBookCover(),
            const SizedBox(height: 12),

            // --- Book Title ---
            Text(
              book.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0096C7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // --- Author Name ---
            Text(
              book.author,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(), // Use a spacer to push the rating to the bottom.

            // --- Rating and Reviews ---
            _buildRatingInfo(),
          ],
        ),
      ),
    );
  }

  /// Helper method to build the book cover image with a placeholder.
  Widget _buildBookCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: book.coverUrl != null
          ? Image.network(
              book.coverUrl!,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              // A builder that shows a loading indicator while the image loads.
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 120,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              // A builder that shows a placeholder icon if the image fails to load.
              errorBuilder: (context, error, stackTrace) =>
                  _buildCoverPlaceholder(),
            )
          : _buildCoverPlaceholder(),
    );
  }

  /// Builds the placeholder for the book cover.
  Widget _buildCoverPlaceholder() {
    return Container(
      width: double.infinity,
      height: 120,
      color: Colors.grey[300],
      child: const Icon(Icons.book, size: 40, color: Colors.grey),
    );
  }

  /// Helper method to build the rating and review count row.
  Widget _buildRatingInfo() {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text(
          '${book.rating}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(width: 8),
        Text(
          '(${book.reviews})',
          style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
        ),
      ],
    );
  }
}

/// A simple footer widget for the bottom of the page.
class _Footer extends StatelessWidget {
  const _Footer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This widget provides a consistent footer across different pages.
    // It's good practice to encapsulate reusable UI elements like this.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Divider(thickness: 1.0),
          const SizedBox(height: 16),
          // --- Copyright Notice ---
          // In a real app, this might be dynamically generated with the current year.
          const Text(
            'Mr. and His Team COPYRIGHT (C) - 2025. ALL RIGHTS RESERVED',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          // --- Additional Footer Links (Placeholder) ---
          // You could add links to Terms of Service, Privacy Policy, etc. here.
          // For now, they are just placeholders to show where they would go.
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Text('Privacy Policy', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
          //     SizedBox(width: 16),
          //     Text('Contact Us', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
          //   ],
          // ),
        ],
      ),
    );
  }
}