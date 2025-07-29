import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookDetailsPage extends StatelessWidget {
  const BookDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final book = {
      'title': "There's a Million Books I Haven't Read, but Just You",
      'author': 'Author Name',
      'cover': 'https://covers.openlibrary.org/b/id/10523338-L.jpg',
      'rating': 4.5,
      'ratingsCount': 8564,
      'reviewsCount': 796,
      'description':
          "This book was pure magic. The Night Circus is unlike anything I've ever read—ambition, forbidden love, and competition entwined. The story follows a secret competition between two young magicians, Celia and her father, who are bound by a black-and-white circus that only appears at night, enchanting visitors with its mysterious acts.",
      'genres': ['Fiction', 'Fantasy', 'Magic', 'Adventure', 'Romance'],
      'pages': 432,
      'language': 'English',
      'isbn': '1234567890',
      'publication': 'May 2023',
      'formats': ['eBook', 'Hardcover', 'Kindle'],
      'editions': [
        {
          'cover': 'https://covers.openlibrary.org/b/id/10523338-L.jpg',
          'type': 'eBook',
          'year': '2023',
        },
        {
          'cover': 'https://covers.openlibrary.org/b/id/10523338-L.jpg',
          'type': 'Hardcover',
          'year': '2022',
        },
        {
          'cover': 'https://covers.openlibrary.org/b/id/10523338-L.jpg',
          'type': 'Kindle',
          'year': '2021',
        },
      ],
      'currentlyReading': 481,
      'wantToRead': 1898,
    };
    final author = {
      'name': 'Author Name',
      'photo': 'https://randomuser.me/api/portraits/men/32.jpg',
      'bio':
          'Award-winning author of modern fiction. Passionate about storytelling and inspiring readers.',
      'books': 10,
      'followers': 1200,
    };
    final reviews = List.generate(
      3,
      (i) => {
        'user': 'User Name',
        'photo': 'https://randomuser.me/api/portraits/women/${30 + i}.jpg',
        'date': 'Month DD, YYYY',
        'text':
            'Ut commodo velit adipiscing hendrerit non non elementum id id cursus non odio vel tincidunt quam at, ac sit Nam at, malesuada non placerat Nam ante, ac eget.',
        'likes': 54,
        'rating': 5 - i,
      },
    );
    final alsoEnjoyed = List.generate(
      6,
      (i) => {
        'title': 'Book Name',
        'author': 'Author Name',
        'cover': 'https://covers.openlibrary.org/b/id/10523338-L.jpg',
        'rating': 4.5,
        'reviews': 3318,
      },
    );
    final reviewBreakdown = [
      {'stars': 5, 'count': 500},
      {'stars': 4, 'count': 200},
      {'stars': 3, 'count': 60},
      {'stars': 2, 'count': 20},
      {'stars': 1, 'count': 16},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          children: [
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
                child: _BookSearchBar(),
              ),
            ),
            const SizedBox(height: 22),
            // Book Main Info Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BookCoverActions(book: book),
                        const SizedBox(width: 32, height: 32),
                        if (isWide)
                          SizedBox(
                            width: 400,
                            child: _BookInfoSection(book: book),
                          )
                        else
                          _BookInfoSection(book: book),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            // Editions
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _BookEditionsSection(book: book),
              ),
            ),
            const SizedBox(height: 18),
            // Reading Stats & Engagement
            _BookStatsSection(book: book),
            const SizedBox(height: 18),
            // About the Author
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _AboutAuthorSection(author: author),
              ),
            ),
            const SizedBox(height: 18),
            // Rating & Reviews
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _RatingReviewsSection(
                  book: book,
                  reviewBreakdown: reviewBreakdown,
                  reviews: reviews,
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Readers Also Enjoyed
            const _SectionHeader(
              title: 'Readers also Enjoyed',
              icon: Icons.recommend,
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: _AlsoEnjoyedSection(books: alsoEnjoyed),
              ),
            ),
            const SizedBox(height: 28),
            // Footer
            _Footer(),
          ],
        ),
      ),
    );
  }
}

