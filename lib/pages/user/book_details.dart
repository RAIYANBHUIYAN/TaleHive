import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'user_dashboard.dart';
import 'package:intl/intl.dart';

// --- Data Models ---
class BookDetails {
  final String title;
  final String author;
  final String cover;
  final double rating;
  final int ratingsCount;
  final int reviewsCount;
  final String description;
  final List<String> genres;
  final int pages;
  final String language;
  final String isbn;
  final String publication;
  final List<String> formats;
  final List<Edition> editions;
  final int currentlyReading;
  final int wantToRead;
  final Author authorDetails;
  final List<Review> reviews;
  final List<BookRecommendation> alsoEnjoyed;
  final List<ReviewBreakdown> reviewBreakdown;

  BookDetails({
    required this.title,
    required this.author,
    required this.cover,
    required this.rating,
    required this.ratingsCount,
    required this.reviewsCount,
    required this.description,
    required this.genres,
    required this.pages,
    required this.language,
    required this.isbn,
    required this.publication,
    required this.formats,
    required this.editions,
    required this.currentlyReading,
    required this.wantToRead,
    required this.authorDetails,
    required this.reviews,
    required this.alsoEnjoyed,
    required this.reviewBreakdown,
  });

  factory BookDetails.fromJson(Map<String, dynamic> json) {
    return BookDetails(
      title: json['title'],
      author: json['author'],
      cover: json['cover'],
      rating: (json['rating'] as num).toDouble(),
      ratingsCount: json['ratingsCount'],
      reviewsCount: json['reviewsCount'],
      description: json['description'],
      genres: List<String>.from(json['genres'] ?? []),
      pages: json['pages'],
      language: json['language'],
      isbn: json['isbn'],
      publication: json['publication'],
      formats: List<String>.from(json['formats'] ?? []),
      editions: (json['editions'] as List? ?? []).map((e) => Edition.fromJson(e)).toList(),
      currentlyReading: json['currentlyReading'],
      wantToRead: json['wantToRead'],
      authorDetails: Author.fromJson(json['authorDetails']),
      reviews: (json['reviews'] as List? ?? []).map((e) => Review.fromJson(e)).toList(),
      alsoEnjoyed: (json['alsoEnjoyed'] as List? ?? []).map((e) => BookRecommendation.fromJson(e)).toList(),
      reviewBreakdown: (json['reviewBreakdown'] as List? ?? []).map((e) => ReviewBreakdown.fromJson(e)).toList(),
    );
  }
}

class Edition {
  final String cover;
  final String type;
  final String year;
  Edition({required this.cover, required this.type, required this.year});
  factory Edition.fromJson(Map<String, dynamic> json) => Edition(
    cover: json['cover'],
    type: json['type'],
    year: json['year'],
  );
}

class Author {
  final String name;
  final String photo;
  final String bio;
  final int books;
  final int followers;
  Author({required this.name, required this.photo, required this.bio, required this.books, required this.followers});
  factory Author.fromJson(Map<String, dynamic> json) => Author(
    name: json['name'],
    photo: json['photo'],
    bio: json['bio'],
    books: json['books'],
    followers: json['followers'],
  );
}

class Review {
  final String user;
  final String photo;
  final String date;
  final String text;
  final int likes;
  final int rating;
  Review({required this.user, required this.photo, required this.date, required this.text, required this.likes, required this.rating});
  factory Review.fromJson(Map<String, dynamic> json) => Review(
    user: json['user'],
    photo: json['photo'],
    date: json['date'],
    text: json['text'],
    likes: json['likes'],
    rating: json['rating'],
  );
}

class BookRecommendation {
  final String title;
  final String author;
  final String cover;
  final double rating;
  final int reviews;
  BookRecommendation({required this.title, required this.author, required this.cover, required this.rating, required this.reviews});
  factory BookRecommendation.fromJson(Map<String, dynamic> json) => BookRecommendation(
    title: json['title'],
    author: json['author'],
    cover: json['cover'],
    rating: (json['rating'] as num).toDouble(),
    reviews: json['reviews'],
  );
}

