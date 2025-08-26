import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// A StatefulWidget to provide a fade-in animation for its child.
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FadeInAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class BookClubPage extends StatefulWidget {
  const BookClubPage({Key? key}) : super(key: key);

  @override
  State<BookClubPage> createState() => _BookClubPageState();
}

class _BookClubPageState extends State<BookClubPage> {
  final TextEditingController _searchController = TextEditingController();
  double _minRating = 0.0;
  String _selectedGenre = 'All';

  // Example book data with genres
  final List<Map<String, dynamic>> _allBooks = List.generate(
    12,
    (i) => {
      'title': 'Book Title $i',
      'author': 'Author Name $i',
      'cover': 'https://covers.openlibrary.org/b/id/10523338-L.jpg',
      'rating': 3.5 + (i % 3) * 0.5,
      'description':
          'A compelling tale that explores deep themes of discovery and adventure in a richly detailed world. Perfect for an evening read.',
      'genre': ['Fiction', 'Sci-Fi', 'Mystery', 'Fantasy'][i % 4],
    },
  );

  final List<String> _genres = [
    'All',
    'Fiction',
    'Sci-Fi',
    'Mystery',
    'Fantasy',
  ];

  String _searchText = '';

  List<Map<String, dynamic>> get _filteredBooks {
    return _allBooks.where((book) {
      final searchLower = _searchText.toLowerCase();
      final matchesSearch =
          book['title'].toString().toLowerCase().contains(searchLower) ||
          book['author'].toString().toLowerCase().contains(searchLower);
      final matchesRating = (book['rating'] as double) >= _minRating;
      final matchesGenre =
          _selectedGenre == 'All' || book['genre'] == _selectedGenre;
      return matchesSearch && matchesRating && matchesGenre;
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
        return StatefulBuilder(
          builder: (context, setModalState) {
            double localMinRating = _minRating;
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
                        const Icon(Icons.star_border, color: Colors.amber),
                        Expanded(
                          child: Slider(
                            value: localMinRating,
                            min: 0.0,
                            max: 5.0,
                            divisions: 10,
                            label: localMinRating.toStringAsFixed(1),
                            activeColor: const Color(0xFF0096C7),
                            inactiveColor: const Color(0xFFADE8F4),
                            onChanged: (value) {
                              setModalState(() {
                                localMinRating = value;
                              });
                            },
                            onChangeEnd: (value) {
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
                        child: const Text('Apply'),
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          children: [
            // Header Row (avatar + header)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0096C7),
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage('Asset/images/parvez.jpg'),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to TaleHive',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            color: const Color(0xFF023E8A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your community book club',
                          style: TextStyle(
                            color: Colors.blueGrey[600],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Book of the Month Section
            _SectionHeader(title: 'Book of the Month'),
            _buildBookOfTheMonthCard(),
            const SizedBox(height: 24),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 2,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _searchText = value),
                          decoration: InputDecoration(
                            hintText: 'Search title or author...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF0096C7),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _showFilterSheet,
                        icon: const Icon(Icons.filter_list),
                        tooltip: 'Filter by rating',
                        color: const Color(0xFF0077B6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Genre Filter Chips
            _SectionHeader(title: 'Filter by Genre'),
            _buildGenreChips(),
            const SizedBox(height: 28),

            _SectionHeader(title: 'Community Books'),

            // Book List
            if (_filteredBooks.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredBooks.length,
                itemBuilder: (context, index) {
                  final book = _filteredBooks[index];
                  return FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 18,
                        left: 24,
                        right: 24,
                      ),
                      child: _buildBookCard(book),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // A widget for displaying a styled section header.
  Widget _SectionHeader({required String title}) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.lato(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: const Color(0xFF023E8A),
        ),
      ),
    );
  }

  // A widget to display when no books match the filter criteria.
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 50, bottom: 50),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.blueGrey[200],
            ),
            const SizedBox(height: 16),
            Text(
              'No Books Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter settings.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.blueGrey[300]),
            ),
          ],
        ),
      ),
    );
  }

  // A card widget to display a single book's information.
  Widget _buildBookCard(Map<String, dynamic> book) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                (book['cover'] ?? '') as String,
                width: 90,
                height: 130,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.book, size: 90),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: SizedBox(
                height: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (book['title'] ?? '') as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF0077B6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (book['author'] ?? '') as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      (book['description'] ?? '') as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFADE8F4),
                            foregroundColor: const Color(0xFF023E8A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Discuss'),
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
    );
  }

  // A widget for the horizontal list of genre filter chips.
  Widget _buildGenreChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _genres.length,
        itemBuilder: (context, index) {
          final genre = _genres[index];
          final isSelected = _selectedGenre == genre;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(genre),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedGenre = genre;
                  });
                }
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF0096C7),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF023E8A),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0096C7)
                      : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // A card to showcase the featured "Book of the Month."
  Widget _buildBookOfTheMonthCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0096C7).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                'https://covers.openlibrary.org/b/id/10523338-L.jpg',
                width: 80,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dune by Frank Herbert',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join the discussion on this month\'s featured sci-fi classic!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Read More'),
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
