import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'user_dashboard.dart';
import '../club/book_club.dart';
import 'book_details.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  // Firebase Auth variables
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;

  final quotes = [
    "There is more treasure in books than in all the pirate's loot on Treasure Island. - Walt Disney",
    "A room without books is like a body without a soul. - Cicero",
    "Books are a uniquely portable magic. - Stephen King",
  ];

  // Google Drive setup for thumbnails
  GoogleSignInAccount? _account;
  List<Map<String, dynamic>> _firestoreBooks = [];
  bool _isLoadingBooks = false;
  final Map<String, String> _thumbnailCache = {};

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.readonly',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  // Dynamic data from Firestore books
  List<Map<String, dynamic>> get newArrivals => _firestoreBooks.take(3).toList();
  List<Map<String, dynamic>> get recommended => _firestoreBooks.skip(3).take(5).toList();
  List<Map<String, dynamic>> get popularBooks => _firestoreBooks.skip(8).take(4).toList();
  List<Map<String, dynamic>> get recentReadings => _firestoreBooks.skip(12).take(5).toList();

  final onlineUsers = ['Noushin Nurjahan', 'Other users (?)', 'User 3'];

  @override
  void initState() {
    super.initState();
    _initializeUserSession();
    _loadBooksFromFirestore();
    _initializeGoogleSignIn();
  }

  // Initialize user session - Fixed version
  void _initializeUserSession() async {
    print('🔐 Initializing user session...');
    
    // Check current user first
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {

      await _fetchUserData(currentUser);
    } else {
      print('❌ No user logged in');
      setState(() {
        _currentUser = null;
        _userData = null;
        _isLoadingUser = false;
      });
    }

    // Listen for auth state changes
    _auth.authStateChanges().listen((User? user) async {
      print('🔄 Auth state changed: ${user?.email ?? 'null'}');
      if (user != null && user != _currentUser) {
        await _fetchUserData(user);
      } else if (user == null) {
        setState(() {
          _currentUser = null;
          _userData = null;
          _isLoadingUser = false;
        });
      }
    });
  }

  // Fetch user data from Firestore - Fixed version
  Future<void> _fetchUserData(User user) async {
    print('📥 Fetching user data for: ${user.email}');
    
    try {
      setState(() {
        _currentUser = user;
        _isLoadingUser = true;
      });

      // Fetch user data from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print('✅ User data found in Firestore: ${userData['name']}');
        
        setState(() {
          _userData = userData;
          _isLoadingUser = false;
        });
      } else {
        print('⚠️ User not found in Firestore, creating new document...');
        
        // Create user document if it doesn't exist
        Map<String, dynamic> newUserData = {
          'uid': user.uid,
          'email': user.email,
          'firstName': user.displayName?.split(' ').first ?? 'User',
          'name': user.displayName ?? 'User',
          'photoURL': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'booksRead': 0,
          'favoriteGenres': 'Fiction, Science',
        };

        await _firestore.collection('users').doc(user.uid).set(newUserData);
        print('✅ New user document created');
        
        setState(() {
          _userData = newUserData;
          _isLoadingUser = false;
        });
      }

      // Update last login time
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('❌ Error fetching user data: $e');
      setState(() {
        _userData = {
          'name': user.displayName ?? 'User',
          'email': user.email ?? '',
          'photoURL': user.photoURL ?? '',
        };
        _isLoadingUser = false;
      });
    }
  }

  // Helper methods for greeting and user name
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

  String _getUserDisplayName() {
    if (_isLoadingUser) {
      return 'Loading...';
    } else if (_currentUser != null) {
      // Try firstName first, then fallback to other sources
      String name = _userData?['firstName'] ?? 
                    _userData?['name'] ?? 
                    _currentUser!.displayName ?? 
                    _currentUser!.email?.split('@')[0] ?? 
                    'User';
      return name;
    } else {
      return 'Guest';
    }
  }

  String _getUserFirstName() {
    String fullName = _getUserDisplayName();
    if (fullName == 'Loading...' || fullName == 'Guest') {
      return fullName;
    }
    return fullName.split(' ').first;
  }

  // Initialize Google Sign-In for thumbnail generation
  Future<void> _initializeGoogleSignIn() async {
    try {
      _account = await _googleSignIn.signInSilently();
      if (_account == null) {
        print('Google Sign-In not available for thumbnails');
      } else {
        print('Signed in as: ${_account!.email} for thumbnails');
      }
    } catch (e) {
      print('Google Sign-In initialization failed: $e');
    }
  }

  // Load books from Firestore
  Future<void> _loadBooksFromFirestore() async {
    if (_isLoadingBooks) return;

    setState(() {
      _isLoadingBooks = true;
    });

    try {
      print('Loading books from Firestore...');

      QuerySnapshot querySnapshot = await _firestore.collection('Books').get();
      List<Map<String, dynamic>> loadedBooks = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> bookData = doc.data() as Map<String, dynamic>;
        bookData['id'] = doc.id;
        
        // Ensure we have the required fields for display
        bookData['title'] = bookData['title'] ?? 'Unknown Title';
        bookData['author'] = bookData['author'] ?? bookData['authorName'] ?? '';
        bookData['category'] = bookData['bookType'] ?? bookData['category'] ?? 'General';
        bookData['rating'] = bookData['rating'] ?? _generateRating();
        
        // Use Google Drive thumbnail if file ID is available
        if (bookData['googleDriveFileId'] != null) {
          bookData['cover'] = 'https://drive.google.com/thumbnail?id=${bookData['googleDriveFileId']}&sz=w400-h500';
        } else {
          bookData['cover'] = null;
        }

        loadedBooks.add(bookData);
      }

      setState(() {
        _firestoreBooks = loadedBooks;
      });

      print('✅ Loaded ${_firestoreBooks.length} books');
     
    } catch (error) {
      print('Error loading books from Firestore: $error');
      _showSnackBar('Error loading books: ${error.toString()}');
    } finally {
      setState(() {
        _isLoadingBooks = false;
      });
    }
  }

  double _generateRating() {
    return 3.5 + (DateTime.now().millisecondsSinceEpoch % 150) / 100;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(),
        ),
        backgroundColor: const Color(0xFF0096C7),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: SafeArea(
        child: LayoutBuilder(
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
                      // Debug info (remove in production)
                      if (_isLoadingUser)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🔄 Loading user session...',
                            style: GoogleFonts.montserrat(fontSize: 12),
                          ),
                        ),
                      if (!_isLoadingUser && _currentUser != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),

                        ),
                      if (!_isLoadingUser && _currentUser == null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '❌ No user logged in',
                            style: GoogleFonts.montserrat(fontSize: 12),
                          ),
                        ),

                      // Greeting Banner - Updated to use dynamic name
                      _GreetingBanner(
                        userName: _getUserFirstName(),
                        greeting: _getGreeting(),
                        isLoading: _isLoadingUser,
                        userData: _userData,
                        currentUser: _currentUser,
                        onEditProfile: _showEditProfileDialog, // Add this
                      ),
                      const SizedBox(height: 18),
                      // Quote/Highlight Section
                      _QuoteCarousel(quotes: quotes),
                      const SizedBox(height: 18),
                      // Loading indicator
                      if (_isLoadingBooks) _buildLoadingSection(),
                      // Show sections only if books are loaded
                      if (_firestoreBooks.isNotEmpty) ...[
                        // New Releases & Arrivals
                        _SectionTitle(title: 'New Releases'),
                        _HorizontalBookList(
                          books: newArrivals,
                          label: 'New Arrivals',
                        ),
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
                      ] else if (!_isLoadingBooks) ...[
                        // Empty state
                        _buildEmptyState(),
                        const SizedBox(height: 18),
                      ],
                      // Special Club Banner
                      _BookClubBanner(),
                      const SizedBox(height: 18),
                      // Footer
                      _Footer(),
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
                          // User info card
                          if (_currentUser != null)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'User Profile',
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Name: ${_getUserDisplayName()}'),
                                    Text('Email: ${_currentUser!.email}'),
                                    Text('Books Read: ${_userData?['booksRead'] ?? 0}'),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          // Refresh button
                          ElevatedButton.icon(
                            onPressed: _loadBooksFromFirestore,
                            icon: _isLoadingBooks
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(_isLoadingBooks ? 'Loading...' : 'Refresh Books'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0096C7),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: !isWide(context) ? FloatingActionButton(
        onPressed: _loadBooksFromFirestore,
        backgroundColor: const Color(0xFF0096C7),
        child: _isLoadingBooks
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.refresh, color: Colors.white),
      ) : null,
    );
  }

  bool isWide(BuildContext context) {
    return MediaQuery.of(context).size.width > 1100;
  }

  Widget _buildLoadingSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF0096C7),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading books from library...',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching books from Firestore database',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.library_books,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No books in library yet',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask authors to publish books or contact admin',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Profile Picture',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: _userData?['photoURL'] != null && _userData!['photoURL'].isNotEmpty
                  ? NetworkImage(_userData!['photoURL'])
                  : null,
              child: _userData?['photoURL'] == null || _userData!['photoURL'].isEmpty
                  ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                  : null,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _updateProfilePicture(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0096C7),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _updateProfilePicture(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0096C7),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfilePicture(ImageSource source) async {
    Navigator.pop(context); // Close dialog
    
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0096C7)),
              const SizedBox(height: 16),
              Text(
                'Updating profile picture...',
                style: GoogleFonts.montserrat(),
              ),
            ],
          ),
        ),
      );

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null && _currentUser != null) {
        // Upload to Firebase Storage
        String downloadUrl = await _uploadImageToFirebase(File(image.path));
        
        // Update Firestore user document
        await _firestore.collection('users').doc(_currentUser!.uid).update({
          'photoURL': downloadUrl,
        });

        // Update local state
        setState(() {
          _userData?['photoURL'] = downloadUrl;
        });

        Navigator.pop(context); // Close loading dialog
        _showSnackBar('Profile picture updated successfully!');
      } else {
        Navigator.pop(context); // Close loading dialog
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showSnackBar('Error updating profile picture: ${e.toString()}');
    }
  }

  Future<String> _uploadImageToFirebase(File imageFile) async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final String fileName = 'profile_${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = storage.ref().child('profile_pictures').child(fileName);
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}