class ReviewBreakdown {
  final int stars;
  final int count;
  ReviewBreakdown({required this.stars, required this.count});
  factory ReviewBreakdown.fromJson(Map<String, dynamic> json) => ReviewBreakdown(
    stars: json['stars'],
    count: json['count'],
  );
}

// --- API Service ---
Future<BookDetails> fetchBookDetails(String bookId) async {
  // If bookId is 'mock', always return mock data
  if (bookId == 'mock') {
    await Future.delayed(const Duration(milliseconds: 500));
    return BookDetails(
      title: "There's a Million Books I Haven't Read, but Just You",
      author: 'Author Name',
      cover: 'https://covers.openlibrary.org/b/id/10523338-L.jpg',
      rating: 4.5,
      ratingsCount: 8564,
      reviewsCount: 796,
      description:
      "This book was pure magic. The Night Circus is unlike anything I've ever read—ambition, forbidden love, and competition entwined. The story follows a secret competition between two young magicians, Celia and her father, who are bound by a black-and-white circus that only appears at night, enchanting visitors with its mysterious acts.",
      genres: ['Fiction', 'Fantasy', 'Magic', 'Adventure', 'Romance'],
      pages: 432,
      language: 'English',
      isbn: '1234567890',
      publication: 'May 2023',
      formats: ['eBook', 'Hardcover', 'Kindle'],
      editions: [
        Edition(cover: 'https://covers.openlibrary.org/b/id/10523338-L.jpg', type: 'eBook', year: '2023'),
        Edition(cover: 'https://covers.openlibrary.org/b/id/10523338-L.jpg', type: 'Hardcover', year: '2022'),
        Edition(cover: 'https://covers.openlibrary.org/b/id/10523338-L.jpg', type: 'Kindle', year: '2021'),
      ],
      currentlyReading: 481,
      wantToRead: 1898,
      authorDetails: Author(
        name: 'Author Name',
        photo: 'https://randomuser.me/api/portraits/men/32.jpg',
        bio: 'Award-winning author of modern fiction. Passionate about storytelling and inspiring readers.',
        books: 10,
        followers: 1200,
      ),
      reviews: List.generate(
        3,
            (i) => Review(
          user: 'User Name',
          photo: 'https://randomuser.me/api/portraits/women/${30 + i}.jpg',
          date: 'Month DD, YYYY',
          text: 'Ut commodo velit adipiscing hendrerit non non elementum id id cursus non odio vel tincidunt quam at, ac sit Nam at, malesuada non placerat Nam ante, ac eget.',
          likes: 54,
          rating: 5 - i,
        ),
      ),
      alsoEnjoyed: List.generate(
        6,
            (i) => BookRecommendation(
          title: 'Book Name',
          author: 'Author Name',
          cover: 'https://covers.openlibrary.org/b/id/10523338-L.jpg',
          rating: 4.5,
          reviews: 3318,
        ),
      ),
      reviewBreakdown: [
        ReviewBreakdown(stars: 5, count: 500),
        ReviewBreakdown(stars: 4, count: 200),
        ReviewBreakdown(stars: 3, count: 60),
        ReviewBreakdown(stars: 2, count: 20),
        ReviewBreakdown(stars: 1, count: 16),
      ],
    );
  }

  // If bookId is empty or null, throw error
  if (bookId.isEmpty) {
    throw Exception('No bookId provided.');
  }

  // Replace with your real API endpoint
  final url = Uri.parse('https://api.example.com/books/$bookId/details');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return BookDetails.fromJson(jsonDecode(response.body));
    } else {
      // If API fails, fallback to mock data for development
      return await fetchBookDetails('mock');
    }
  } catch (e) {
    // If API call throws, fallback to mock data for development
    return await fetchBookDetails('mock');
  }
}

