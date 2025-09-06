import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../components/admin_sidebar.dart';
import '../catalog/all_users_books_reqst_Catalog_management.dart';
import '../books/books_and_club_management.dart';
import '../../main_home_page/main_page.dart';
import '../../../models/author_model.dart' as AuthorModel;
import '../../../models/user_model.dart' as UserModel;

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final supabase = Supabase.instance.client;

  // Sidebar state
  bool _isSidebarOpen = false;
  bool _isLoading = false;

  // Data lists
  List<UserModel.User> _users = [];
  List<AuthorModel.Author> _authors = [];
  List<UserModel.User> _filteredUsers = [];
  List<AuthorModel.Author> _filteredAuthors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange); // Listen for tab changes
    _loadUsers();
    _loadAuthors();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange); // Remove listener
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Handle tab changes to clear search and re-filter
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _searchController.clear();
      _performSearch();
    }
  }

  // Load users from Supabase
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('users')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _users = (response as List<dynamic>)
            .map((data) => UserModel.User.fromMap(data as Map<String, dynamic>))
            .toList();
        _filteredUsers = _users;
      });
    } catch (e) {
      print('Error loading users: $e');
      _showSnackBar('Error loading users: $e', isSuccess: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Load authors from Supabase
  Future<void> _loadAuthors() async {
    try {
      final response = await supabase
          .from('authors')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _authors = (response as List<dynamic>)
            .map((data) => AuthorModel.Author.fromMap(data as Map<String, dynamic>))
            .toList();
        _filteredAuthors = _authors;
      });
    } catch (e) {
      print('Error loading authors: $e');
      _showSnackBar('Error loading authors: $e', isSuccess: false);
    }
  }

  // Ban/Unban user
  Future<void> _toggleUserBan(UserModel.User user) async {
    final newStatus = !user.isActive;

    try {
      await supabase
          .from('users')
          .update({'is_active': newStatus})
          .eq('id', user.id);

      await _loadUsers();
      _showSnackBar(
        newStatus ? 'User unbanned successfully!' : 'User banned successfully!',
        isSuccess: true,
      );
    } catch (e) {
      print('Error updating user status: $e');
      _showSnackBar('Error updating user status: $e', isSuccess: false);
    }
  }

  // Toggle author verification
  Future<void> _toggleAuthorVerification(AuthorModel.Author author) async {
    final newStatus = author.isVerified ? 'pending' : 'verified';

    try {
      await supabase
          .from('authors')
          .update({'verification_status': newStatus})
          .eq('id', author.id);

      await _loadAuthors();
      _showSnackBar(
        'Author verification status updated successfully!',
        isSuccess: true,
      );
    } catch (e) {
      print('Error updating author verification: $e');
      _showSnackBar('Error updating verification status: $e', isSuccess: false);
    }
  }

  // Generate Report (placeholder for now)
  void _generateReport() {
    _showSnackBar('Report generation feature coming soon!', isSuccess: true);
  }

  // Show filter dialog (placeholder for now)
  void _showFilterDialog() {
    _showSnackBar('Advanced filters coming soon!', isSuccess: true);
  }

  // Perform search across current tab
  void _performSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (_tabController.index == 0) {
        // Users tab
        _filteredUsers = _users.where((user) {
          final fullName = user.fullName.toLowerCase();
          final email = (user.email ?? '').toLowerCase();
          final username = (user.username ?? '').toLowerCase();
          return fullName.contains(query) ||
              email.contains(query) ||
              username.contains(query);
        }).toList();
      } else {
        // Authors tab
        _filteredAuthors = _authors.where((author) {
          final displayName = (author.displayName ?? '').toLowerCase();
          final firstName = (author.firstName ?? '').toLowerCase();
          final lastName = (author.lastName ?? '').toLowerCase();
          final email = (author.email ?? '').toLowerCase();
          return displayName.contains(query) ||
              firstName.contains(query) ||
              lastName.contains(query) ||
              email.contains(query);
        }).toList();
      }
    });
  }