// Updated _GreetingBanner to accept dynamic data
class _GreetingBanner extends StatelessWidget {
  final String userName;
  final String greeting;
  final bool isLoading;
  final Map<String, dynamic>? userData;
  final User? currentUser;
  final VoidCallback? onEditProfile; // Add this

  const _GreetingBanner({
    required this.userName,
    required this.greeting,
    required this.isLoading,
    this.userData,
    this.currentUser,
    this.onEditProfile, // Add this
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
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: _buildProfileAvatar(context), // Pass context here
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

    // Check if user has photo URL
    String? photoURL = userData?['photoURL'] ?? currentUser?.photoURL;
    
    return GestureDetector(
      onTap: () {
        // Navigate to user dashboard
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDashboardPage(
              userData: userData,
              onMyBooksTap: () {
                Navigator.pop(context);
              },
              onEditProfileTap: () {
                Navigator.pop(context);
                _showEditProfileFromBanner();
              },
            ),
          ),
        );
      },
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
    return currentUser?.displayName?.isNotEmpty == true 
        ? currentUser!.displayName![0].toUpperCase()
        : currentUser?.email?.isNotEmpty == true
            ? currentUser!.email![0].toUpperCase()
            : 'U';
  }

  void _showEditProfileFromBanner() {
    if (onEditProfile != null) {
      onEditProfile!();
    }
  }
}