class BookDetailsPage extends StatelessWidget {
  final String bookId;
  const BookDetailsPage({Key? key, required this.bookId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: FutureBuilder<BookDetails>(
          future: fetchBookDetails(bookId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: \\${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No data found'));
            }
            final book = snapshot.data!;
            return ListView(
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
                const SizedBox(height: 18),
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
                    child: _AboutAuthorSection(author: book.authorDetails),
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
                      reviewBreakdown: book.reviewBreakdown,
                      reviews: book.reviews,
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
                    child: _AlsoEnjoyedSection(books: book.alsoEnjoyed),
                  ),
                ),
                const SizedBox(height: 28),
                // Footer
                _Footer(),
                const SizedBox(height: 18),
                // Navigation Button for testing
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserDashboardPage(
                          onMyBooksTap: () {},
                          onEditProfileTap: () {},
                        )),
                      );
                    },
                    child: const Text('Go to User Dashboard'),
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
  final BookDetails book;
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
                tag: 'book_cover_${book.cover}',
                child: Image.network(
                  book.cover,
                  width: 180,
                  height: 240,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 90, // match width
                    height: 120, // match height
                    color: Colors.grey[300],
                    child: const Icon(Icons.book, size: 40, color: Colors.grey),
                  ),
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
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => BorrowRequestDialog(
                    bookCover: book.cover,
                    bookName: book.title,
                    authorName: book.author,
                  ),
                );
              },
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
  final VoidCallback? onPressed;
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.color,
    this.minWidth = 120,
    this.onPressed,
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
        onPressed: onPressed ?? () {},
      ),
    );
  }
}

class _BookInfoSection extends StatelessWidget {
  final BookDetails book;
  const _BookInfoSection({required this.book});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Color(0xFF0096C7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          book.author,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            Text(
              '${book.rating}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Text(
              '${book.ratingsCount} ratings, ${book.reviewsCount} reviews',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(book.description, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ...book.genres.map<Widget>(
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
              _MetaItem(label: 'Pages', value: '${book.pages}'),
              _MetaItem(label: 'Language', value: book.language),
              _MetaItem(label: 'ISBN', value: book.isbn),
              _MetaItem(label: 'Published', value: book.publication),
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
  final BookDetails book;
  const _BookEditionsSection({required this.book});
  @override
  Widget build(BuildContext context) {
    final editions = (book.editions as List?) ?? [];
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
                        ed.cover ?? '',
                        width: 60,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60, // match width
                          height: 80, // match height
                          color: Colors.grey[300],
                          child: const Icon(Icons.book, size: 30, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ed.type ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      ed.year ?? '',
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
  final BookDetails book;

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
                      '${book.currentlyReading} people are currently reading',
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
                      '${book.wantToRead} want to Read',
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
  final Author author;
  const _AboutAuthorSection({required this.author});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'About the Author'),
        Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ClipOval(
                child: Image.network(
                  author.photo,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, size: 32, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${author.books} Books   ${author.followers} Followers',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(author.bio, style: const TextStyle(fontSize: 13)),
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
  final BookDetails book;
  final List<ReviewBreakdown> reviewBreakdown;
  final List<Review> reviews;

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
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => WriteReviewDialog(
                                bookCover: book.cover,
                                bookName: book.title,
                                authorName: book.author,
                              ),
                            );
                          },
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
                  rating: book.rating,
                  count: book.reviewsCount,
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
  final List<ReviewBreakdown> breakdown;
  const _CommunityReviewsChart({
    required this.rating,
    required this.count,
    required this.breakdown,
  });
  @override
  Widget build(BuildContext context) {
    final maxCount = breakdown
        .map((b) => b.count as int)
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
                      '${b.stars} stars',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 60,
                      child: LinearProgressIndicator(
                        value: (b.count as int) / maxCount,
                        backgroundColor: Colors.grey[200],
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${b.count}', style: const TextStyle(fontSize: 12)),
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
  final Review review;
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
                    backgroundImage: NetworkImage(review.photo),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    review.user,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    review.date,
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
                  review.rating,
                      (i) => const Icon(Icons.star, color: Colors.amber, size: 14),
                ),
              ),
              const SizedBox(height: 6),
              Text(review.text, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${review.likes} Likes',
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
  final List<BookRecommendation> books;
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
                    book.cover ?? '',
                    width: 90,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 90, // match width
                      height: 120, // match height
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 90,
                  child: Text(
                    book.title ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  book.author ?? '',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    Text(
                      '${book.rating ?? ''}',
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
            'Mr. and His Team COPYRIGHT (C) - 2025. ALL RIGHTS RESERVED',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          SizedBox(height: 4),

        ],
      ),
    );
  }
}

class WriteReviewDialog extends StatefulWidget {
  final String bookCover;
  final String bookName;
  final String authorName;
  
  const WriteReviewDialog({
    Key? key,
    required this.bookCover,
    required this.bookName,
    required this.authorName,
  }) : super(key: key);

  @override
  State<WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<WriteReviewDialog> {
  int rating = 0;
  final TextEditingController reviewController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF8BC7DB),
      child: Container(
        width: MediaQuery.of(context).size.width > 500 ? 500 : double.infinity,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Close button in top right
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 20,
                  ),
                ],
              ),
              
              // Title
              Text(
                'Write a Review',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: const Color(0xFF22223b),
                ),
              ),
              const SizedBox(height: 24),
              
              // Book cover
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.bookCover,
                  width: 120,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 120,
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.book, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Book title
              Text(
                widget.bookName,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: const Color(0xFF22223b),
                ),
                textAlign: TextAlign.center,
              ),
              
