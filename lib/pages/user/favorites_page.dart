import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'book_details.dart';

class FavoritesPage extends StatefulWidget {
  final VoidCallback? onFavoritesChanged; // Add this callback
  
  const FavoritesPage({Key? key, this.onFavoritesChanged}) : super(key: key);

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

  // ✅ Update the _removeFromFavorites method to notify parent
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

      // ✅ Notify parent page about the change
      if (widget.onFavoritesChanged != null) {
        widget.onFavoritesChanged!();
      }

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
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ Get responsive grid count based on screen width
  int _getGridCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) {
      return 2; // Mobile
    } else if (screenWidth < 900) {
      return 3; // Tablet portrait
    } else if (screenWidth < 1200) {
      return 4; // Tablet landscape
    } else {
      return 5; // Desktop
    }
  }

  // ✅ Get responsive aspect ratio
  double _getGridAspectRatio(double screenWidth) {
    if (screenWidth < 400) {
      return 0.65; // Mobile - slightly taller cards for better book cover visibility
    } else if (screenWidth < 600) {
      return 0.68; // Small screens
    } else if (screenWidth < 900) {
      return 0.72; // Tablet portrait
    } else {
      return 0.75; // Tablet landscape and desktop
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22223b)),
          onPressed: () => Navigator.pop(context),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'My Favorites',
            style: GoogleFonts.montserrat(
              color: const Color(0xFF22223b),
              fontWeight: FontWeight.bold,
              fontSize: screenWidth < 400 ? 18 : 20,
            ),
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
              ? _buildEmptyState(screenWidth, screenHeight)
              : _buildFavoritesList(screenWidth),
    );
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          width: screenWidth,
          constraints: BoxConstraints(
            minHeight: screenHeight * 0.7,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.08,
              vertical: 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth < 400 ? 20 : 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0096C7).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: screenWidth < 400 ? 48 : 64,
                    color: const Color(0xFF0096C7),
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.03),
                
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'No Favorites Yet',
                    style: GoogleFonts.montserrat(
                      fontSize: screenWidth < 400 ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.015),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Text(
                    'Start exploring and add books to your favorites by tapping the heart icon.',
                    style: GoogleFonts.montserrat(
                      fontSize: screenWidth < 400 ? 14 : 16,
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.04),
                
                SizedBox(
                  width: screenWidth < 400 ? screenWidth * 0.7 : null,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0096C7),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth < 400 ? 24 : 32,
                        vertical: screenWidth < 400 ? 12 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Explore Books',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth < 400 ? 14 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesList(double screenWidth) {
    final crossAxisCount = _getGridCrossAxisCount(screenWidth);
    final aspectRatio = _getGridAspectRatio(screenWidth);
    final horizontalPadding = screenWidth * 0.04;
    
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header info
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: const Color(0xFF0096C7),
                  size: screenWidth < 400 ? 18 : 20,
                ),
                SizedBox(width: screenWidth * 0.02),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_favoriteBooks.length} favorite${_favoriteBooks.length != 1 ? 's' : ''}',
                      style: GoogleFonts.montserrat(
                        fontSize: screenWidth < 400 ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Books grid
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: screenWidth < 400 ? 12 : 16,
              mainAxisSpacing: screenWidth < 400 ? 12 : 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final book = _favoriteBooks[index];
                return _buildFavoriteBookCard(book, screenWidth);
              },
              childCount: _favoriteBooks.length,
            ),
          ),
        ),
        
        // Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ),
      ],
    );
  }

  Widget _buildFavoriteBookCard(Map<String, dynamic> book, double screenWidth) {
    final bookId = book['id']?.toString() ?? '';
    final isSmallScreen = screenWidth < 400;
    final cardPadding = isSmallScreen ? 8.0 : 12.0;
    
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
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: isSmallScreen ? 8 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Fixed book image container with proper aspect ratio
            Expanded(
              flex: isSmallScreen ? 6 : 7, // More space for image
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.all(cardPadding),
                child: Stack(
                  children: [
                    // ✅ Properly fitted book cover
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                        child: book['cover_image_url'] != null && book['cover_image_url'].toString().isNotEmpty
                            ? Image.network(
                                book['cover_image_url'],
                                fit: BoxFit.cover, // ✅ This ensures the image covers the entire container
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0096C7).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: const Color(0xFF0096C7),
                                        strokeWidth: 2,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF0096C7).withOpacity(0.1),
                                          const Color(0xFF0096C7).withOpacity(0.2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.picture_as_pdf,
                                            color: const Color(0xFF0096C7),
                                            size: isSmallScreen ? 24 : 32,
                                          ),
                                          if (!isSmallScreen) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'PDF',
                                              style: GoogleFonts.montserrat(
                                                color: const Color(0xFF0096C7),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF0096C7).withOpacity(0.1),
                                      const Color(0xFF0096C7).withOpacity(0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.picture_as_pdf,
                                        color: const Color(0xFF0096C7),
                                        size: isSmallScreen ? 24 : 32,
                                      ),
                                      if (!isSmallScreen) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'PDF',
                                          style: GoogleFonts.montserrat(
                                            color: const Color(0xFF0096C7),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    
                    // ✅ Remove from favorites button - better positioned
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _showRemoveConfirmation(bookId, book['title'] ?? 'this book'),
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: isSmallScreen ? 16 : 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // ✅ Book details section - properly constrained
            Expanded(
              flex: isSmallScreen ? 4 : 3, // Less space for text, more for image
              child: Padding(
                padding: EdgeInsets.fromLTRB(cardPadding, 0, cardPadding, cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Title - properly constrained
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          book['title'] ?? 'No Title',
                          maxLines: isSmallScreen ? 2 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: isSmallScreen ? 11 : 13,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    ),
                    
                    // ✅ Author - constrained to one line
                    if (book['author_name'] != null && book['author_name'].toString().trim().isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 2),
                        child: Text(
                          book['author_name'],
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF64748B),
                            fontSize: isSmallScreen ? 9 : 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // ✅ Bottom row - rating and badge
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Rating
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: isSmallScreen ? 12 : 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '4.5',
                                  style: GoogleFonts.montserrat(
                                    fontSize: isSmallScreen ? 9 : 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2D3748),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Favorite badge
                          Expanded(
                            flex: 1,
                            child: Container(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 6 : 8,
                                  vertical: isSmallScreen ? 2 : 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0096C7).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF0096C7).withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  'FAVORITE',
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0xFF0096C7),
                                    fontSize: isSmallScreen ? 7 : 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.favorite, 
                color: Colors.red, 
                size: screenWidth < 400 ? 20 : 24,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Remove Favorite',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth < 400 ? 16 : 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              'Remove "$bookTitle" from your favorites?',
              style: GoogleFonts.montserrat(
                fontSize: screenWidth < 400 ? 14 : 16,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: screenWidth < 400 ? 14 : 16,
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
                  fontSize: screenWidth < 400 ? 14 : 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}