// --- Components (Updated to handle dynamic data) ---

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
    if (books.isEmpty) {
      return Container(
        height: 150,
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

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, i) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final book = books[i];
          return GestureDetector(  // Add this
            onTap: () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // Small delay to show loading
              await Future.delayed(const Duration(milliseconds: 300));
              
              // Close loading dialog
              Navigator.pop(context);
              
              // Navigate to book details
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailsPage(
                    bookId: book['id'] ?? 'mock',
                  ),
                ),
              );
            },
            child: ConstrainedBox(
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
                        child: Image.network(
                          book['cover'] ?? '',
                          width: 70,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0096C7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf,
                                color: Color(0xFF0096C7),
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 90,
                        child: Text(
                          book['title'] ?? 'No Title',
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
    if (books.isEmpty) {
      return Container(
        height: 190,
        child: Center(
          child: Text(
            'No recommendations available',
            style: GoogleFonts.montserrat(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, i) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final book = books[i];
          return GestureDetector(  // Add this
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailsPage(
                    bookId: book['id'] ?? 'mock',
                  ),
                ),
              );
            },
            child: ConstrainedBox(
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
                        child: Image.network(
                          book['cover'] ?? '',
                          width: 70,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0096C7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf,
                                color: Color(0xFF0096C7),
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book['title'] ?? 'No Title',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (book['author'] != null && book['author'].toString().trim().isNotEmpty)
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
                            '${book['rating']?.toStringAsFixed(1) ?? '4.5'}',
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
    if (books.isEmpty) {
      return Container(
        height: 150,
        child: Center(
          child: Text(
            'No recent readings',
            style: GoogleFonts.montserrat(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, i) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final book = books[i];
          return GestureDetector(  // Add this
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailsPage(
                    bookId: book['id'] ?? 'mock',
                  ),
                ),
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Container(
                height: 140,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          book['cover'] ?? '',
                          width: 60,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0096C7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf,
                                color: Color(0xFF0096C7),
                                size: 25,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book['title'] ?? 'No Title',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (book['author'] != null && book['author'].toString().trim().isNotEmpty)
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
                          '${book['rating']?.toStringAsFixed(1) ?? '4.5'}',
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
    return GestureDetector(  // Add GestureDetector to make it clickable
      onTap: () {
        // Navigate to Book Club page
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
                child: Row(  // Change to Row to add an icon
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'TaleHive Book Club',
                      style: TextStyle(
                        color: Color(0xFF0096C7),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF0096C7),
                      size: 16,
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
            'TaleHive (C) - 2025. ALL RIGHTS RESERVED.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          SizedBox(height: 4),
        ],
      ),
    );
  }
}