// Show add author dialog
void _showAddAuthorDialog() {
  _showSnackBar('Add Author dialog coming soon!', isSuccess: true);
}

// Show add author dialog methods (simplified for now)
void _showViewAuthorDialog(AuthorModel.Author author) {
  _showSnackBar('View Author details coming soon!', isSuccess: true);
}

void _showEditAuthorDialog(AuthorModel.Author author) {
  _showSnackBar('Edit Author dialog coming soon!', isSuccess: true);
}


  Widget _buildLoadingState(String message) {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: const Color(0xFF0096C7)),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.montserrat(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.montserrat(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorsTable() {
    if (_isLoading && _authors.isEmpty) {
      // Only show full loading if no data is present yet
      return _buildLoadingState('Loading authors...');
    }

    if (_filteredAuthors.isEmpty && !_isLoading) {
      return _buildEmptyState(
        icon: Icons.edit_outlined,
        title: 'No authors found',
        subtitle: 'Authors will appear here once registered',
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 2; // Default for medium screens
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 3; // Larger screens get more columns
          } else if (constraints.maxWidth < 700) {
            crossAxisCount = 1; // Small screens get a single column
          }

          return GridView.builder(
      
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Important: Let parent CustomScrollView handle scrolling
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: constraints.maxWidth < 700
                  ? 1.2  // Reduced from 1.5 to make cards taller on mobile
                  : (constraints.maxWidth < 1200 ? 1.00 : 0.85), // Reduced ratios to increase height
            ),
            itemCount: _filteredAuthors.length,
            itemBuilder: (context, index) {
              final author = _filteredAuthors[index];
              final verificationStatus = author.verificationStatus;
              final isVerified = author.isVerified;
              // Use the model's isActive property directly
              final isActive = author.isActive;
              final createdAt = author.createdAt;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isVerified
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with verification status
                      Row(
                        children: [
                          Flexible( // Changed from Expanded to Flexible
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isVerified
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isVerified ? Icons.verified : Icons.pending,
                                    size: 12,
                                    color: isVerified ? Colors.green[700] : Colors.orange[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible( // Wrap text in Flexible to prevent overflow
                                    child: Text(
                                      verificationStatus.toUpperCase(),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isVerified ? Colors.green[700] : Colors.orange[700],
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'ACTIVE' : 'INACTIVE',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isActive ? Colors.blue[700] : Colors.red[700],
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Author Avatar and Name
                      Row(
                        children: [
                            Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: author.photoUrl != null && author.photoUrl!.isNotEmpty
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  author.photoUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    color: Colors.grey[600],
                                    size: 24,
                                  );
                                  },
                                ),
                                )
                              : Icon(
                                Icons.person,
                                color: Colors.grey[600],
                                size: 24,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Flexible( // Changed from Expanded to Flexible
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${author.firstName ?? ''} ${author.lastName ?? ''}".trim(),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2D3748),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                               
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Contact Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (author.email != null && author.email!.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    color: Colors.teal[700],
                                    size: 12,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded( // Ensure email text doesn't overflow
                                    child: Text(
                                      author.email!,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        color: Colors.teal[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            if (author.contactNo != null && author.contactNo!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: author.email != null ? 4.0 : 0.0), // Add spacing if email is present
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      color: Colors.teal[700],
                                      size: 12,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded( // Ensure phone number doesn't overflow
                                      child: Text(
                                        author.contactNo!,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 10,
                                          color: Colors.teal[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Stats section
                      Row(
                        children: [
                          Flexible( // Changed from Expanded to avoid constraints issues
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Books',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 8,
                                      color: Colors.amber[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    author.booksPublished?.toString() ?? '0',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      color: Colors.amber[700],
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible( // Changed from Expanded to avoid constraints issues
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Joined',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 8,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text( // Removed Flexible wrapper as it's not needed here
                                  createdAt != null
                                      ? DateFormat('dd MMM yyyy').format(createdAt)
                                      : 'Unknown',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    color: const Color(0xFF2D3748),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildIconOnlyActionButton(
                            icon: Icons.visibility,
                            color: Colors.blue,
                            onTap: () => _showViewAuthorDialog(author),
                          ),
                          _buildIconOnlyActionButton(
                            icon: isVerified ? Icons.verified_user : Icons.pending,
                            color: isVerified ? Colors.green : Colors.orange,
                            onTap: () => _toggleAuthorVerification(author),
                          ),
                          _buildIconOnlyActionButton(
                            icon: Icons.edit,
                            color: Colors.purple,
                            onTap: () => _showEditAuthorDialog(author),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  
  }

  // Dialog methods (simplified for now)
  void _showViewUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(
              maxWidth: 450,
              maxHeight: 500, // Added max height to prevent overflow on small screens
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0096C7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF0096C7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'View User',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0096C7),
                          ),
                          overflow: TextOverflow.ellipsis, // Added overflow for title
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 24),
                // Content
                Expanded( // Use Expanded with SingleChildScrollView for flexible height
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column( // Changed to Column for better responsiveness on small screens
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User details
                        _buildViewDetailItem('User ID :', '${user['id']}'),
                        const SizedBox(height: 16),
                        _buildViewDetailItem('Name :', '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'),
                        const SizedBox(height: 16),
                        _buildViewDetailItem('Email :', user['email'] ?? 'N/A'),
                        const SizedBox(height: 16),
                        _buildViewDetailItem('Username :', user['username'] ?? 'N/A'),
                        const SizedBox(height: 24), // Spacing before divider

                        // Divider for smaller screens
                        if (MediaQuery.of(context).size.width < 600)
                          Container(
                            height: 1,
                            color: Colors.grey[300],
                            margin: const EdgeInsets.symmetric(vertical: 24),
                          )
                        else // Vertical divider for wider screens
                          Center(
                            child: Container(
                              width: 1,
                              height: 150,
                              color: Colors.grey[300],
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                          ),
                        const SizedBox(height: 24), // Spacing after divider

                        // Created by info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Created by :',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mr. XYZ',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '(Admin)',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Close button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0096C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'CLOSE',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }



  void _showEditUserDialog(Map<String, dynamic> user) {
    _showSnackBar('Edit User dialog coming soon!', isSuccess: true);
  }



  // Sidebar methods
  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  // Smooth transition route helper
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  void _handleSidebarTap(String label) {
    if (label == 'Dashboard') {
      _toggleSidebar();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pop(); // Go back to dashboard
        }
      });
    } else if (label == 'Catalog') {
      _toggleSidebar();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(_createRoute(const AllUsersBookRequestCatalogManagementPage()));
        }
      });
    } else if (label == 'Books') {
      _toggleSidebar();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(_createRoute(const BooksAndClubManagementPage()));
        }
      });
    } else if (label == 'Log Out') {
      _showLogoutDialog();
    } else {
      _toggleSidebar();
    }
  }

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
              Icon(
                Icons.logout,
                color: Colors.red[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from admin panel?',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to main page
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainPage()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0096C7),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0096C7).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top row with hamburger menu and title
            Row(
              children: [
                // Hamburger Menu Button
                GestureDetector(
                  onTap: _toggleSidebar,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                  child: Text(
                    'User Management',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // Added overflow
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tab Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                indicator: BoxDecoration(
                  color: const Color(0xFF0096C7),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0096C7).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF0096C7),
                labelStyle: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                indicatorPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Users'),
                  Tab(text: 'Authors'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSearchAndActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          // Search and Action Buttons Row
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive layout based on screen width
              if (constraints.maxWidth < 600) {
                // Mobile layout - Stack vertically
                return Column(
                  children: [
                    // Search bar
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: _tabController.index == 0 
                              ? 'Search users...'
                              : 'Search authors...',
                          hintStyle: GoogleFonts.montserrat(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF0096C7),
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Action buttons in scrollable row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildActionButton(
                            icon: Icons.filter_list,
                            text: 'Filter',
                            color: Colors.orange,
                            onTap: _showFilterDialog,
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.picture_as_pdf,
                            text: 'Report',
                            color: Colors.green,
                            onTap: _generateReport,
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.add,
                            text: _tabController.index == 0 ? 'Add User' : 'Add Author',
                            color: const Color(0xFF0096C7),
                            onTap: () {
                              if (_tabController.index == 0) {
                                _showAddUserDialog();
                              } else {
                                _showAddAuthorDialog();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Desktop/Tablet layout - Single row
                return Row(
                  children: [
                    // Search bar
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: _tabController.index == 0 
                                ? 'Search users by name, email, username...'
                                : 'Search authors by name, email...',
                            hintStyle: GoogleFonts.montserrat(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF0096C7),
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Action buttons
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionButton(
                              icon: Icons.filter_list,
                              text: 'Filter',
                              color: Colors.orange,
                              onTap: _showFilterDialog,
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.picture_as_pdf,
                              text: 'Report',
                              color: Colors.green,
                              onTap: _generateReport,
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.add,
                              text: _tabController.index == 0 ? 'Add User' : 'Add Author',
                              color: const Color(0xFF0096C7),
                              onTap: () {
                                if (_tabController.index == 0) {
                                  _showAddUserDialog();
                                } else {
                                  _showAddAuthorDialog();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Statistics Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics header
                Text(
                  'Statistics Overview',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 12),
                // Statistics in scrollable row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard(
                        label: 'Total ${_tabController.index == 0 ? 'Users' : 'Authors'}',
                        value: _tabController.index == 0 ? _users.length.toString() : _authors.length.toString(),
                        color: const Color(0xFF0096C7),
                        icon: _tabController.index == 0 ? Icons.people : Icons.edit,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        label: 'Active',
                        value: _tabController.index == 0 
                            ? _users.where((u) => u.isActive).length.toString()
                            : _authors.where((a) => a.isActive).length.toString(),
                        color: Colors.green,
                        icon: Icons.check_circle,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        label: 'Inactive',
                        value: _tabController.index == 0 
                            ? _users.where((u) => !u.isActive).length.toString()
                            : _authors.where((a) => !a.isActive).length.toString(),
                        color: Colors.red,
                        icon: Icons.block,
                      ),
                      if (_tabController.index == 1) ...[
                        const SizedBox(width: 16),
                        _buildStatCard(
                          label: 'Verified',
                          value: _authors.where((a) => a.verificationStatus == 'verified').length.toString(),
                          color: Colors.purple,
                          icon: Icons.verified,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          label: 'Pending',
                          value: _authors.where((a) => a.verificationStatus == 'pending').length.toString(),
                          color: Colors.orange,
                          icon: Icons.pending,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for action buttons
  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 100,
        maxWidth: 140,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for stat cards
  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 180,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // Removed unused _buildStatItem method as it's been replaced by _buildStatCard

  Widget _buildUsersTable() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: const Color(0xFF0096C7)),
              const SizedBox(height: 16),
              Text(
                'Loading users...',
                style: GoogleFonts.montserrat(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No users found',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Users will appear here once registered',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine number of columns based on screen width
          int crossAxisCount = 2;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth < 800) {
            crossAxisCount = 1;
          }
          
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Important: Let parent CustomScrollView handle scrolling
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2, // Responsive aspect ratio
            ),
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final user = _filteredUsers[index];
              // Use the model's properties directly
              final isActive = user.isActive;
              final role = user.role ?? 'user';
              final createdAt = user.createdAt;
              
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive 
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with status and role
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isActive 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'BANNED',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? Colors.green[700] : Colors.red[700],
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: role == 'admin' 
                                  ? Colors.purple.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: role == 'admin' ? Colors.purple[700] : Colors.blue[700],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // User Avatar and Name
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0096C7).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.person,
                              color: const Color(0xFF0096C7),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName.trim().isNotEmpty 
                                      ? user.fullName
                                      : user.username ?? 'Unknown User',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2D3748),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (user.username != null)
                                  Text(
                                    '@${user.username}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Email Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: Colors.blue[700],
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                user.email ?? 'No email',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Footer with join date and actions
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Joined',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 8,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  createdAt != null 
                                      ? DateFormat('dd MMM yyyy').format(createdAt)
                                      : 'Unknown',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    color: const Color(0xFF2D3748),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Action buttons
                          Row(
                            children: [
                              _buildIconOnlyActionButton(
                                icon: Icons.visibility,
                                color: Colors.blue,
                                onTap: () => _showViewUserDialog(user.toMap()),
                              ),
                              const SizedBox(width: 8),
                              _buildIconOnlyActionButton(
                                icon: isActive ? Icons.block : Icons.check_circle,
                                color: isActive ? Colors.red : Colors.green,
                                onTap: () => _toggleUserBan(user),
                              ),
                              const SizedBox(width: 8),
                              _buildIconOnlyActionButton(
                                icon: Icons.edit,
                                color: Colors.orange,
                                onTap: () => _showEditUserDialog(user.toMap()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIconOnlyActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Icon(
            icon,
            color: color,
            size: 14,
          ),
        ),
      ),
    );
  }



  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0096C7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add,
                          color: Color(0xFF0096C7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Add New User',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0096C7),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Form content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Name field
                        _buildTextField(
                          controller: nameController,
                          label: 'Full Name',
                          hint: 'Enter full name',
                        ),
                        const SizedBox(height: 16),
                        // Email field
                        _buildTextField(
                          controller: emailController,
                          label: 'Email',
                          hint: 'Enter email address',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        // Username and Password row
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: usernameController,
                                label: 'Username',
                                hint: 'Enter username',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: passwordController,
                                label: 'Password',
                                hint: 'Enter password',
                                isPassword: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogActionButton(
                                text: 'CANCEL',
                                backgroundColor: Colors.grey[300]!,
                                textColor: Colors.grey[700]!,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDialogActionButton(
                                text: 'ADD USER',
                                backgroundColor: const Color(0xFF0096C7),
                                textColor: Colors.white,
                                onPressed: () {
                                  _saveUser(
                                    name: nameController.text,
                                    email: emailController.text,
                                    username: usernameController.text,
                                    password: passwordController.text,
                                  );
                                  Navigator.of(context).pop();
                                },
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
      },
    );
  }

  Widget _buildViewDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _saveUser({
    required String name,
    required String email,
    required String username,
    required String password,
  }) {
    // Here you would implement the actual save logic
    // For now, we'll just show a success message
    _showSnackBar(
      'User "$name" added successfully!',
      isSuccess: true,
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        backgroundColor: isSuccess ? Colors.green : const Color(0xFF0096C7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(
              color: Colors.grey[400],
              fontSize: 14,
            ),
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
              borderSide: const BorderSide(color: Color(0xFF0096C7), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDialogActionButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContentSliver() {
    if (_isLoading) {
      return Container(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: const Color(0xFF0096C7)),
              const SizedBox(height: 16),
              Text(
                'Loading data...',
                style: GoogleFonts.montserrat(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return IndexedStack(
      index: _tabController.index,
      children: [
        _buildUsersTable(),
        _buildAuthorsTable(),
      ],
    );
  }

  // Removed unused _buildMainContent method as it's been replaced by _buildMainContentSliver

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: Stack(
        children: [
          // Main Content - Everything scrollable together
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header as a sliver that scrolls
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              // Search and Actions as a sliver that scrolls
              SliverToBoxAdapter(
                child: _buildSearchAndActions(),
              ),
              // Main content as a sliver
              SliverToBoxAdapter(
                child: _buildMainContentSliver(),
              ),
              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
          // Sidebar Overlay
          if (_isSidebarOpen)
            GestureDetector(
              onTap: _toggleSidebar,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          // Sidebar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: _isSidebarOpen ? 0 : -280,
            top: 0,
            bottom: 0,
            child: AdminSidebar(
              onItemTap: _handleSidebarTap,
              activePage: 'Users',
            ),
          ),
        ],
      ),
    );
  }
}