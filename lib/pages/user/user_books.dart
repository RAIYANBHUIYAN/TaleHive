import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class UserBooksPage extends StatefulWidget {
  const UserBooksPage({Key? key}) : super(key: key);

  @override
  State<UserBooksPage> createState() => _UserBooksPageState();
}

class _UserBooksPageState extends State<UserBooksPage> {
  int _selectedTab = 0;
  bool isLoading = true;
  String error = '';
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> readedBooks = [];
  List<Map<String, dynamic>> requestedBooks = [];
  List<Map<String, dynamic>> downloadedBooks = [];

  @override
  void initState() {
    super.initState();
    fetchAllBooks();
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
    final response = await http.get(Uri.parse('https://openlibrary.org/search.json?q=${Uri.encodeComponent(searchQuery)}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List docs = data['docs'] ?? [];
      return docs.map<Map<String, dynamic>>((doc) => {
        'title': doc['title'] ?? '',
        'author': (doc['author_name'] != null && doc['author_name'].isNotEmpty) ? doc['author_name'][0] : 'Unknown',
        'cover': doc['cover_i'] != null ? 'https://covers.openlibrary.org/b/id/${doc['cover_i']}-L.jpg' : null,
        'rating': 4.0,
        'reviews': 3318,
      }).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }

  List<Map<String, dynamic>> get currentBooks {
    switch (_selectedTab) {
      case 0:
        return readedBooks.length > 25 ? readedBooks.sublist(0, 25) : readedBooks;
      case 1:
        return requestedBooks.length > 25 ? requestedBooks.sublist(0, 25) : requestedBooks;
      case 2:
        return downloadedBooks.length > 25 ? downloadedBooks.sublist(0, 25) : downloadedBooks;
      default:
        return [];
    }
  }

  void _onSearch() {
    fetchAllBooks(_searchText.trim());
  }

  @override
  Widget build(BuildContext context) {
    final tabTitles = [
      'Readed Books',
      'Requested Books',
      'Downloaded Books',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: ListView(
            children: [
              // Search Bar
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            _onSearch();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search books by title, author, or genre',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF0096C7)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        child: const Icon(Icons.search),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Tab Bar (Horizontally scrollable)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(tabTitles.length, (index) {
                    final isSelected = _selectedTab == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTab = index;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF38B000).withOpacity(0.15)
                                : const Color(0xFF0096C7).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF38B000)
                                  : const Color(0xFF0096C7),
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          child: Text(
                            tabTitles[index],
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isSelected
                                  ? const Color(0xFF38B000)
                                  : const Color(0xFF0096C7),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              // Book Grid
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error.isNotEmpty
                      ? Center(
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : currentBooks.isEmpty
                          ? Center(
                              child: Text(
                                'No books found.',
                                style: TextStyle(
                                  color: Colors.blueGrey[400],
                                  fontSize: 18,
                                ),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                int crossAxisCount = 3;
                                if (constraints.maxWidth < 600) {
                                  crossAxisCount = 2;
                                }
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: currentBooks.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 18,
                                    mainAxisSpacing: 18,
                                    childAspectRatio: 0.6,
                                  ),
                                  itemBuilder: (context, index) {
                                    final book = currentBooks[index];
                                    return _BookCard(book: book);
                                  },
                                );
                              },
                            ),
              _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: book['cover'] != null
                  ? Image.network(
                      book['cover'],
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.book, size: 40, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, size: 40, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              book['title'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0096C7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              book['author'],
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${book['rating']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${book['reviews']})',
                  style: TextStyle(
                    color: Colors.blueGrey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: const [
          Divider(),
          SizedBox(height: 8),
          Text(
            'Mr. and His Team COPYRIGHT (C) - 2025. ALL RIGHTS RESERVED',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          SizedBox(height: 4),
        ],
      ),
    );
  }
}
