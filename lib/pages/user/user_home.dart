import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'book_details.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  List<Map<String, dynamic>> newArrivals = [];
  List<Map<String, dynamic>> recommended = [];
  List<Map<String, dynamic>> popularBooks = [];
  List<Map<String, dynamic>> recentReadings = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchAllBooks();
  }

  Future<void> fetchAllBooks() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    try {
      final arrivals = await fetchBooks('new');
      final recs = await fetchBooks('recommended');
      final popular = await fetchBooks('popular');
      final recent = await fetchBooks('recent');
      setState(() {
        newArrivals = arrivals;
        recommended = recs;
        popularBooks = popular;
        recentReadings = recent;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchBooks(String query) async {
    final response = await http.get(Uri.parse('https://openlibrary.org/search.json?q=${Uri.encodeComponent(query)}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List docs = data['docs'] ?? [];
      return docs.map<Map<String, dynamic>>((doc) => {
        'title': doc['title'] ?? '',
        'author': (doc['author_name'] != null && doc['author_name'].isNotEmpty) ? doc['author_name'][0] : 'Unknown',
        'cover': doc['cover_i'] != null ? 'https://covers.openlibrary.org/b/id/${doc['cover_i']}-L.jpg' : null,
        'rating': 4.0,
      }).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = ' Nahid ';
    final quotes = [
      "There is more treasure in books than in all the pirate's loot on Treasure Island. - Walt Disney",
      "A room without books is like a body without a soul. - Cicero",
      "Books are a uniquely portable magic. - Stephen King",
    ];
    final onlineUsers = ['Noushin Nurjahan', 'Other users (?)', 'User 3'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error.isNotEmpty
                ? Center(child: Text(error, style: TextStyle(color: Colors.red)))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 1100;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main Content
                          Expanded(
                            flex: 4,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              children: [
                                // Greeting Banner
                                _GreetingBanner(userName: userName),
                                const SizedBox(height: 18),
                                // Quote/Highlight Section
                                _QuoteCarousel(quotes: quotes),
                                const SizedBox(height: 18),
                                // New Releases & Arrivals
                                _SectionTitle(title: 'New Releases'),
                                _HorizontalBookList(books: newArrivals, label: 'New Arrivals'),
                                const SizedBox(height: 18),
                                // Recommended For You
                                _SectionTitle(title: 'Recommended for You'),
                                _RecommendedList(books: recommended),
                                const SizedBox(height: 18),
                                // Popular Books
                                _SectionTitle(title: 'Popular Books'),
                                _HorizontalBookList(books: popularBooks),
                                const SizedBox(height: 18),
                                // Recent Readings
                                _SectionTitle(title: 'Recent Readings'),
                                _RecentReadingsList(books: recentReadings),
                                const SizedBox(height: 18),
                                // Special Club Banner
                                _BookClubBanner(),
                                const SizedBox(height: 18),
                                // Footer
                                _Footer(),
                                const SizedBox(height: 18),
                                // Navigation Button for testing
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookDetailsPage(bookId: '123'), // Provide a valid bookId here
                                        ),
                                      );
                                    },
                                    child: const Text('Go to Book Details'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Sidebar Widgets
                          if (isWide)
                            SizedBox(
                              width: 300,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(top: 32, right: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _OnlineUsersWidget(users: onlineUsers),
                                    const SizedBox(height: 24),
                                    // Add more sidebar widgets here if needed
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}

// --- Components ---

class _GreetingBanner extends StatelessWidget {
  final String userName;
  const _GreetingBanner({required this.userName});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0096C7),
        borderRadius: BorderRadius.circular(18),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=800&q=80',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Color(0xAA0096C7), BlendMode.srcATop),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and Name Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: AssetImage('Asset/images/nahid.jpg'),
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good morning,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    userName.trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Start your day with a book',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Request for a BOOK? or Search...',
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
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0096C7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  elevation: 2,
                ),
                child: const Text('Search'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuoteCarousel extends StatefulWidget {
  final List<String> quotes;
  const _QuoteCarousel({required this.quotes});
  @override
  State<_QuoteCarousel> createState() => _QuoteCarouselState();
}

class _QuoteCarouselState extends State<_QuoteCarousel> {
  int _current = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFB5179E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.quotes[_current],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.quotes.length,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _current
                    ? const Color(0xFFB5179E)
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(
                () => _current =
                    (_current - 1 + widget.quotes.length) %
                    widget.quotes.length,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(
                () => _current = (_current + 1) % widget.quotes.length,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Color(0xFF22223b),
        ),
      ),
    );
  }
}

class _HorizontalBookList extends StatelessWidget {
  final List<Map<String, dynamic>> books;
  final String? label;
  const _HorizontalBookList({required this.books, this.label});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, i) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final book = books[i];
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Container(
              height: 140,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (label != null && i == 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB5179E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: book['cover'] != null
                          ? Image.network(
                              book['cover'],
                              width: 70,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 70,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.book, size: 40, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 70,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.book, size: 40, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 90,
                      child: Text(
                        book['title'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecommendedList extends StatelessWidget {
  final List<Map<String, dynamic>> books;
  const _RecommendedList({required this.books});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, i) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final book = books[i];
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: book['cover'] != null
                          ? Image.network(
                              book['cover'],
                              width: 70,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 70,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.book, size: 40, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 70,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.book, size: 40, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      book['author'],
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        Text(
                          '${book['rating']}',
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Color(0xFFB5179E),
                      ),
                      onPressed: () {},
                      tooltip: 'Add to Favorites',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecentReadingsList extends StatelessWidget {
  final List<Map<String, dynamic>> books;
  const _RecentReadingsList({required this.books});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, i) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final book = books[i];
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Container(
              height: 140,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: book['cover'] != null
                          ? Image.network(
                              book['cover'],
                              width: 60,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 60,
                                height: 70,
                                color: Colors.grey[300],
                                child: const Icon(Icons.book, size: 35, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 70,
                              color: Colors.grey[300],
                              child: const Icon(Icons.book, size: 35, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      book['author'],
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        Text(
                          '${book['rating']}',
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookClubBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1516979187457-637abb4f9353?auto=format&fit=crop&w=800&q=80',
          ),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'TaleHive Book Club',
                style: TextStyle(
                  color: Color(0xFF0096C7),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineUsersWidget extends StatelessWidget {
  final List<String> users;
  const _OnlineUsersWidget({required this.users});
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Online users',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...users.map(
              (u) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 10),
                    const SizedBox(width: 8),
                    Text(u, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
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