// --- Components ---

class _BookSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search Your Books',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0096C7)),
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
        SizedBox(
          width: 180,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by ID or Type',
              filled: true,
              fillColor: Colors.white,
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
      ],
    );
  }
}

class _BookCoverActions extends StatelessWidget {
  final Map<String, dynamic> book;
  const _BookCoverActions({required this.book});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            Container(
              width: 180,
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0096C7).withOpacity(0.1), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Hero(
                tag: 'book_cover_${book['cover']}',
                child: Image.network(
                  book['cover'],
                  width: 180,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _ActionChipButton(
              icon: Icons.menu_book,
              label: 'Read',
              color: Color(0xFF0096C7),
              minWidth: 140,
            ),
            _ActionChipButton(
              icon: Icons.summarize,
              label: 'Summary',
              color: Color(0xFFB5179E),
              minWidth: 140,
            ),
            _ActionChipButton(
              icon: Icons.picture_as_pdf,
              label: 'Download PDF',
              color: Color(0xFF43AA8B),
              minWidth: 140,
            ),
            _ActionChipButton(
              icon: Icons.shopping_cart,
              label: 'Borrow/Buy',
              color: Color(0xFFF3722C),
              minWidth: 140,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0096C7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: const BorderSide(color: Color(0xFF0096C7)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          ),
          child: const Text('Book Status'),
        ),
      ],
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double minWidth;
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.color,
    this.minWidth = 120,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: minWidth,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 2,
          shadowColor: color.withOpacity(0.15),
        ),
        onPressed: () {},
      ),
    );
  }
}

