import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'book_details.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _favoriteBooks = [];
  bool _isLoading = true;
  Set<String> _favoriteBookIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadFavoriteBooks();
  }

  Future<void> _loadFavoriteBooks() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // First, get user's favorite book IDs
      final userResponse = await supabase
          .from('users')
          .select('Favourites')
          .eq('id', user.id)
          .single();

      final favorites = userResponse['Favourites'];
      if (favorites != null && favorites.isNotEmpty) {
        List<String> favoriteIds;
        if (favorites is String) {
          favoriteIds = favorites.split(',').where((id) => id.isNotEmpty).toList();
        } else if (favorites is List) {
          favoriteIds = favorites.map((id) => id.toString()).toList();
        } else {
          favoriteIds = [];
        }

        setState(() {
          _favoriteBookIds = favoriteIds.toSet();
        });

        if (favoriteIds.isNotEmpty) {
          // Get book details for favorite IDs
          final booksResponse = await supabase
              .from('books')
              .select()
              .inFilter('id', favoriteIds)
              .eq('is_active', true);

          setState(() {
            _favoriteBooks = List<Map<String, dynamic>>.from(booksResponse);
          });
        }
      }
    } catch (e) {
      print('Error loading favorite books: $e');
      _showSnackBar('Failed to load favorites: ${e.toString()}', backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromFavorites(String bookId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Remove from local state
      setState(() {
        _favoriteBookIds.remove(bookId);
        _favoriteBooks.removeWhere((book) => book['id'].toString() == bookId);
      });

      // Update database
      final favoritesString = _favoriteBookIds.join(',');
      await supabase.from('users')
          .update({'Favourites': favoritesString})
          .eq('id', user.id);

      _showSnackBar('Removed from favorites', backgroundColor: Colors.orange);
    } catch (e) {
      print('Error removing from favorites: $e');
      _showSnackBar('Failed to remove from favorites', backgroundColor: Colors.red);
      // Reload to restore state
      _loadFavoriteBooks();
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat()),
        backgroundColor: backgroundColor ?? const Color(0xFF0096C7),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22223b)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Favorites',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF22223b),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF22223b)),
            onPressed: _loadFavoriteBooks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0096C7)))
          : _favoriteBooks.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0096C7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 64,
                color: Color(0xFF0096C7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Favorites Yet',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start exploring and add books to your favorites by tapping the heart icon.',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0096C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Explore Books',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: const Color(0xFF0096C7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_favoriteBooks.length} favorite${_favoriteBooks.length != 1 ? 's' : ''}',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Books grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65, // Made books taller for more content
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final book = _favoriteBooks[index];
                return _buildFavoriteBookCard(book);
              },
              childCount: _favoriteBooks.length,
            ),
          ),
        ),
        
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildFavoriteBookCard(Map<String, dynamic> book) {
    final bookId = book['id']?.toString() ?? '';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsPage(bookId: bookId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book image with remove button
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      book['cover_image_url'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0096C7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            color: Color(0xFF0096C7),
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Remove from favorites button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _showRemoveConfirmation(bookId, book['title'] ?? 'this book'),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Book details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title'] ?? 'No Title',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    if (book['author_name'] != null && book['author_name'].toString().trim().isNotEmpty)
                      Text(
                        book['author_name'],
                        style: GoogleFonts.montserrat(
                          color: Colors.blueGrey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const Spacer(),
                    
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '4.5',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0096C7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'FAVORITE',
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF0096C7),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }

  void _showRemoveConfirmation(String bookId, String bookTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              Text(
                'Remove Favorite',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Remove "$bookTitle" from your favorites?',
            style: GoogleFonts.montserrat(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _removeFromFavorites(bookId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Remove',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}