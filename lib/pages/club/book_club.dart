import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../pages/user/author_dashboard.dart';

class BookClubPage extends StatefulWidget {
  const BookClubPage({Key? key}) : super(key: key);

  @override
  State<BookClubPage> createState() => _BookClubPageState();
}

class _BookClubPageState extends State<BookClubPage> {
  final TextEditingController _searchController = TextEditingController();
  double _minRating = 0.0;

  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;
  String _error = '';
  String _searchText = 'harry potter';

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks([String? query]) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final q = query ?? _searchText;
    try {
      final response = await http.get(Uri.parse('https://openlibrary.org/search.json?q=${Uri.encodeComponent(q)}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List docs = data['docs'] ?? [];
        setState(() {
          _books = docs.map<Map<String, dynamic>>((doc) => {
            'title': doc['title'] ?? '',
            'author': (doc['author_name'] != null && doc['author_name'].isNotEmpty) ? doc['author_name'][0] : 'Unknown',
            'cover': doc['cover_i'] != null ? 'https://covers.openlibrary.org/b/id/${doc['cover_i']}-L.jpg' : null,
            'rating': 4.0, // OpenLibrary does not provide rating
            'description': doc['first_sentence'] ?? '',
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load books.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredBooks {
    if (_minRating == 0.0) {
      return _books;
    }
    return _books.where((book) {
      final matchesRating = (book['rating'] as double) >= _minRating;
      return matchesRating;
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        double localMinRating = _minRating;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 24.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by Minimum Rating',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        Expanded(
                          child: Slider(
                            value: localMinRating,
                            min: 0.0,
                            max: 5.0,
                            divisions: 10,
                            label: localMinRating.toStringAsFixed(1),
                            onChanged: (value) {
                              setModalState(() {
                                localMinRating = value;
                              });
                              setState(() {
                                _minRating = value;
                              });
                            },
                          ),
                        ),
                        Text(localMinRating.toStringAsFixed(1)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          children: [
            // Header Row (avatar + header)
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with border and shadow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF0096C7), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage('Asset/images/parvez.jpg'),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Header section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to TaleHive Book Club',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: const Color(0xFF0096C7),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Discover and discuss books with the community',
                          style: TextStyle(
                            color: Colors.blueGrey[600],
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 80,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0096C7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Search Bar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchText = value;
                          });
                        },
                        onSubmitted: (value) {
                          fetchBooks(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search books by title, author, or genre',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF0096C7),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showFilterSheet,
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Filter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0096C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Book List
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error.isNotEmpty)
              Center(child: Text(_error, style: TextStyle(color: Colors.red)))
            else if (_filteredBooks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    'No books found.',
                    style: TextStyle(color: Colors.blueGrey[400], fontSize: 18),
                  ),
                ),
              )
            else
              ..._filteredBooks.map(
                (book) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              (book['cover'] ?? '') as String,
                              width: 80,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (book['title'] ?? '') as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF0096C7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (book['author'] ?? '') as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${book['rating']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  (book['description'] ?? '') as String,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0096C7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('View'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ).toList(),
            // Navigation Button for testing
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthorDashboardPage()),
                  );
                },
                child: const Text('Go to Author Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