              // Author name
              Text(
                widget.authorName,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFF6B35),
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      rating = i + 1;
                    });
                  },
                  splashRadius: 20,
                )),
              ),
              const SizedBox(height: 20),
              
              // Reviews label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reviews',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF22223b),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Review text field
              Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: reviewController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Write your review about this book',
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a review';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && rating > 0) {
                      // Handle review submission here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Review submitted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pop();
                    } else if (rating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a rating'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38B000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BorrowRequestDialog extends StatefulWidget {
  final String bookCover;
  final String bookName;
  final String authorName;
  const BorrowRequestDialog({
    required this.bookCover,
    required this.bookName,
    required this.authorName,
  });

  @override
  State<BorrowRequestDialog> createState() => _BorrowRequestDialogState();
}

class _BorrowRequestDialogState extends State<BorrowRequestDialog> {
  int step = 1;
  int rating = 0;
  final TextEditingController reasonController = TextEditingController();
  DateTime? collectionDate;
  DateTime? returnDate;
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: step == 1 ? const Color(0xFFBFE6FB) : Colors.white,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: MediaQuery.of(context).size.width > 500 ? 500 : double.infinity,
        padding: const EdgeInsets.all(32),
        child: step == 1 ? _buildStep1(context) : _buildStep2(context),
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Close button positioned at top right
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 28),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
          // Title centered below
          Text('Borrow Request',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: const Color(0xFF22223b),
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              widget.bookCover,
              width: 120,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 120,
                height: 150,
                color: Colors.grey[300],
                child: const Icon(Icons.book, size: 40, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(widget.bookName,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: const Color(0xFF22223b),
              )),
          Text(widget.authorName,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: Colors.black87,
              )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => IconButton(
              icon: Icon(
                i < rating ? Icons.star : Icons.star_border,
                color: const Color(0xFF43AA8B),
                size: 28,
              ),
              onPressed: () {
                setState(() {
                  rating = i + 1;
                });
              },
              splashRadius: 20,
            )),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4),
              child: Text(
                'Write Why You Want To Borrow This Book',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: reasonController,
              minLines: 3,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your reason to borrow',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a reason';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      step = 2;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38B000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 36, color: Color(0xFF0096C7)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Borrow Date\nDetails',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: const Color(0xFF0096C7),
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 28),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
          const Divider(thickness: 1, height: 28),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Book Collection\nDate',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: collectionDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            collectionDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0096C7)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          collectionDate != null ? _dateFormat.format(collectionDate!) : 'Enter Date',
                          style: TextStyle(
                            color: collectionDate != null ? Colors.black : Colors.blueGrey,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Book Return\nDate',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: returnDate ?? (collectionDate ?? DateTime.now()),
                          firstDate: collectionDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (picked != null) {
                          setState(() {
                            returnDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0096C7)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          returnDate != null ? _dateFormat.format(returnDate!) : 'Enter Date',
                          style: TextStyle(
                            color: returnDate != null ? Colors.black : Colors.blueGrey,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBFE6FB),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (collectionDate == null || returnDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select both dates.')),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0096C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  child: const Text('CONFIRM'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
