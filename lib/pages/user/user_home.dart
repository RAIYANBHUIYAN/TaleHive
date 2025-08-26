import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'user_dashboard.dart';
import '../club/book_club.dart';
import 'book_details.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'favorites_page.dart'; // Add this import at the top of the file

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _books = [];
  bool _isLoadingUser = false;
  bool _isLoadingBooks = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  
  // Add these new properties for favorites
  Set<String> _favoriteBookIds = <String>{};
  bool _isLoadingFavorites = false;

  final quotes = [
    "There is more treasure in books than in all the pirate's loot on Treasure Island. - Walt Disney",
    "A room without books is like a body without a soul. - Cicero",
    "Books are a uniquely portable magic. - Stephen King",
  ];

  // Dynamic data from Supabase books
  List<Map<String, dynamic>> get newArrivals => _books.take(3).toList();
  List<Map<String, dynamic>> get recommended => _books.skip(3).take(5).toList();
  List<Map<String, dynamic>> get popularBooks => _books.skip(8).take(4).toList();
  List<Map<String, dynamic>> get recentReadings => _books.skip(12).take(5).toList();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBooksFromSupabase();
    _loadUserFavorites(); // Add this line
  }

  // Replace the _loadUserData method with this corrected version
  Future<void> _loadUserData() async {
    setState(() => _isLoadingUser = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Only try users table (remove profiles table fallback)
        try {
          final userResponse = await supabase
              .from('users')
              .select()
              .eq('id', user.id)
              .single();

          setState(() {
            _userData = userResponse;
          });
          print('Successfully loaded user data from users table');
          return;
        } catch (userError) {
          print('User not found in users table: $userError');
          
          // Use auth metadata as fallback
          setState(() {
            _userData = {
              'id': user.id,
              'email': user.email,
              'first_name': user.userMetadata?['name']?.split(' ')[0] ?? user.email?.split('@')[0] ?? 'User',
              'last_name': user.userMetadata?['name']?.split(' ').length > 1 ? 
                          user.userMetadata!['name'].split(' ').sublist(1).join(' ') : '',
              'photo_url': user.userMetadata?['avatar_url'],
              'created_at': user.createdAt,
            };
          });
          print('Using auth metadata as fallback');
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _loadBooksFromSupabase() async {
    setState(() => _isLoadingBooks = true);
    try {
      final response = await supabase
          .from('books')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      setState(() {
        _books = response.map((book) => Map<String, dynamic>.from(book)).toList();
      });
    } catch (e) {
      print('Error loading books: $e');
    } finally {
      setState(() => _isLoadingBooks = false);
    }
  }

  // Update the _loadUserFavorites method
  Future<void> _loadUserFavorites() async {
    setState(() => _isLoadingFavorites = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('users')
            .select('Favourites') // Use lowercase 'favourites'
            .eq('id', user.id)
            .single();
        
        final favorites = response['Favourites']; // Use lowercase 'favourites'
        if (favorites != null) {
          if (favorites is String) {
            setState(() {
              _favoriteBookIds = favorites.split(',').where((id) => id.isNotEmpty).toSet();
            });
          } else if (favorites is List) {
            setState(() {
              _favoriteBookIds = favorites.map((id) => id.toString()).toSet();
            });
          }
        }
        print('Loaded favorites: $_favoriteBookIds');
      }
    } catch (e) {
      print('Error loading favorites: $e');
    } finally {
      setState(() => _isLoadingFavorites = false);
    }
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  // Replace the _getUserDisplayName method to handle first_name and last_name
  String _getUserDisplayName() {
    if (_isLoadingUser) {
      return 'Loading...';
    }
    final user = supabase.auth.currentUser;
    String name = '';
    if (user != null) {
      // Try to get name from first_name and last_name
      if (_userData?['first_name'] != null || _userData?['last_name'] != null) {
        final firstName = _userData?['first_name'] ?? '';
        final lastName = _userData?['last_name'] ?? '';
        name = '$firstName $lastName'.trim();
      } else {
        name = _userData?['full_name'] ??
               _userData?['name'] ??
               user.userMetadata?['name'] ??
               user.email?.split('@')[0] ??
               'User';
      }
    } else {
      name = 'Guest';
    }
    // Show only the first two words
    final words = name.split(' ');
    return words.length > 2 ? '${words[0]} ${words[1]}' : name;
  }

  // Add this method to toggle favorite status
  Future<void> _toggleFavorite(String bookId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showSnackBar('Please login to add favorites');
        return;
      }

      final isFavorite = _favoriteBookIds.contains(bookId);
      
      setState(() {
        if (isFavorite) {
          _favoriteBookIds.remove(bookId);
        } else {
          _favoriteBookIds.add(bookId);
        }
      });

      final favoritesString = _favoriteBookIds.join(',');
      
      await supabase.from('users')
          .update({'Favourites': favoritesString}) // Use lowercase 'favourites'
          .eq('id', user.id);

      if (mounted) {
        _showSnackBar(
          isFavorite 
              ? 'Removed from favorites' 
              : 'Added to favorites',
        );
      }

      print('Updated favorites in database: $favoritesString');

    } catch (e) {
      print('Error toggling favorite: $e');
      
      setState(() {
        if (_favoriteBookIds.contains(bookId)) {
          _favoriteBookIds.remove(bookId);
        } else {
          _favoriteBookIds.add(bookId);
        }
      });

      if (mounted) {
        _showSnackBar('Failed to update favorites: ${e.toString()}');
      }
    }
  }

  // Update the _showSnackBar method to handle different colors
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

  // Replace the _buildProfileDrawer method with this scrollable version
  Widget _buildProfileDrawer() {
    final user = supabase.auth.currentUser;
    final profileImageUrl = _userData?['photo_url'] ?? 
                           _userData?['avatar_url'] ?? 
                           user?.userMetadata?['avatar_url'];

    final userDisplayData = {
      'name': _userData?['full_name'] ?? _userData?['firstName'] ?? _userData?['name'] ?? 
              user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'] ?? 'User',
      'id': _userData?['email']?.split('@')[0] ?? user?.email?.split('@')[0] ?? 
            _userData?['id']?.toString().substring(0, 8) ?? 'BS 1754',
      'books': _userData?['booksRead'] ?? 100,
      'friends': _userData?['friends'] ?? 1245,
      'following': _userData?['following'] ?? 8,
      'joined': _userData?['created_at'] != null
          ? _formatDate(_userData!['created_at'])
          : 'Month DD YEAR',
      'genres': _userData?['favoriteGenres'] ?? 'Romance, Mystery/Thriller, Fantasy, Science Fiction, +5 More',
      'photoURL': profileImageUrl,
    };

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0096C7),
              Color(0xFF00B4D8),
              Color(0xFFF8F9FA),
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header section with profile info
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                  child: Column(
                    children: [
                      // Close button and title - FIX: Add the missing Row content
                     
                      const SizedBox(height: 20),
                      
                      // Profile avatar
                      GestureDetector(
                        onTap: _updateProfileImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              child: profileImageUrl == null || profileImageUrl.isEmpty
                                  ? const Icon(Icons.person, size: 60, color: Color(0xFF00B4D8))
                                  : null,
                            ),
                            
                            // Upload indicator overlay
                            if (_isUploadingImage)
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Camera icon
                            if (!_isUploadingImage)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Color(0xFF00B4D8),
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // User name
                      Text(
                        userDisplayData['name'] as String,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                           
                      const SizedBox(height: 4),
                      
                      // User ID
                      Text(
                        userDisplayData['id'] as String,
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stats section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.menu_book,
                        value: userDisplayData['books'].toString(),
                        label: 'Books',
                      ),
                      _buildVerticalDivider(),
                      _buildStatItem(
                        icon: Icons.people,
                        value: userDisplayData['friends'].toString(),
                        label: 'Friends',
                      ),
                      _buildVerticalDivider(),
                      _buildStatItem(
                        icon: Icons.person_add,
                        value: userDisplayData['following'].toString(),
                        label: 'Following',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Menu items section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildDrawerMenuItem(
                        icon: Icons.edit,
                        title: 'Edit Profile',
                        onTap: () {
                          Navigator.pop(context);
                          _showEditProfileDialog();
                        },
                      ),
                      
                      _buildDrawerMenuItem(
                        icon: Icons.library_books,
                        title: 'My Books',
                        onTap: () {
                          Navigator.pop(context);
                          // Add your my books navigation here
                        },
                      ),
                      
                      _buildDrawerMenuItem(
                        icon: Icons.favorite,
                        title: 'Favorites',
                        onTap: () async {
                          Navigator.pop(context); // Close drawer
                          
                          // ✅ Navigate and wait for result
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FavoritesPage(
                                onFavoritesChanged: () {
                                  // ✅ Reload favorites when changed
                                  _loadUserFavorites();
                                },
                              ),
                            ),
                          );
                          
                          // ✅ Also reload when returning from favorites page
                          _loadUserFavorites();
                        },
                      ),
                      
                      _buildDrawerMenuItem(
                        icon: Icons.bookmark,
                        title: 'Reading List',
                        onTap: () {
                          Navigator.pop(context);
                          // Add your reading list navigation here
                        },
                      ),
                      
                      _buildDrawerMenuItem(
                        icon: Icons.history,
                        title: 'Reading History',
                        onTap: () {
                          Navigator.pop(context);
                          // Add your reading history navigation here
                        },
                      ),
                      
                      _buildDrawerMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.pop(context);
                          // Add your help navigation here
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Logout button
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 30),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showLogoutDialog();
                          },
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: Text(
                            'Logout',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      // Footer info
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Text(
                              'TaleHive Digital Community',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version 1.0.0',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
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
        ),
      ));
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  })  {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF0096C7),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0096C7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0096C7),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF64748B),
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.white,
      ),
    );
  }

  Future<void> _updateProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final bytes = await File(image.path).readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload to Supabase Storage
      await supabase.storage
          .from('avatars')
          .uploadBinary(fileName, bytes);

      final imageUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // Only update users table (remove profiles table fallback)
      try {
        await supabase.from('users')
            .update({'photo_url': imageUrl})
            .eq('id', user.id);
        print('Successfully updated users table with new image');
      } catch (e) {
        print('Could not update users table: $e');
        throw Exception('Failed to update profile image in database: $e');
      }

      // Update auth metadata
      await supabase.auth.updateUser(UserAttributes(
        data: {'avatar_url': imageUrl},
      ));

      // Reload user data to refresh UI
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Profile image updated successfully!',
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }

    } catch (e) {
      print('Error updating profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to update image: ${e.toString()}',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showEditProfileDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit Profile',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.7,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: _EditProfilePopup(
                userData: _userData,
                onSave: _updateUserProfile,
                onCancel: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        );
      },
    );
  }

  // Replace the _updateUserProfile method with this corrected version
  Future<void> _updateUserProfile(Map<String, dynamic> updatedData) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      print('Updating profile with data: $updatedData'); // Debug log

      // Only update users table (remove profiles table fallback)
      try {
        await supabase.from('users')
            .update(updatedData)
            .eq('id', user.id);
        print('Successfully updated users table');
      } catch (e) {
        print('Could not update users table: $e');
        throw Exception('Failed to update profile in database: $e');
      }

      // Update auth metadata if name changed (use first_name for metadata)
      if (updatedData['first_name'] != null) {
        try {
          await supabase.auth.updateUser(UserAttributes(
            data: {
              'full_name': '${updatedData['first_name']} ${updatedData['last_name'] ?? ''}'.trim(),
              'name': updatedData['first_name'],
            },
          ));
          print('Successfully updated auth metadata');
        } catch (e) {
          print('Could not update auth metadata: $e');
        }
      }

      // Reload user data
      await _loadUserData();

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Profile updated successfully!',
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }

    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to update profile: ${e.toString()}',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _performLogout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged out successfully',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error logging out: $e',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Month DD YEAR';
    try {
      DateTime? date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.tryParse(timestamp);
      }
      if (date != null) {
        const months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return '${months[date.month - 1]} ${date.day} ${date.year}';
      }
      return 'Month DD YEAR';
    } catch (e) {
      return 'Month DD YEAR';
    }
  }

  // Add this helper method for the about dialog
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0096C7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info,
                  color: Color(0xFF0096C7),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'About TaleHive',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TaleHive Library Management System',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version: 1.0.0',
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Developed by: TaleHive Team',
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Year: 2025',
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                'Your gateway to endless stories and knowledge. Discover, read, and share amazing books with our community.',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0096C7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Close',
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

  // Add the missing _showLogoutDialog method
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
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
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
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

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: _buildProfileDrawer(),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 80,
              floating: true,
              pinned: false,
              backgroundColor: const Color(0xFFF8F9FA),
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF22223b)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Color(0xFF22223b)),
                  onPressed: () {},
                ),
              
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'TaleHive',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF22223b),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Banner
                    _GreetingBanner(
                      userName: _getUserDisplayName(),
                      greeting: _getGreeting(),
                      isLoading: _isLoadingUser,
                      userData: _userData,
                      currentUser: user,
                      onProfileTap: () => _scaffoldKey.currentState?.openDrawer(),
                    ),

                    const SizedBox(height: 24),

                    // Quote Carousel
                    _QuoteCarousel(quotes: quotes),

                    const SizedBox(height: 32),

                    // New Arrivals Section
                    const _SectionTitle(title: 'New Arrivals'),
                    const SizedBox(height: 16),
                    _isLoadingBooks
                        ? const Center(child: CircularProgressIndicator())
                        : _HorizontalBookList(books: newArrivals, label: 'NEW'),

                    const SizedBox(height: 32),

                    // Popular Books Section
                    const _SectionTitle(title: 'Popular Books'),
                    const SizedBox(height: 16),
                    _isLoadingBooks
                        ? const Center(child: CircularProgressIndicator())
                        : _HorizontalBookList(books: popularBooks, label: 'POPULAR'),

                    const SizedBox(height: 32),

                    // Book Club Banner
                    _BookClubBanner(),

                    const SizedBox(height: 32),

                    // Recommended Section
                    const _SectionTitle(title: 'Recommended for You'),
                    const SizedBox(height: 16),
                    _isLoadingBooks
                        ? const Center(child: CircularProgressIndicator())
                        : _RecommendedList(books: recommended),

                    const SizedBox(height: 32),

                    // Recent Readings Section
                    const _SectionTitle(title: 'Recent Readings'),
                    const SizedBox(height: 16),
                    _isLoadingBooks
                        ? const Center(child: CircularProgressIndicator())
                        : _RecentReadingsList(books: recentReadings),

                    const SizedBox(height: 32),

                    // Footer
                    _Footer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Also fix the drawer header - add the missing Row content after line 400:






  // Replace the _updateUserProfile method with this corrected version



  // Add this helper method for the about dialog

  // Add the missing _showLogoutDialog method
}