class _BookInfoSection extends StatelessWidget {
  final Map<String, dynamic> book;
  const _BookInfoSection({required this.book});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book['title'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Color(0xFF0096C7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          book['author'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            Text(
              '${book['rating']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Text(
              '${book['ratingsCount']} ratings, ${book['reviewsCount']} reviews',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(book['description'], style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ...book['genres'].map<Widget>(
              (g) => Chip(
                label: Text(g),
                backgroundColor: const Color(0xFFE0EAFc),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _MetaItem(label: 'Pages', value: '${book['pages']}'),
              _MetaItem(label: 'Language', value: book['language']),
              _MetaItem(label: 'ISBN', value: book['isbn']),
              _MetaItem(label: 'Published', value: book['publication']),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetaItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18, bottom: 4),
      child: Chip(
        label: Text('$label: $value', style: const TextStyle(fontSize: 13)),
        backgroundColor: const Color(0xFFE0EAFc),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }
}

class _BookEditionsSection extends StatelessWidget {
  final Map<String, dynamic> book;
  const _BookEditionsSection({required this.book});
  @override
  Widget build(BuildContext context) {
    final editions = (book['editions'] as List?) ?? [];
    if (editions.isEmpty) {
      return const SizedBox(height: 120);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'More Edition'),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: editions.length,
            separatorBuilder: (context, i) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final ed = editions[i];
              if (ed == null) {
                return const SizedBox(width: 70, height: 120);
              }
              return SizedBox(
                width: 70,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ed['cover'] ?? '',
                        width: 60,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ed['type'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      ed['year'] ?? '',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        TextButton(onPressed: () {}, child: const Text('Show all Editions')),
      ],
    );
  }
}

class _BookStatsSection extends StatelessWidget {
  final Map<String, dynamic> book;

  const _BookStatsSection({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Colors.blueGrey[400]),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 200,
                    child: Text(
                      '${book['currentlyReading']} people are currently reading',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Row(
                children: [
                  Icon(Icons.bookmark, color: Colors.orange[400]),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 180,
                    child: Text(
                      '${book['wantToRead']} want to Read',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              TextButton(
                onPressed: () {},
                child: const Text('More Information'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _AboutAuthorSection extends StatelessWidget {
  final Map<String, dynamic> author;
  const _AboutAuthorSection({required this.author});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'About the Author'),
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(author['photo']),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${author['books']} Books   ${author['followers']} Followers',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(author['bio'], style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RatingReviewsSection extends StatelessWidget {
  final Map<String, dynamic> book;
  final List<Map<String, dynamic>> reviewBreakdown;
  final List<Map<String, dynamic>> reviews;

  const _RatingReviewsSection({
    required this.book,
    required this.reviewBreakdown,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Rating & Reviews', icon: Icons.star),

        // ✅ Fix: Wrap the Row in a SingleChildScrollView to avoid overflow
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Rating Input
              SizedBox(
                width: 250, // 👈 Adjust width as needed
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                            'https://randomuser.me/api/portraits/men/31.jpg',
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'What Do You Think ?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        5,
                            (i) => const Icon(Icons.star_border, color: Colors.amber),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0096C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Write a review'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Community Reviews Chart
              SizedBox(
                width: 300, // 👈 Adjust width as needed
                child: _CommunityReviewsChart(
                  rating: book['rating'],
                  count: book['reviewsCount'],
                  breakdown: reviewBreakdown,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Reader Reviews List
        const Text(
          'Readers Reviews',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...reviews.map((r) => _ReviewItem(review: r)),
        const SizedBox(height: 8),
        Center(
          child: OutlinedButton(
            onPressed: () {},
            child: const Text('More Reviews'),
          ),
        ),
      ],
    );
  }
}


class _CommunityReviewsChart extends StatelessWidget {
  final double rating;
  final int count;
  final List<Map<String, dynamic>> breakdown;
  const _CommunityReviewsChart({
    required this.rating,
    required this.count,
    required this.breakdown,
  });
  @override
  Widget build(BuildContext context) {
    final maxCount = breakdown
        .map((b) => b['count'] as int)
        .reduce((a, b) => a > b ? a : b);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$rating',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            Text(
              '$count Reviews',
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ...breakdown.map(
              (b) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      '${b['stars']} stars',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 60,
                      child: LinearProgressIndicator(
                        value: (b['count'] as int) / maxCount,
                        backgroundColor: Colors.grey[200],
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${b['count']}', style: const TextStyle(fontSize: 12)),
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

class _ReviewItem extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewItem({required this.review});
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(review['photo']),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    review['user'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    review['date'],
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0096C7),
                      side: const BorderSide(color: Color(0xFF0096C7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: const Text('Follow'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  review['rating'],
                  (i) => const Icon(Icons.star, color: Colors.amber, size: 14),
                ),
              ),
              const SizedBox(height: 6),
              Text(review['text'], style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${review['likes']} Likes',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(onPressed: () {}, child: const Text('Like')),
                  TextButton(onPressed: () {}, child: const Text('Comment')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlsoEnjoyedSection extends StatelessWidget {
  final List<Map<String, dynamic>> books;
  const _AlsoEnjoyedSection({required this.books});

  @override
  Widget build(BuildContext context) {
    final safeBooks = books ?? [];
    if (safeBooks.isEmpty) {
      return const SizedBox(height: 170);
    }

    return SizedBox(
      height: 190, // ✅ Increased to give enough height
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: safeBooks.length,
        separatorBuilder: (context, i) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final book = safeBooks[i];
          if (book == null) {
            return const SizedBox(width: 100, height: 170);
          }
          return SizedBox(
            width: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    book['cover'] ?? '',
                    width: 90,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 90,
                  child: Text(
                    book['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  book['author'] ?? '',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    Text(
                      '${book['rating'] ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  const _SectionHeader({required this.title, this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF0096C7),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        if (icon != null) Icon(icon, color: Color(0xFF0096C7)),
        if (icon != null) const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF22223b),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(thickness: 1, color: Colors.grey)),
      ],
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
            'BRAIN COPYRIGHT (C) TaleHive LMS - 2025. ALL RIGHTS RESERVED',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            'DATA RETENTION SUMMARY    |    GET THE MOBILE APP',
            style: TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
