import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../main_home_page/main_page.dart';
import '../pdf_preview/pdf_viewer_page.dart';

// Club system imports
import '../../services/club_service.dart';
import '../../models/club_model.dart';
import '../../models/author_earnings_model.dart';
import 'club_members_page.dart';
import 'club_books_page.dart';
import 'club_payments_page.dart';
import 'club_analytics_page.dart';

class AuthorDashboardPage extends StatefulWidget {
  const AuthorDashboardPage({Key? key}) : super(key: key);

  @override
  State<AuthorDashboardPage> createState() => _AuthorDashboardPageState();
}

class _AuthorDashboardPageState extends State<AuthorDashboardPage> {
  final supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  final ClubService _clubService = ClubService();

  final author = {
  'first_name': 'Md Raiyan',
  'last_name': 'Buhiyan',
    'bio': 'Award-winning author of modern fiction. Passionate about storytelling and inspiring readers.',
    'avatar': 'Asset/images/loren.jpg',
    'email': 'loreen@email.com',
  };

  List<Map<String, dynamic>> books = [];
  bool _isLoadingBooks = false;
  String search = '';
  Map<String, dynamic>? authorData;

  // Club system variables
  List<Club> _authorClubs = [];
  AuthorEarnings? _authorEarnings;
  bool _isLoadingClubs = false;
  bool _isLoadingEarnings = false;