// Greeting Banner Widget
class _GreetingBanner extends StatelessWidget {
  final String userName;
  final String greeting;
  final bool isLoading;
  final Map<String, dynamic>? userData;
  final User? currentUser;
  final VoidCallback? onProfileTap;

  const _GreetingBanner({
    required this.userName,
    required this.greeting,
    required this.isLoading,
    required this.userData,
    required this.currentUser,
    this.onProfileTap,
  });

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
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: _buildProfileAvatar(context),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      isLoading ? 'Loading...' : userName,
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentUser != null 
                ? 'Welcome back! Start your reading journey' 
                : 'Start your day with a book',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: currentUser != null 
                        ? 'Search your library...' 
                        : 'Request for a BOOK? or Search...',
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

  Widget _buildProfileAvatar(BuildContext context) {
    if (isLoading) {
      return const CircleAvatar(
        radius: 32,
        backgroundColor: Colors.white,
        child: CircularProgressIndicator(
          color: Color(0xFF0096C7),
          strokeWidth: 2,
        ),
      );
    }

    String? photoURL = userData?['photo_url'] ?? 
                    userData?['avatar_url'] ?? 
                    currentUser?.userMetadata?['avatar_url'];
    
    return GestureDetector(
      onTap: onProfileTap,
      child: CircleAvatar(
        radius: 32,
        backgroundColor: Colors.white,
        backgroundImage: photoURL != null && photoURL.isNotEmpty 
            ? NetworkImage(photoURL)
            : null,
        onBackgroundImageError: photoURL != null ? (exception, stackTrace) {
          print('Failed to load profile image: $exception');
        } : null,
        child: photoURL == null || photoURL.isEmpty
            ? Text(
                _getInitial(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0096C7),
                ),
              )
            : null,
      ),
    );
  }

  String _getInitial() {
    return currentUser?.userMetadata?['name']?.isNotEmpty == true 
        ? currentUser!.userMetadata!['name'][0].toUpperCase()
        : currentUser?.email?.isNotEmpty == true
            ? currentUser!.email![0].toUpperCase()
            : 'U';
  }
}