  final List<String> accessTypes = ['free', 'borrow'];
  String selectedAccessType = 'free';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadAuthorData();
    await _loadBooksFromSupabase();
    await _syncBooksPublishedCount();
    await _loadAuthorClubs();
    await _loadAuthorEarnings();
  }

  Future<void> _syncBooksPublishedCount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null && authorData != null) {
        final dbCount = authorData?['books_published'] ?? 0;
        final actualCount = books.length;
        
        if (dbCount != actualCount) {
          print('🔄 Syncing books_published count: DB=$dbCount, Actual=$actualCount');
          
          await supabase
              .from('authors')
              .update({'books_published': actualCount})
              .eq('id', user.id);
          
          // Update local author data
          setState(() {
            authorData?['books_published'] = actualCount;
          });
          
          print('✅ Books count synchronized: $actualCount');
        } else {
          print('✅ Books count already in sync: $actualCount');
        }
      }
    } catch (e) {
      print('⚠️ Error syncing books count: $e');
    }
  }

  Future<void> _loadAuthorData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        print('🔄 Loading author data for user: ${user.id}');
        
        final response = await supabase
            .from('authors')
            .select()
            .eq('id', user.id)
            .single();
            
        print('📊 Author data from database: $response');
        
        setState(() {
          authorData = response;
        });
        
        print('📊 Author data loaded - books_published: ${authorData?['books_published']}');
      } else {
        print('⚠️ No authenticated user found');
      }
    } catch (e) {
      print('❌ Error loading author data: $e');
    }
  }

  Future<void> _loadBooksFromSupabase() async {
    setState(() {
      _isLoadingBooks = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // First, get all book IDs that are in club_books table
        final clubBooksResponse = await supabase
            .from('club_books')
            .select('book_id');
        
        final clubBookIds = clubBooksResponse
            .map((item) => item['book_id'] as String)
            .toSet();
        
        print('📚 Found ${clubBookIds.length} books in clubs: $clubBookIds');

        // Then get all books by this author
        final response = await supabase
            .from('books')
            .select()
            .eq('author_id', user.id)
            .order('created_at', ascending: false);

        // Filter out books that are in clubs
        final filteredBooks = response
            .where((book) => !clubBookIds.contains(book['id']))
            .toList();

        print('📖 Total books by author: ${response.length}');
        print('📖 Books after filtering club books: ${filteredBooks.length}');

        setState(() {
          books = filteredBooks.map((book) => Map<String, dynamic>.from(book)).toList();
        });
      }
    } catch (e) {
      print('Error loading books: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading books: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoadingBooks = false;
      });
    }
  }

  // Load author's clubs
  // This method is already defined inside _AuthorDashboardPageState.
  // Remove this duplicate definition at the end of the file.

  // Load author's earnings
  Future<void> _loadAuthorEarnings() async {
    setState(() {
      _isLoadingEarnings = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final earnings = await _clubService.getAuthorEarnings(user.id);
        setState(() {
          _authorEarnings = earnings;
        });
      }
    } catch (e) {
      print('Error loading earnings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading earnings: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoadingEarnings = false;
      });
    }
  }

  // Upload PDF file to Supabase Storage
  Future<String?> _uploadPdfFile() async {
    try {
      // Show file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.single;
        
        // Check if we have file bytes (for web) or path (for mobile)
        Uint8List? fileBytes;
        
        if (file.bytes != null) {
          // Web platform - use bytes directly
          fileBytes = file.bytes!;
        } else if (file.path != null) {
          // Mobile platform - read from file path
          final fileFromPath = File(file.path!);
          fileBytes = await fileFromPath.readAsBytes();
        } else {
          throw Exception('No file data available');
        }

        final user = supabase.auth.currentUser;
        if (user == null) throw Exception('User not authenticated');
        
        // Create unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final originalName = file.name.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
        final fileName = 'pdf_${user.id}_${timestamp}_$originalName';
        
        print('Uploading file: $fileName (${fileBytes.length} bytes)');
        
        // Show progress dialog
        _showUploadProgress('Uploading PDF...');

        try {
          // Upload to Supabase Storage
          await supabase.storage
              .from('book-pdfs')
              .uploadBinary(fileName, fileBytes, 
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ),
              );

          // Close progress dialog
          if (mounted) Navigator.pop(context);

          // Get public URL
          final publicUrl = supabase.storage
              .from('book-pdfs')
              .getPublicUrl(fileName);

          print('PDF uploaded successfully: $publicUrl');
          
          return publicUrl;
          
        } catch (uploadError) {
          // Close progress dialog
          if (mounted) Navigator.pop(context);
          throw Exception('Upload failed: $uploadError');
        }
      } else {
        print('No file selected');
        return null;
      }
    } catch (e) {
      print('Error in _uploadPdfFile: $e');
      
      // Close progress dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return null;
    }
  }

  // Upload cover image to Supabase Storage
  Future<String?> _uploadCoverImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final user = supabase.auth.currentUser;
        if (user == null) throw Exception('User not authenticated');
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = path.extension(image.path).toLowerCase();
        final fileName = 'cover_${user.id}_${timestamp}$extension';
        
        print('Uploading cover: $fileName (${bytes.length} bytes)');
        
        _showUploadProgress('Uploading cover image...');

        try {
          await supabase.storage
              .from('book-covers')
              .uploadBinary(fileName, bytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ),
              );

          if (mounted) Navigator.pop(context);

          final publicUrl = supabase.storage
              .from('book-covers')
              .getPublicUrl(fileName);

          print('Cover uploaded successfully: $publicUrl');
          return publicUrl;
        
        } catch (uploadError) {
          if (mounted) Navigator.pop(context);
          throw Exception('Upload failed: $uploadError');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading cover: $e'), backgroundColor: Colors.red),
      );
    }
    return null;
  }

  // Show upload progress dialog
  void _showUploadProgress(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Save book to Supabase database
  Future<bool> _saveBookToSupabase(Map<String, dynamic> bookData) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Add metadata
      bookData['author_id'] = user.id;
      bookData['is_active'] = true;
      bookData['created_at'] = DateTime.now().toIso8601String();
      bookData['updated_at'] = DateTime.now().toIso8601String();

      // Save to Supabase
      final response = await supabase
          .from('books')
          .insert(bookData)
          .select()
          .single();

      // Update local books list
      setState(() {
        books = [response, ...books];
      });

      // Increment books_published count in authors table
      try {
        print('🔄 Starting books_published increment process...');
        print('👤 User ID: $user.id');
        
        // First, ensure the author record exists
        try {
          await supabase
              .from('authors')
              .upsert({
                'id': user.id,
                'email': user.email,
                'first_name': authorData?['first_name'] ?? author['first_name'],
                'last_name': authorData?['last_name'] ?? author['last_name'],
                'bio': authorData?['bio'] ?? author['bio'],
                'books_published': authorData?['books_published'] ?? 0,
                'created_at': DateTime.now().toIso8601String(),
              });
          print('✅ Author record ensured in database');
        } catch (upsertError) {
          print('⚠️ Warning during author upsert: $upsertError');
        }
        
        // Now get the current books_published count to ensure accuracy
        final currentAuthorData = await supabase
            .from('authors')
            .select('books_published')
            .eq('id', user.id)
            .single();
        
        print('📊 Current author data: $currentAuthorData');
        final currentCount = currentAuthorData['books_published'] ?? 0;
        print('📊 Current books_published count: $currentCount');
        
        final newCount = currentCount + 1;
        print('📊 New books_published count will be: $newCount');
        
        final updateResult = await supabase
            .from('authors')
            .update({
              'books_published': newCount,
            })
            .eq('id', user.id);
        
        print('✅ Update result: $updateResult');
        
        // Reload author data to reflect the updated books_published count
        print('🔄 Reloading author data...');
        
        // Add a small delay to ensure database update has propagated
        await Future.delayed(const Duration(milliseconds: 500));
        
        await _loadAuthorData();
        
        print('📊 Author data after reload: ${authorData?['books_published']}');
        
        // Force UI update after reloading author data with explicit state change
        if (mounted) {
          setState(() {
            // This will trigger a rebuild with the updated authorData
            // Force refresh of stats cards
          });
        }
        
        print('📈 Author books_published count incremented from $currentCount to $newCount');
        print('🎯 Final authorData books_published: ${authorData?['books_published']}');
        
        // Additional verification - query the database directly to confirm the update
        try {
          final verifyData = await supabase
              .from('authors')
              .select('books_published')
              .eq('id', user.id)
              .single();
          print('✅ Database verification - books_published: ${verifyData['books_published']}');
        } catch (verifyError) {
          print('⚠️ Could not verify database update: $verifyError');
        }
      } catch (e) {
        print('⚠️ Warning: Failed to increment books_published count: $e');
        print('⚠️ Error details: ${e.toString()}');
        // Don't fail the entire operation if this update fails
      }

      print('📚 Book saved with data:');
      print('   Title: ${bookData['title']}');
      print('   Cover URL: ${bookData['cover_image_url']}');
      print('   PDF URL: ${bookData['pdf_url']}');
      
      // Test the cover URL if it exists
      if (bookData['cover_image_url'] != null) {
        await _testCoverUrl(bookData['cover_image_url']);
      }

      return true;
    } catch (e) {
      print('Error saving book: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving book: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  // Build book cover from Supabase URL or placeholder
  Widget _buildBookCover(Map<String, dynamic> book, double width, double height) {
    final coverUrl = book['cover_image_url'];
    
    print('=== DEBUG COVER IMAGE ===');
    print('Book ID: ${book['id']}');
    print('Cover URL: $coverUrl');
    print('URL Type: ${coverUrl.runtimeType}');
    print('URL Length: ${coverUrl?.toString().length}');
    print('========================');
    
    if (coverUrl != null && coverUrl.toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          coverUrl.toString(), // Ensure it's a string
          width: width,
          height: height,
          fit: BoxFit.cover,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print('✅ Image loaded successfully: $coverUrl');
              return child;
            }
            
            final progress = loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null;
            
            print('📥 Loading image: ${(progress ?? 0) * 100}%');
            
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading...',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    if (progress != null)
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(fontSize: 8, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error loading image: $error');
            print('❌ Stack trace: $stackTrace');
            print('❌ Image URL was: $coverUrl');
            print('❌ Error type: ${error.runtimeType}');
            return _buildDefaultThumbnail(width, height);
          },
        ),
      );
    }
    
    print('🔍 No cover URL found, using default thumbnail');
    return _buildDefaultThumbnail(width, height);
  }

  // Build default thumbnail placeholder
  Widget _buildDefaultThumbnail(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: width * 0.3,
            color: const Color(0xFF6C63FF).withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Book',
            style: TextStyle(
              fontSize: width * 0.08,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6C63FF).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Handle PDF viewing from Supabase URL
  Future<void> _handlePdfView(Map<String, dynamic> book) async {
    final pdfUrl = book['pdf_url'];
    final bookTitle = book['title'] ?? 'Unknown Book';
    
    if (pdfUrl != null && pdfUrl.toString().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerPage(
            pdfUrl: pdfUrl,
            bookTitle: bookTitle,
            bookId: book['id'], // Pass the required bookId argument
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF file available')),
      );
    }
  }

  // Get published books count with proper synchronization
  String _getPublishedCount() {
    // Always use the local books count as it's the most accurate
    final localCount = books.length;
    final dbCount = authorData?['books_published'];
    
    print('📊 Stats Card Debug:');
    print('   - Database count: $dbCount');
    print('   - Local books count: $localCount');
    print('   - Author data: ${authorData != null ? "loaded" : "null"}');
    
    // If there's a mismatch, log it but use local count
    if (dbCount != null && dbCount != localCount) {
      print('⚠️ Count mismatch detected: DB=$dbCount, Local=$localCount');
      print('⚠️ Using local count as source of truth: $localCount');
    }
    
    return localCount.toString();
  }

  // Get categories information - show most popular category or count
  String _getCategoriesInfo() {
    if (books.isEmpty) return '0';
    
    // Count books per category
    Map<String, int> categoryCount = {};
    for (var book in books) {
      String category = book['category']?.toString() ?? 'Unknown';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    
    // Return the count of unique categories
    return categoryCount.length.toString();
  }

  // Add this method to test URLs:
  Future<void> _testCoverUrl(String url) async {
    try {
      print('🧪 Testing cover URL: $url');
      
      final response = await http.head(Uri.parse(url));
      print('🧪 Response status: ${response.statusCode}');
      print('🧪 Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        print('✅ URL is accessible');
      } else {
        print('❌ URL returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ URL test failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBooks = books
        .where((b) => (b['title'] ?? '').toLowerCase().contains(search.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Author Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          //  Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Dashboard',
            onPressed: _initializeData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: _isLoadingBooks
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading books...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Author Name
                          Row(
                          children: [
                            Expanded(
                            child: Text(
                              '${authorData?['first_name'] ?? author['first_name']} ${authorData?['last_name'] ?? author['last_name']}',
                              style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Color(0xFF6C63FF),
                              ),
                            ),
                            ),
                            IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF6C63FF)),
                            tooltip: 'Edit Profile',
                            onPressed: () => _showEditProfileDialog(context),
                            ),
                          ],
                          ),
                          const SizedBox(height: 12),
                          // Avatar + Info Row
                          Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                            radius: 44,
                            backgroundImage: (authorData?['photo_url'] != null && authorData!['photo_url'].toString().isNotEmpty)
                              ? NetworkImage(authorData!['photo_url'])
                              : AssetImage(author['avatar']!) as ImageProvider,
                            backgroundColor: Colors.grey[200],
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              // Bio
                              Text(
                                authorData?['bio'] ?? author['bio'],
                                style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Email
                              Row(
                                children: [
                                const Icon(Icons.email, size: 16, color: Colors.blueGrey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      final email = (supabase.auth.currentUser?.email ?? author['email']) ?? '';
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Email'),
                                          content: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: SelectableText(
                                              email,
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Text(
                                        (supabase.auth.currentUser?.email ?? author['email']) ?? '',
                                        style: const TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ),
                                )
                                ],
                              ),
                              ],
                            ),
                            ),
                          ],
                          ),
                        ],
                        ),
                  )),
                  const SizedBox(height: 24),

                  // Supabase Storage Status
               

                  // Action Buttons Row
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showPublishBookDialog, 
                        icon: const Icon(Icons.add_box_rounded),
                        label: const Text('Upload Book'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _showCreateClubDialog, 
                        icon: const Icon(Icons.group_add),
                        label: const Text('Create Club'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Analytics
                  Text(
                    'Analytics Overview',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 16),

                  // Stats Cards
                  Row(
                    children: [
                      _statCard('Published', '${_getPublishedCount()}', Icons.publish, Colors.green),
                      const SizedBox(width: 8),
                      _statCard('Categories', '${_getCategoriesInfo()}', Icons.category, Colors.orange),
                      const SizedBox(width: 8),
                      _statCard('Clubs', '${_authorClubs.length}', Icons.groups, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Earnings Cards
                  if (_authorEarnings != null) ...[
                    Row(
                      children: [
                        _earningsCard('Total Earnings', '৳${_authorEarnings!.totalEarnings.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.blue),
                        const SizedBox(width: 8),
                        _earningsCard('This Month', '৳${_authorEarnings!.monthlyEarnings.toStringAsFixed(2)}', Icons.trending_up, Colors.green),
                        const SizedBox(width: 8),
                        _earningsCard('Members', '${_authorEarnings!.totalMembers}', Icons.people, Colors.indigo),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Books List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Published Books', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search books...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() => search = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Books List
                  (filteredBooks.isEmpty)
                      ? Card(
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Icons.library_books, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('No books found', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('Start by publishing your first book!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        )
                      : Card(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredBooks.length,
                            separatorBuilder: (context, i) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final book = filteredBooks[i];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildBookCover(book, 80, 120),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book['title'] ?? 'No Title',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                  
                                          if (book['category'] != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[100],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                book['category'],
                                                style: TextStyle(color: Colors.blue[800], fontSize: 12, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                             
                                              if (book['pdf_url'] != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green[50],
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: Colors.green[200]!),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.picture_as_pdf, size: 12, color: Colors.green[700]),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        'PDF',
                                                        style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.w500),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (book['pdf_url'] != null)
                                          IconButton(
                                            icon: const Icon(Icons.launch, color: Colors.green),
                                            tooltip: 'Open PDF',
                                            onPressed: () => _handlePdfView(book),
                                          ),
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.description,
                                            color: book['description'] != null && book['description'].toString().isNotEmpty 
                                                ? Colors.green 
                                                : Colors.orange,
                                          ),
                                          tooltip: 'Abstract Options',
                                          onSelected: (value) {
                                            switch (value) {
                                              case 'upload':
                                                _uploadAbstract(book);
                                                break;
                                              case 'update':
                                                _updateAbstract(book);
                                                break;
                                              case 'delete':
                                                _deleteAbstract(book);
                                                break;
                                            }
                                          },
                                          itemBuilder: (context) {
                                            bool hasAbstract = book['description'] != null && book['description'].toString().isNotEmpty;
                                            return [
                                              if (!hasAbstract)
                                                const PopupMenuItem<String>(
                                                  value: 'upload',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.upload_file, color: Colors.blue),
                                                      SizedBox(width: 8),
                                                      Text('Upload Abstract'),
                                                    ],
                                                  ),
                                                ),
                                              if (hasAbstract) ...[
                                                const PopupMenuItem<String>(
                                                  value: 'update',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.update, color: Colors.blue),
                                                      SizedBox(width: 8),
                                                      Text('Update Abstract'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem<String>(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('Delete Abstract'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ];
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _editBook(book),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteBook(book['id']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                  const SizedBox(height: 32),

                  // Clubs Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('My Book Clubs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      if (_authorClubs.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            // Navigate to detailed clubs view
                          },
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Clubs List
                  _isLoadingClubs
                      ? const Center(child: CircularProgressIndicator())
                      : (_authorClubs.isEmpty)
                          ? Card(
                              child: Container(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Icon(Icons.groups, size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text('No clubs created yet', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text('Create your first book club to connect with readers!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _showCreateClubDialog,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Create Club'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Card(
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _authorClubs.length > 3 ? 3 : _authorClubs.length, // Show max 3
                                separatorBuilder: (context, i) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final club = _authorClubs[i];
                                  final isPremium = club.isPremium;
                                  final status = club.approvalStatus?.toLowerCase() ?? 'approved';
                                  final showActions = !isPremium || (status == 'approved');
                                  return Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: club.coverImageUrl != null
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Image.network(
                                                        club.coverImageUrl!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Icon(
                                                            Icons.groups,
                                                            color: const Color(0xFF10B981),
                                                            size: 30,
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.groups,
                                                      color: const Color(0xFF10B981),
                                                      size: 30,
                                                    ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Column(
                                                    children: [
                                                      Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: Text(
                                                          club.name,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                        const SizedBox(height: 4),
                                                      if (isPremium)
                                                        Container(
                                                          margin: const EdgeInsets.only(left: 8),
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.amber[100],
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Text(
                                                                'Premium',
                                                                style: TextStyle(
                                                                  color: Colors.amber[800],
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 6),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                                decoration: BoxDecoration(
                                                                  color: status == 'approved'
                                                                      ? Colors.green[100]
                                                                      : status == 'pending'
                                                                          ? Colors.orange[100]
                                                                          : Colors.red[100],
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                                child: Text(
                                                                  status == 'approved'
                                                                      ? 'Approved'
                                                                      : status == 'pending'
                                                                          ? 'Pending'
                                                                          : 'Rejected',
                                                                  style: TextStyle(
                                                                    color: status == 'approved'
                                                                        ? Colors.green[800]
                                                                        : status == 'pending'
                                                                            ? Colors.orange[800]
                                                                            : Colors.red[800],
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    club.description,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        isPremium ? '৳${club.membershipPrice}/month' : 'Free',
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuButton(
                                              icon: const Icon(Icons.more_vert),
                                              onSelected: (value) {
                                                switch (value) {
                                                  case 'edit':
                                                    _showEditClubDialog(club);
                                                    break;
                                                  case 'delete':
                                                    _showDeleteClubDialog(context, club);
                                                    break;
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit, size: 18),
                                                      SizedBox(width: 8),
                                                      Text('Edit'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete, size: 18, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Add manage action buttons below
                                      if (showActions)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
                                          child: Column(
                                            children: [
                                              const Divider(height: 1),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _clubActionButton(
                                                      icon: Icons.people,
                                                      label: 'Members',
                                                      color: Colors.blue,
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => ClubMembersPage(club: club),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: _clubActionButton(
                                                      icon: Icons.book,
                                                      label: 'Books',
                                                      color: Colors.green,
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => ClubBooksPage(club: club),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: _clubActionButton(
                                                      icon: Icons.analytics,
                                                      label: 'Analytics',
                                                      color: Colors.purple,
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => ClubAnalyticsPage(club: club),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (isPremium) ...[
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: double.infinity,
                                                child: _clubActionButton(
                                                  icon: Icons.payment,
                                                  label: 'View Payments',
                                                  color: Colors.orange,
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => ClubPaymentsPage(club: club),
                                                      ),
                                                    );
                                                  },
                                                  fullWidth: true,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _earningsCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value, 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16, 
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label, 
                style: const TextStyle(
                  color: Colors.blueGrey, 
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _clubActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editBook(Map<String, dynamic> book) {
    final titleController = TextEditingController(text: book['title']);
    final priceController = TextEditingController(text: book['price']?.toString() ?? '');
    final summaryController = TextEditingController(text: book['summary'] ?? '');
    final languageController = TextEditingController(text: book['language'] ?? 'English');

    String selectedCategory = book['category'] ?? 'Fiction';
    bool isUpdating = false;
    String? pdfUrl = book['pdf_url'];
    String? coverImageUrl = book['cover_image_url'];
    
    final List<String> categories = [
      'Fiction', 'Non-Fiction', 'Politics & Public Affairs', 'Business', 'Classic',
      'Philosophy', 'Thriller', 'Religion & Spirituality', 'Horror', 
      'Historical Fiction/Novels/Poetry', 'Science', 'IT & Computers', 'Other'
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Book'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current Info
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Editing: ${book['title']}',
                            style: TextStyle(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PDF Update Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.picture_as_pdf, color: Colors.red[600]),
                            const SizedBox(width: 8),
                            const Text('PDF File', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (pdfUrl != null)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  const Expanded(child: Text('Current PDF file')),
                                  TextButton(
                                    onPressed: () async {
                                      final url = await _uploadPdfFile();
                                      if (url != null) {
                                        setDialogState(() => pdfUrl = url);
                                      }
                                    },
                                    child: const Text('Replace'),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () async {
                              final url = await _uploadPdfFile();
                              if (url != null) {
                                setDialogState(() => pdfUrl = url);
                              }
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload PDF'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cover Image Update Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.image, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            const Text('Cover Image', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (coverImageUrl != null)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  const Expanded(child: Text('Current cover image')),
                                  TextButton(
                                    onPressed: () async {
                                      final url = await _uploadCoverImage();
                                      if (url != null) {
                                        setDialogState(() => coverImageUrl = url);
                                      }
                                    },
                                    child: const Text('Replace'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  coverImageUrl!,
                                  width: 80,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 110,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () async {
                              final url = await _uploadCoverImage();
                              if (url != null) {
                                setDialogState(() => coverImageUrl = url);
                              }
                            },
                            icon: const Icon(Icons.image),
                            label: const Text('Upload Cover'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600]),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Form fields
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Book Title*')),
                  const SizedBox(height: 8),
                
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price (\$)'), keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  TextField(controller: languageController, decoration: const InputDecoration(labelText: 'Language')),
                  const SizedBox(height: 8),
                  TextField(controller: summaryController, decoration: const InputDecoration(labelText: 'Summary'), maxLines: 3),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: selectedAccessType,
                    decoration: const InputDecoration(labelText: 'Access Type'),
                    items: accessTypes.map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase()))).toList(),
                    onChanged: (value) => setDialogState(() => selectedAccessType = value!),
                  ),

                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) => setDialogState(() => selectedCategory = value!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUpdating ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isUpdating ? null : () async {
                  // Validation
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a book title')),
                    );
                    return;
                  }

                  setDialogState(() => isUpdating = true);

                  try {
                    final updatedData = {
                      'title': titleController.text.trim(),
                      'price': double.tryParse(priceController.text) ?? 0.0,
                      'language': languageController.text.trim(),
                      'summary': summaryController.text.trim(),
                      'category': selectedCategory,
                      'pdf_url': pdfUrl,
                      'cover_image_url': coverImageUrl,
                      'updated_at': DateTime.now().toIso8601String(),
                    };

                    // Update in Supabase
                    await supabase
                        .from('books')
                        .update(updatedData)
                        .eq('id', book['id']);

                    // Refresh books list
                    await _loadBooksFromSupabase();

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📚 Book updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isUpdating = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating book: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600]),
                child: isUpdating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update Book', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ));
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
  final firstNameController = TextEditingController(text: authorData?['first_name'] ?? author['first_name']);
  final lastNameController = TextEditingController(text: authorData?['last_name'] ?? author['last_name']);
        final bioController = TextEditingController(text: authorData?['bio'] ?? author['bio']);
        String? avatarUrl = authorData?['photo_url'];
        bool isUploading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundImage: (avatarUrl != null && avatarUrl?.isNotEmpty == true)
                            ? NetworkImage(avatarUrl!)
                            : AssetImage(author['avatar']!) as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            setState(() => isUploading = true);
                            try {
                              final XFile? image = await _imagePicker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 400,
                                maxHeight: 400,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                final user = supabase.auth.currentUser;
                                if (user == null) throw Exception('User not authenticated');
                                final timestamp = DateTime.now().millisecondsSinceEpoch;
                                final extension = path.extension(image.path).toLowerCase();
                                final fileName = 'avatar_${user.id}_$timestamp$extension';
                                // Show progress indicator
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const AlertDialog(
                                    content: SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                                  ),
                                );
                                await supabase.storage
                                    .from('avatars')
                                    .uploadBinary(fileName, bytes,
                                      fileOptions: const FileOptions(upsert: false),
                                    );
                                Navigator.pop(context); // Close progress dialog
                                final publicUrl = supabase.storage
                                    .from('avatars')
                                    .getPublicUrl(fileName);
                                setState(() => avatarUrl = publicUrl);
                              }
                            } catch (e) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error uploading photo: $e'), backgroundColor: Colors.red),
                              );
                            } finally {
                              setState(() => isUploading = false);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: isUploading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.edit, size: 20, color: Color(0xFF6C63FF)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name')),
                  TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name')),
                  TextField(controller: bioController, decoration: const InputDecoration(labelText: 'Bio')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final user = supabase.auth.currentUser;
                      if (user != null) {
                        await supabase.from('authors').upsert({
                          'id': user.id,
                          'first_name': firstNameController.text,
                          'last_name': lastNameController.text,
                          'bio': bioController.text,
                          'email': user.email,
                          'photo_url': avatarUrl,
                        });
                        await _loadAuthorData();
                      }
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating profile: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPublishBookDialog() {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final summaryController = TextEditingController();
    final languageController = TextEditingController(text: 'English');

    String selectedCategory = 'Fiction';
    bool isPublishing = false;
    String? pdfUrl;
    String? coverImageUrl;
    
    final List<String> categories = [
      'Fiction', 'Non-Fiction', 'Politics & Public Affairs', 'Business', 'Classic',
      'Philosophy', 'Thriller', 'Religion & Spirituality', 'Horror', 
      'Historical Fiction/Novels/Poetry', 'Science', 'IT & Computers', 'Other'
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Publish New Book'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Instructions
                  Text(
                    '${authorData?['first_name'] ?? author['first_name']} ${authorData?['last_name'] ?? author['last_name']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    authorData?['bio'] ?? author['bio'],
                    style: const TextStyle(color: Colors.blueGrey, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          (supabase.auth.currentUser?.email ?? author['email']) ?? '',
                          style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  // PDF Upload Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.picture_as_pdf, color: Colors.red[600]),
                            const SizedBox(width: 8),
                            const Text('PDF File', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (pdfUrl == null)
                          ElevatedButton.icon(
                            onPressed: () async {
                              final url = await _uploadPdfFile();
                              if (url != null) {
                                setDialogState(() => pdfUrl = url);
                              }
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload PDF'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
                          )
                        else
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  const Expanded(child: Text('PDF uploaded successfully')),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => setDialogState(() => pdfUrl = null),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cover Image Upload Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.image, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            const Text('Cover Image', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (coverImageUrl == null)
                          ElevatedButton.icon(
                            onPressed: () async {
                              final url = await _uploadCoverImage();
                              if (url != null) {
                                setDialogState(() => coverImageUrl = url);
                              }
                            },
                            icon: const Icon(Icons.image),
                            label: const Text('Upload Cover'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600]),
                          )
                        else
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  const Expanded(child: Text('Cover uploaded successfully')),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => setDialogState(() => coverImageUrl = null),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  coverImageUrl!,
                                  width: 100,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Form fields
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Book Title*')),
                  const SizedBox(height: 8),
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price (\$)'), keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  TextField(controller: languageController, decoration: const InputDecoration(labelText: 'Language')),
                  const SizedBox(height: 8),
                  TextField(controller: summaryController, decoration: const InputDecoration(labelText: 'Summary'), maxLines: 3),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: selectedAccessType,
                    decoration: const InputDecoration(labelText: 'Access Type'),
                    items: accessTypes.map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase()))).toList(),
                    onChanged: (value) => setDialogState(() => selectedAccessType = value!),
                  ),

                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) => setDialogState(() => selectedCategory = value!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isPublishing ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isPublishing ? null : () async {
                  // Validation
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a book title')),
                    );
                    return;
                  }

                  if (pdfUrl == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please upload a PDF file')),
                    );
                    return;
                  }

                  setDialogState(() => isPublishing = true);

                  final bookData = {
                    'title': titleController.text.trim(),
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'language': languageController.text.trim(),
                    'summary': summaryController.text.trim(),
                    'category': selectedCategory,
                    'pdf_url': pdfUrl,
                    'cover_image_url': coverImageUrl,
                    'access_type': selectedAccessType,
                  };

                  final success = await _saveBookToSupabase(bookData);

                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📚 Book published successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                child: isPublishing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Publish Book', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ));
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _performLogout,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      await supabase.auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Replace the _deleteBook method - handle UUID strings properly:

  Future<void> _deleteBook(dynamic bookId) async {
    // Convert bookId to string for UUID handling
    String id = bookId.toString();
    
    print('Deleting book with ID: $id'); // Debug log
    
    // Find the book to get its details
    final bookToDelete = books.firstWhere(
      (book) => book['id'].toString() == id,
      orElse: () => <String, dynamic>{},
    );
    
    if (bookToDelete.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Delete Book'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this book?',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800]),
            ),
            const SizedBox(height: 8),
            Text('Title: ${bookToDelete['title'] ?? 'Unknown'}'),
            const SizedBox(height: 4),
            Text('Category: ${bookToDelete['category'] ?? 'Unknown'}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will permanently delete the book, PDF file, and cover image.',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Deleting "${bookToDelete['title'] ?? 'Book'}"...'),
            ],
          ),
        ),
      );

      try {
        // Delete storage files first
        List<String> deletionErrors = [];

        // Delete PDF file if exists
        if (bookToDelete['pdf_url'] != null && bookToDelete['pdf_url'].toString().isNotEmpty) {
          try {
            final pdfFileName = _extractFileNameFromUrl(bookToDelete['pdf_url']);
            if (pdfFileName != null) {
              await supabase.storage
                  .from('book-pdfs')
                  .remove([pdfFileName]);
              print('✅ PDF file deleted: $pdfFileName');
            }
          } catch (e) {
            print('❌ Error deleting PDF: $e');
            deletionErrors.add('PDF file');
          }
        }

        // Delete cover image if exists
        if (bookToDelete['cover_image_url'] != null && bookToDelete['cover_image_url'].toString().isNotEmpty) {
          try {
            final coverFileName = _extractFileNameFromUrl(bookToDelete['cover_image_url']);
            if (coverFileName != null) {
              await supabase.storage
                  .from('book-covers')
                  .remove([coverFileName]);
              print('✅ Cover image deleted: $coverFileName');
            }
          } catch (e) {
            print('❌ Error deleting cover: $e');
            deletionErrors.add('Cover image');
          }
        }

        // Delete from database - use the string ID directly (works with UUIDs)
        await supabase.from('books').delete().eq('id', id);
        
        // Decrement books_published count in authors table
        try {
          final user = supabase.auth.currentUser;
          if (user != null) {
            // Get the current books_published count from database to ensure accuracy
            final currentAuthorData = await supabase
                .from('authors')
                .select('books_published')
                .eq('id', user.id)
                .single();
            
            final currentCount = currentAuthorData['books_published'] ?? 0;
            final newCount = (currentCount > 0) ? currentCount - 1 : 0;
            
            await supabase
                .from('authors')
                .update({
                  'books_published': newCount,
             
                })
                .eq('id', user.id);
            
            // Reload author data to reflect the updated books_published count
            await _loadAuthorData();
            
            print('📉 Author books_published count decremented from $currentCount to $newCount');
          }
        } catch (e) {
          print('⚠️ Warning: Failed to decrement books_published count: $e');
          // Don't fail the entire operation if this update fails
        }
        
        // Close loading dialog
        if (mounted) Navigator.pop(context);
        
        // Refresh books list
        await _loadBooksFromSupabase();
        
        if (mounted) {
          String message = '✅ Book deleted successfully!';
          if (deletionErrors.isNotEmpty) {
            message += '\n⚠️ Note: ${deletionErrors.join(', ')} could not be deleted from storage.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: deletionErrors.isEmpty ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) Navigator.pop(context);
        
        print('❌ Error deleting book: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error deleting book: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  // Helper method to extract filename from Supabase URL
  String? _extractFileNameFromUrl(String url) {
    try {
      if (url.isEmpty) return null;
      
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      print('Extracting filename from URL: $url'); // Debug log
      print('Path segments: $pathSegments'); // Debug log
      
      // For Supabase storage URLs: /storage/v1/object/public/bucket-name/filename
      if (pathSegments.length >= 5 && pathSegments.contains('storage')) {
        final filename = pathSegments.last;
        print('Extracted filename: $filename'); // Debug log
        return filename;
      }
      
      // Fallback: get last segment
      final filename = pathSegments.isNotEmpty ? pathSegments.last : null;
      print('Fallback filename: $filename'); // Debug log
      return filename;
    } catch (e) {
      print('❌ Error extracting filename from URL: $e');
      return null;
    }
  }

  // Abstract upload functionality
  Future<void> _uploadAbstract(Map<String, dynamic> book) async {
    try {
      // Pick PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Show upload progress dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Uploading abstract for "${book['title']}"...'),
              ],
            ),
          ),
        );

        // Generate unique filename for abstract
        final user = supabase.auth.currentUser;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueFileName = 'abstract_${user?.id}_${book['id']}_$timestamp.pdf';

        // Upload to Supabase storage
        final bytes = await file.readAsBytes();
        await supabase.storage
            .from('book-pdfs')
            .uploadBinary(uniqueFileName, bytes);

        // Get the public URL
        final abstractUrl = supabase.storage
            .from('book-pdfs')
            .getPublicUrl(uniqueFileName);

        // Update the book's description with the abstract URL
        await supabase
            .from('books')
            .update({'description': abstractUrl})
            .eq('id', book['id']);

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Abstract uploaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Refresh books list
        await _loadBooksFromSupabase();

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No file selected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted) Navigator.pop(context);
      
      print('❌ Error uploading abstract: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error uploading abstract: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Update abstract functionality
  Future<void> _updateAbstract(Map<String, dynamic> book) async {
    try {
      // Check if book already has an abstract
      if (book['description'] == null || book['description'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No abstract found to update. Upload an abstract first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Pick new PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Show upload progress dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Updating abstract for "${book['title']}"...'),
              ],
            ),
          ),
        );

        // Delete old abstract from storage
        final oldAbstractUrl = book['description'].toString();
        if (oldAbstractUrl.isNotEmpty) {
          try {
            final oldFileName = _extractFileNameFromUrl(oldAbstractUrl);
            if (oldFileName != null) {
              await supabase.storage
                  .from('book-pdfs')
                  .remove([oldFileName]);
              print('✅ Old abstract deleted: $oldFileName');
            }
          } catch (e) {
            print('⚠️ Warning: Could not delete old abstract: $e');
          }
        }

        // Generate unique filename for new abstract
        final user = supabase.auth.currentUser;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueFileName = 'abstract_${user?.id}_${book['id']}_$timestamp.pdf';

        // Upload new abstract to Supabase storage
        final bytes = await file.readAsBytes();
        await supabase.storage
            .from('book-pdfs')
            .uploadBinary(uniqueFileName, bytes);

        // Get the public URL
        final newAbstractUrl = supabase.storage
            .from('book-pdfs')
            .getPublicUrl(uniqueFileName);

        // Update the book's description with the new abstract URL
        await supabase
            .from('books')
            .update({'description': newAbstractUrl})
            .eq('id', book['id']);

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Abstract updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Refresh books list
        await _loadBooksFromSupabase();

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No file selected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted) Navigator.pop(context);
      
      print('❌ Error updating abstract: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating abstract: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Delete abstract functionality
  Future<void> _deleteAbstract(Map<String, dynamic> book) async {
    try {
      // Check if book has an abstract
      if (book['description'] == null || book['description'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No abstract found to delete.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Confirm deletion
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red[600]),
              const SizedBox(width: 8),
              const Text('Delete Abstract'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete the abstract for this book?',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800]),
              ),
              const SizedBox(height: 8),
              Text('Book: ${book['title'] ?? 'Unknown'}'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will permanently remove the abstract PDF file.',
                        style: TextStyle(fontSize: 12, color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Deleting abstract for "${book['title']}"...'),
              ],
            ),
          ),
        );

        // Delete abstract from storage
        final abstractUrl = book['description'].toString();
        if (abstractUrl.isNotEmpty) {
          try {
            final fileName = _extractFileNameFromUrl(abstractUrl);
            if (fileName != null) {
              await supabase.storage
                  .from('book-pdfs')
                  .remove([fileName]);
              print('✅ Abstract file deleted: $fileName');
            }
          } catch (e) {
            print('❌ Error deleting abstract file: $e');
          }
        }

        // Remove abstract URL from database (set description to null)
        await supabase
            .from('books')
            .update({'description': null})
            .eq('id', book['id']);

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Abstract deleted successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Refresh books list
        await _loadBooksFromSupabase();
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted) Navigator.pop(context);
      
      print('❌ Error deleting abstract: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error deleting abstract: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ============= CLUB MANAGEMENT METHODS =============

// ============= CLUB MANAGEMENT METHODS =============

void _showCreateClubDialog() {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  
  bool isPremium = false;
  bool isCreating = false;
  String? coverImageUrl;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Create New Book Club'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Club Name*'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),

                /// ✅ FIXED COVER IMAGE SECTION
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Icon(Icons.image, color: Colors.grey[600]),
                      const Text('Club Cover Image (Optional)'),
                      if (coverImageUrl == null)
                        ElevatedButton.icon(
                          onPressed: isCreating ? null : () async {
                            final url = await _uploadCoverImage();
                            if (url != null) {
                              setDialogState(() => coverImageUrl = url);
                            }
                          },
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload Cover'),
                        )
                      else ...[
                        const Text(
                          '✓ Cover uploaded',
                          style: TextStyle(color: Colors.green),
                        ),
                        TextButton(
                          onPressed: isCreating ? null : () => setDialogState(() => coverImageUrl = null),
                          child: const Text('Remove'),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// PREMIUM SETTINGS
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    border: Border.all(color: Colors.amber[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[700]),
                          const SizedBox(width: 8),
                          const Text('Premium Club Settings'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Make this a Premium Club'),
                        subtitle: const Text('Members will pay to join and access exclusive features'),
                        value: isPremium,
                        onChanged: (value) => setDialogState(() => isPremium = value!),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (isPremium) ...[
                        TextField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Monthly Price (BDT)*',
                            hintText: 'Enter price in BDT',
                            border: OutlineInputBorder(),
                            prefixText: '৳',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isCreating ? null : () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a club name')),
                  );
                  return;
                }
                if (descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a description')),
                  );
                  return;
                }
                if (isPremium && priceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a price for premium club')),
                  );
                  return;
                }

                setDialogState(() => isCreating = true);

                try {
                  final user = supabase.auth.currentUser;
                  if (user == null) throw Exception('User not authenticated');
                  final clubData = {
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'cover_image_url': coverImageUrl,
                    'author_id': user.id,
                    'membership_price': double.tryParse(priceController.text.trim()) ?? 0,
                    'is_premium': isPremium,
                    'created_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                    'is_active': true,
                    'approval_status': isPremium ? 'pending' : 'approved',
                  };
                  await supabase.from('clubs').insert(clubData);
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isPremium
                        ? 'Premium club request submitted. Awaiting admin approval.'
                        : 'Club created and approved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadAuthorClubs();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  setDialogState(() => isCreating = false);
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    )
                  : const Text('Create Club'),
            ),
          ],
        );
      },
    ),
  );
}


  void _showEditClubDialog(Club club) {
    final nameController = TextEditingController(text: club.name);
    final descriptionController = TextEditingController(text: club.description);
    final priceController = TextEditingController(text: club.membershipPrice.toString());
    
    bool isPremium = club.isPremium;
    bool isUpdating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Book Club'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Club Name*',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description*',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Premium Settings
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        border: Border.all(color: Colors.amber[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: const Text('Premium Club'),
                            value: isPremium,
                            onChanged: (value) => setDialogState(() => isPremium = value!),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (isPremium) ...[
                            TextField(
                              controller: priceController,
                              decoration: const InputDecoration(
                                labelText: 'Monthly Price (BDT)*',
                                border: OutlineInputBorder(),
                                prefixText: '৳',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUpdating ? null : () async {
                    if (nameController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields')),
                      );
                      return;
                    }

                    setDialogState(() => isUpdating = true);

                    try {
                      final updatedClub = club.copyWith(
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        isPremium: isPremium,
                        membershipPrice: isPremium ? double.tryParse(priceController.text) ?? 0.0 : 0.0,
                        updatedAt: DateTime.now(),
                      );

                      final success = await _clubService.updateClub(updatedClub);
                      
                      if (success) {
                        await _loadAuthorClubs();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Club updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update club'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating club: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setDialogState(() => isUpdating = false);
                    }
                  },
                  child: isUpdating 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteClubDialog(BuildContext context, Club club) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Removed unused isDeleting variable
          
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[600]),
                const SizedBox(width: 8),
                const Text('Delete Club'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete "${club.name}"?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.red[700], size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'This action will permanently:',
                            style: TextStyle(
                              fontSize: 12, 
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('• Cancel all active memberships', style: TextStyle(fontSize: 12, color: Colors.red[700])),
                      Text('• Remove all books from the club', style: TextStyle(fontSize: 12, color: Colors.red[700])),
                      Text('• Deactivate the club permanently', style: TextStyle(fontSize: 12, color: Colors.red[700])),
                      if (club.isPremium)
                        Text('• Stop all premium subscription billing', style: TextStyle(fontSize: 12, color: Colors.red[700], fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Removed setDialogState for isDeleting (variable no longer exists)
                  final success = await _clubService.deleteClub(club.id);
                  if (Navigator.of(context).mounted) {
                    Navigator.pop(context);
                    if (success) {
                      await _loadAuthorClubs();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Club "${club.name}" deleted successfully'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Failed to delete club. Please try again.'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete Club'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadAuthorClubs() async {
    setState(() {
      _isLoadingClubs = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final clubs = await _clubService.getClubsByAuthor(user.id);
        setState(() {
          _authorClubs = clubs;
        });
      }
    } catch (e) {
      print('Error loading clubs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading clubs: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoadingClubs = false;
      });
    }
  }

}