// Quote Carousel Widget
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
                () => _current = (_current - 1 + widget.quotes.length) % widget.quotes.length,
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

// Section Title Widget
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

// Horizontal Book List Widget
class _HorizontalBookList extends StatelessWidget {
  final List<Map<String, dynamic>> books;
  final String? label;
  const _HorizontalBookList({required this.books, this.label});
  
  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Text(
            'No books available',
            style: GoogleFonts.montserrat(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        separatorBuilder: (context, i) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final book = books[i];
          return _buildPopularBookCard(context, book, i == 0 ? label : null);
        },
      ),
    );
  }

  // Replace the _buildPopularBookCard method in _HorizontalBookList
  Widget _buildPopularBookCard(BuildContext context, Map<String, dynamic> book, String? label) {
    final bookId = book['id']?.toString() ?? '';
    
    return GestureDetector(
      onTap: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
        
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pop(context);
        
        // ✅ Add callback support
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsPage(
              bookId: bookId,
              onFavoriteChanged: () {
                // ✅ Reload favorites when changed
                final parentState = context.findAncestorStateOfType<_UserHomePageState>();
                if (parentState != null) {
                  parentState._loadUserFavorites();
                }
              },
            ),
          ),
        );
        
        // ✅ Also reload when returning
        final parentState = context.findAncestorStateOfType<_UserHomePageState>();
        if (parentState != null) {
          parentState._loadUserFavorites();
        }
      },
      child: Container(
        width: 150,
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
          children: [
            // Header with label and favorite icon
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Label (if exists)
                  if (label != null)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB5179E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                
                  if (label != null) const SizedBox(width: 4),
                
                  // Favorite icon
                  GestureDetector(
                    onTap: () {
                      // Get the parent state to access _toggleFavorite
                      final parentState = context.findAncestorStateOfType<_UserHomePageState>();
                      if (parentState != null && bookId.isNotEmpty) {
                        parentState._toggleFavorite(bookId);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Builder(
                        builder: (context) {
                          final parentState = context.findAncestorStateOfType<_UserHomePageState>();
                          final isFavorite = parentState?._favoriteBookIds.contains(bookId) ?? false;
                          
                          return Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey[600],
                            size: 16,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Book image
            Container(
              height: 110,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  book['cover_image_url'] ?? '',
                  width: double.infinity,
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
                        size: 35,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Book details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        book['title'] ?? 'No Title',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    if (book['author_name'] != null && book['author_name'].toString().trim().isNotEmpty)
                      Text(
                        book['author_name'],
                        style: const TextStyle(
                          color: Colors.blueGrey, 
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        const Text(
                          '4.5',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ));
    }
}

// Recommended List Widget
class _RecommendedList extends StatelessWidget {
  final List<Map<String, dynamic>> books;
  const _RecommendedList({required this.books});
  
  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Text(
            'No recommendations available',
            style: GoogleFonts.montserrat(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        separatorBuilder: (context, i) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final book = books[i];
          return _buildRecommendedBookCard(context, book);
        },
      ));
  }

  // Replace the _buildRecommendedBookCard method in _RecommendedList
  Widget _buildRecommendedBookCard(BuildContext context, Map<String, dynamic> book) {
    final bookId = book['id']?.toString() ?? '';
    
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsPage(
              bookId: bookId,
              onFavoriteChanged: () {
                final parentState = context.findAncestorStateOfType<_UserHomePageState>();
                if (parentState != null) {
                  parentState._loadUserFavorites();
                }
              },
            ),
          ),
        );
        
        // Reload when returning
        final parentState = context.findAncestorStateOfType<_UserHomePageState>();
        if (parentState != null) {
          parentState._loadUserFavorites();
        }
      },
      child: Container(
        width: 160,
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
          children: [
            // Header with favorite icon
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      final parentState = context.findAncestorStateOfType<_UserHomePageState>();
                      if (parentState != null && bookId.isNotEmpty) {
                        parentState._toggleFavorite(bookId);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Builder(
                        builder: (context) {
                          final parentState = context.findAncestorStateOfType<_UserHomePageState>();
                          final isFavorite = parentState?._favoriteBookIds.contains(bookId) ?? false;
                          
                          return Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey[600],
                            size: 18,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Book image
            Container(
              height: 120,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  book['cover_image_url'] ?? '',
                  width: double.infinity,
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
            
            // Book details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        book['title'] ?? 'No Title',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                    ),
                    
                    if (book['author_name'] != null && book['author_name'].toString().trim().isNotEmpty)
                      Container(
                        height: 16,
                        margin: const EdgeInsets.only(top: 4),
                        child: Text(
                          book['author_name'],
                          style: const TextStyle(
                            color: Colors.blueGrey, 
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    const Spacer(),
                    
                    Container(
                      height: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            '4.5',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
      ));
    }
}

// Recent Readings List Widget
class _RecentReadingsList extends StatelessWidget {
  final List<Map<String, dynamic>> books;
  const _RecentReadingsList({required this.books});
  
  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Text(
            'No recent readings',
            style: GoogleFonts.montserrat(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        separatorBuilder: (context, i) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final book = books[i];
          return _buildRecentBookCard(context, book);
        },
      ),
    );
  }

  // In the _RecentReadingsList class, update the _buildRecentBookCard method
  Widget _buildRecentBookCard(BuildContext context, Map<String, dynamic> book) {
    final bookId = book['id']?.toString() ?? '';
    
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsPage(
              bookId: bookId,
              onFavoriteChanged: () {
                final parentState = context.findAncestorStateOfType<_UserHomePageState>();
                if (parentState != null) {
                  parentState._loadUserFavorites();
                }
              },
            ),
          ),
        );
        
        // Reload when returning
        final parentState = context.findAncestorStateOfType<_UserHomePageState>();
        if (parentState != null) {
          parentState._loadUserFavorites();
        }
      },
      child: Container(
        width: 140,
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
          children: [
            // Header with favorite icon
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      final parentState = context.findAncestorStateOfType<_UserHomePageState>();
                      if (parentState != null && bookId.isNotEmpty) {
                        parentState._toggleFavorite(bookId);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Builder(
                        builder: (context) {
                          final parentState = context.findAncestorStateOfType<_UserHomePageState>();
                          final isFavorite = parentState?._favoriteBookIds.contains(bookId) ?? false;
                          
                          return Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey[600],
                            size: 16,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Book image
            Container(
              height: 100,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  book['cover_image_url'] ?? '',
                  width: double.infinity,
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
                        size: 35,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Book details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        book['title'] ?? 'No Title',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ),
                    
                    if (book['author_name'] != null && book['author_name'].toString().trim().isNotEmpty)
                      Container(
                        height: 16,
                        margin: const EdgeInsets.only(top: 4),
                        child: Text(
                          book['author_name'],
                          style: const TextStyle(
                            color: Colors.blueGrey, 
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    const Spacer(),
                    
                    Container(
                      height: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          const Text(
                            '4.5', 
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
      ));
    }
}

// Footer Widget
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Divider(color: Colors.grey[300], thickness: 1),
          const SizedBox(height: 16),
          
          Text(
            'TaleHive Library',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0096C7),
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Your gateway to endless stories and knowledge',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.copyright,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                '2025 TaleHive Team. All rights reserved.',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Version 1.0.0',
            style: GoogleFonts.montserrat(
              color: Colors.grey[400],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookClubBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BookClubPage(),
          ),
        );
      },
      child: Container(
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.black26,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'TaleHive Book Club',
                    style: TextStyle(
                      color: const Color(0xFF0096C7).withOpacity(0.85),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF0096C7),
                    size: 16,
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

// Replace the _EditProfilePopup class with this updated version
class _EditProfilePopup extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final ValueChanged<Map<String, dynamic>> onSave;
  final VoidCallback onCancel;

  const _EditProfilePopup({
    Key? key,
    required this.userData,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  __EditProfilePopupState createState() => __EditProfilePopupState();
}

class __EditProfilePopupState extends State<_EditProfilePopup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _genresController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Combine first_name and last_name for display
    String fullName = '';
    if (widget.userData?['first_name'] != null || widget.userData?['last_name'] != null) {
      final firstName = widget.userData?['first_name'] ?? '';
      final lastName = widget.userData?['last_name'] ?? '';
      fullName = '$firstName $lastName'.trim();
    } else {
      fullName = widget.userData?['full_name'] ?? '';
    }
    
    _nameController = TextEditingController(text: fullName);
    _emailController = TextEditingController(text: widget.userData?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.userData?['contact_no'] ?? widget.userData?['phone'] ?? '');
    _genresController = TextEditingController(text: widget.userData?['favorite_genres'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genresController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final updatedData = <String, dynamic>{};
      
      // Split full name into first_name and last_name (remove full_name)
      if (_nameController.text.trim().isNotEmpty) {
        final nameParts = _nameController.text.trim().split(' ');
        if (nameParts.isNotEmpty) {
          updatedData['first_name'] = nameParts.first;
          if (nameParts.length > 1) {
            updatedData['last_name'] = nameParts.sublist(1).join(' ');
          } else {
            updatedData['last_name'] = '';
          }
          // Don't include full_name since it doesn't exist in the database
        }
      }
      
      // Save phone as contact_no
      if (_phoneController.text.trim().isNotEmpty) {
        updatedData['contact_no'] = _phoneController.text.trim();
      }
      
      // Save favorite genres
      if (_genresController.text.trim().isNotEmpty) {
        updatedData['favorite_genres'] = _genresController.text.trim();
      }
      
      widget.onSave(updatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500), // Reduced height since fewer fields
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00B4D8), Color(0xFF0096C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Edit Profile',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextFormField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person,
                            hint: 'Enter your first and last name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            enabled: false,
                            hint: 'Email cannot be changed',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            hint: 'Enter your contact number',
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                // Basic phone validation
                                if (value.trim().length < 10) {
                                  return 'Please enter a valid phone number';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _genresController,
                            label: 'Favorite Genres',
                            icon: Icons.category,
                            hint: 'e.g., Romance, Mystery, Sci-Fi, Fantasy',
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.montserrat(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B4D8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Save Changes',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold,
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
      ));
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.montserrat(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF00B4D8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00B4D8), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: GoogleFonts.montserrat(
          color: enabled ? const Color(0xFF64748B) : Colors.grey[400],
        ),
        hintStyle: GoogleFonts.montserrat(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
    );
  }
}

