import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../services/notification_service.dart';
import '../../../services/reading_analytics_service.dart';
import '../../../components/admin_sidebar.dart';
import '../books/books_and_club_management.dart';
import '../users/user_management.dart';
import '../../main_home_page/main_page.dart';

class AllUsersBookRequestCatalogManagementPage extends StatefulWidget {
  const AllUsersBookRequestCatalogManagementPage({Key? key}) : super(key: key);

  @override
  State<AllUsersBookRequestCatalogManagementPage> createState() =>
      _AllUsersBookRequestCatalogManagementPageState();
}

class _AllUsersBookRequestCatalogManagementPageState
    extends State<AllUsersBookRequestCatalogManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final supabase = Supabase.instance.client;
  final ReadingAnalyticsService _analyticsService = ReadingAnalyticsService();
  bool _isLoading = false;
  
  // Sidebar state
  bool _isSidebarOpen = false;

  // Filter state
  String _selectedCategory = 'All';
  List<String> _categories = [
    'All',
    'Programming',
    'AI/ML',
    'Technical',
    'Design',
    'Business',
    'Science',
  ];

  // Real data from database instead of sample data
  List<Map<String, dynamic>> _currentReadings = [];
  List<Map<String, dynamic>> _popularBooks = [];
  List<Map<String, dynamic>> _bookRequests = [];

  // Real borrow requests from database
  List<Map<String, dynamic>> _borrowRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Add debug listener to track tab changes
    _tabController.addListener(() {
      print('📊 Tab changed to index: ${_tabController.index}');
    });
    
    _searchController.addListener(() {
      setState(() {
        // Trigger rebuild when search text changes
      });
    });
    _loadAllData();
  }

  // Load all data
  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Load all data in parallel
      await Future.wait([
        _loadCurrentReadings(),
        _loadPopularBooks(),
        _loadBorrowRequests(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Load current readings (Reading Books tab)
  Future<void> _loadCurrentReadings() async {
    try {
      final readings = await _analyticsService.getCurrentReadings();
      if (mounted) {
        setState(() {
          _currentReadings = readings;
        });
      }
    } catch (e) {
      print('Error loading current readings: $e');
    }
  }

  // Load popular books (Most Readable Books tab)
  Future<void> _loadPopularBooks() async {
    try {
      final books = await _analyticsService.getMostPopularBooks();
      if (mounted) {
        setState(() {
          _popularBooks = books;
        });
      }
    } catch (e) {
      print('Error loading popular books: $e');
    }
  }

  // Load real borrow requests from Supabase
  Future<void> _loadBorrowRequests() async {
    try {
      final response = await supabase
          .from('borrow_requests')
          .select('''
            id,
            book_id,
            user_id,
            reason,
            start_date,
            end_date,
            status,
            created_at,
            books(title, cover_image_url),
            users(first_name, last_name, email)
          ''')
          .order('created_at', ascending: false);
      
      print('Raw borrow requests response: $response');
      print('Response length: ${response.length}');
      
      // Only update state if widget is still mounted
      if (mounted) {
        setState(() {
          _borrowRequests = List<Map<String, dynamic>>.from(response);
          // Transform borrow requests to match the table format
          _bookRequests = _borrowRequests.map((request) {
            final book = request['books'] as Map<String, dynamic>?;
            final user = request['users'] as Map<String, dynamic>?;
            final createdAt = DateTime.parse(request['created_at']);
            
            return {
              'requestId': request['id'],
              'userId': request['user_id'],
              'userName': user != null 
                  ? '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim()
                  : 'Unknown User',
              'userEmail': user?['email'] ?? '',
              'bookTitle': book?['title'] ?? 'Unknown Book',
              'bookCover': book?['cover_image_url'] ?? '',
              'reason': request['reason'] ?? '',
              'startDate': request['start_date'],
              'endDate': request['end_date'],
              'requestDate': DateFormat('dd-MM-yyyy').format(createdAt),
              'status': request['status'],
              'rawData': request, // Keep original data for actions
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading borrow requests: $e');
    }
  }

  @override
  void dispose() {
    print('🔴 AllUsersBookRequestCatalogManagementPage is being disposed!');
    print('🔴 Current loading state: $_isLoading');
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
    } else if (label == 'Books') {
      _toggleSidebar();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(_createRoute(const BooksAndClubManagementPage()));
        }
      });
    } else if (label == 'Users') {
      _toggleSidebar();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(_createRoute(const UserManagementPage()));
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

  // Filter methods
  List<Map<String, dynamic>> _getFilteredReadingBooks() {
    List<Map<String, dynamic>> filteredBooks = _selectedCategory == 'All'
        ? _currentReadings
        : _currentReadings
              .where(
                (reading) => (reading['category'] ?? 'Unknown') == _selectedCategory,
              )
              .toList();

    // Apply search filter if search text is not empty
    if (_searchController.text.isNotEmpty) {
      String searchText = _searchController.text.toLowerCase();
      filteredBooks = filteredBooks
          .where(
            (reading) =>
                (reading['book_title'] ?? '').toString().toLowerCase().contains(searchText) ||
                (reading['user_name'] ?? '').toString().toLowerCase().contains(searchText) ||
                (reading['author_name'] ?? '').toString().toLowerCase().contains(searchText) ||
                (reading['category'] ?? '').toString().toLowerCase().contains(searchText),
          )
          .toList();
    }

    return filteredBooks;
  }

  List<Map<String, dynamic>> _getFilteredMostReadableBooks() {
    List<Map<String, dynamic>> filteredBooks = _selectedCategory == 'All'
        ? _popularBooks
        : _popularBooks
              .where(
                (book) => (book['category'] ?? 'Unknown') == _selectedCategory,
              )
              .toList();

    // Apply search filter if search text is not empty
    if (_searchController.text.isNotEmpty) {
      String searchText = _searchController.text.toLowerCase();
      filteredBooks = filteredBooks
          .where(
            (book) =>
                (book['book_title'] ?? '').toString().toLowerCase().contains(searchText) ||
                (book['author_name'] ?? '').toString().toLowerCase().contains(searchText) ||
                (book['category'] ?? '').toString().toLowerCase().contains(searchText),
          )
          .toList();
    }

    return filteredBooks;
  }

  void _showReadingActionsDialog(Map<String, dynamic> reading) {
    final isExpired = reading['days_remaining'] != null && reading['days_remaining'] < 0;
    final isDueToday = reading['status'] == 'due_today';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reading Details',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book: ${reading['book_title'] ?? 'Unknown'}',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Reader: ${reading['user_name'] ?? 'Unknown'}',
                style: GoogleFonts.montserrat(),
              ),
              const SizedBox(height: 8),
              Text(
                'Due Date: ${reading['due_date'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(reading['due_date'])) : 'N/A'}',
                style: GoogleFonts.montserrat(),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${reading['status'] ?? 'Unknown'}',
                style: GoogleFonts.montserrat(
                  color: reading['status'] == 'overdue' 
                      ? Colors.red 
                      : isDueToday 
                          ? Colors.orange 
                          : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isExpired) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    '⚠️ Book access has expired. User can no longer read this book.',
                    style: GoogleFonts.montserrat(
                      color: Colors.red[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.montserrat(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => _extendDueDate(reading),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text(
                isExpired ? 'Renew Access' : 'Extend Due Date',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Extend due date
  void _extendDueDate(Map<String, dynamic> reading) {
    Navigator.of(context).pop();
    
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((selectedDate) async {
      if (selectedDate != null) {
        final success = await _analyticsService.extendDueDate(
          reading['reading_id'].toString(),
          selectedDate,
        );
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Due date extended successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCurrentReadings(); // Refresh data
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to extend due date'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _applyFilter(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF0096C7),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
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
                    'Catalog Management',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: const Color(0xFF0096C7),
                  borderRadius: BorderRadius.circular(8),
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
                  Tab(text: 'Reading Books'),
                  Tab(text: 'Most Readable Books'),
                  Tab(text: 'Book Request'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
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
                  hintText: 'Search by ID or Category',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _showCategoryFilter();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCategory == 'All'
                            ? 'Books Category'
                            : _selectedCategory,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _selectedCategory == 'All'
                              ? Colors.grey[700]
                              : const Color(0xFF0096C7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.filter_list,
                        color: _selectedCategory == 'All'
                            ? Colors.grey[700]
                            : const Color(0xFF0096C7),
                        size: 18,
                      ),
                      if (_selectedCategory != 'All') ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _applyFilter('All'),
                          child: Icon(
                            Icons.clear,
                            color: Colors.red[600],
                            size: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSummary() {
    int readingCount = _getFilteredReadingBooks().length;
    int mostReadableCount = _getFilteredMostReadableBooks().length;

    if (_selectedCategory == 'All' && _searchController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0096C7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF0096C7).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: const Color(0xFF0096C7), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedCategory != 'All'
                  ? 'Filtered by: $_selectedCategory • Reading: $readingCount, Most Readable: $mostReadableCount'
                  : 'Search results • Reading: $readingCount, Most Readable: $mostReadableCount',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFF0096C7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_selectedCategory != 'All' || _searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _applyFilter('All');
                _searchController.clear();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0096C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Clear All',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReadingBooksTable() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: const Color(0xFF0096C7)),
              const SizedBox(height: 16),
              Text(
                'Loading current readings...',
                style: GoogleFonts.montserrat(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_getFilteredReadingBooks().isEmpty) {
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
              Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No current readings found',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'There are no books currently being read by users',
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
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3, // Responsive aspect ratio
            ),
            itemCount: _getFilteredReadingBooks().length,
            itemBuilder: (context, index) {
              final reading = _getFilteredReadingBooks()[index];
              final daysRemaining = reading['days_remaining'] ?? 0;
              final isOverdue = reading['status'] == 'overdue';
              final isDueToday = reading['status'] == 'due_today';
              
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOverdue 
                        ? Colors.red.withOpacity(0.3)
                        : isDueToday 
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.1),
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
                      // Header with status indicator
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isOverdue 
                                    ? Colors.red.withOpacity(0.1)
                                    : isDueToday 
                                        ? Colors.orange.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isOverdue 
                                    ? 'OVERDUE'
                                    : isDueToday 
                                        ? 'DUE TODAY'
                                        : 'READING',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isOverdue 
                                      ? Colors.red[700]
                                      : isDueToday 
                                          ? Colors.orange[700]
                                          : Colors.green[700],
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showReadingActionsDialog(reading),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0096C7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.more_vert,
                                color: const Color(0xFF0096C7),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Book Title
                      Expanded(
                        flex: 2,
                        child: Text(
                          reading['book_title'] ?? 'Unknown Book',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D3748),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Author
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              reading['author_name'] ?? 'Unknown Author',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Reader Info
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.account_circle_outlined,
                                  color: Colors.purple[700],
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Reader',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 8,
                                        color: Colors.purple[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      reading['user_name'] ?? 'Unknown User',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        color: Colors.purple[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Footer with due date and category
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Due Date',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 8,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  reading['due_date'] != null 
                                      ? DateFormat('dd MMM').format(DateTime.parse(reading['due_date']))
                                      : 'N/A',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    color: isOverdue ? Colors.red[700] : const Color(0xFF2D3748),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (daysRemaining != 0)
                                  Text(
                                    isOverdue 
                                        ? '${(-daysRemaining).abs()}d overdue'
                                        : isDueToday
                                            ? 'Due today!'
                                            : '${daysRemaining}d left',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 8,
                                      color: isOverdue 
                                          ? Colors.red[600]
                                          : isDueToday
                                              ? Colors.orange[600]
                                              : Colors.green[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(
                                reading['category'] ?? 'Unknown',
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              reading['category'] ?? 'Unknown',
                              style: GoogleFonts.montserrat(
                                fontSize: 8,
                                color: _getCategoryColor(
                                  reading['category'] ?? 'Unknown',
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

  Widget _buildMostReadableBooksTable() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: const Color(0xFF0096C7)),
              const SizedBox(height: 16),
              Text(
                'Loading popular books...',
                style: GoogleFonts.montserrat(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_getFilteredMostReadableBooks().isEmpty) {
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
              Icon(Icons.trending_up, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No popular books data found',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Popular books will appear here as users start reading',
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
          int crossAxisCount = 3;
          if (constraints.maxWidth > 1400) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth > 1000) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth > 600) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = 1;
          }
          
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1, // Responsive aspect ratio
            ),
            itemCount: _getFilteredMostReadableBooks().length,
            itemBuilder: (context, index) {
              final book = _getFilteredMostReadableBooks()[index];
              final totalBorrows = book['total_borrows'] ?? 0;
              final uniqueReaders = book['unique_readers'] ?? 0;
              
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.1),
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
                      // Header with popularity badge
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.withOpacity(0.1),
                                    Colors.amber.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    size: 12,
                                    color: Colors.orange[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'POPULAR',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange[700],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showBookReviewsDialog(book['book_id']?.toString() ?? ''),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.star,
                                color: Colors.amber[700],
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Book Title
                      Expanded(
                        flex: 2,
                        child: Text(
                          book['book_title'] ?? 'Unknown Book',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D3748),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Author
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              book['author_name'] ?? 'Unknown Author',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Statistics Row
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0096C7).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FittedBox(
                                      child: Text(
                                        totalBorrows.toString(),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0096C7),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Borrows',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 8,
                                        color: const Color(0xFF0096C7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FittedBox(
                                      child: Text(
                                        uniqueReaders.toString(),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.purple[700],
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Readers',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 8,
                                        color: Colors.purple[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Footer with category and last borrowed
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (book['last_borrowed_date'] != null) ...[
                                  Text(
                                    'Last Borrowed',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 8,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMM').format(DateTime.parse(book['last_borrowed_date'])),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 9,
                                      color: const Color(0xFF2D3748),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(
                                book['category'] ?? 'Unknown',
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              book['category'] ?? 'Unknown',
                              style: GoogleFonts.montserrat(
                                fontSize: 8,
                                color: _getCategoryColor(
                                  book['category'] ?? 'Unknown',
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

  Widget _buildBookRequestsTable() {
    print('Building book requests table. Loading: $_isLoading');
    print('Book requests count: ${_bookRequests.length}');
    
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: const Color(0xFF0096C7)),
              const SizedBox(height: 20),
              Text(
                'Loading borrow requests...',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_bookRequests.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                'No borrow requests found',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'User book requests will appear here',
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

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive columns based on available width
            final maxWidth = constraints.maxWidth;
            double cardWidth = maxWidth;
            
            if (maxWidth > 1200) {
              cardWidth = (maxWidth - 48) / 3; // 48 = spacing between 3 cards
            } else if (maxWidth > 800) {
              cardWidth = (maxWidth - 24) / 2; // 24 = spacing between 2 cards
            }
            
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _bookRequests.map((request) {
                final status = request['status']?.toString().toLowerCase() ?? 'unknown';
                final isPending = status == 'pending';
                
                return Container(
                  width: cardWidth,
                  constraints: BoxConstraints(
                    minHeight: 400, // Minimum height but can expand
                    maxWidth: cardWidth,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Important: let content determine height
                  children: [
                  // Header with request ID and status
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0096C7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Req #${request['requestId']}',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0096C7),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // User info section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.purple[700],
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'User',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      color: Colors.purple[600],
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    request['userName'] ?? 'Unknown User',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      color: Colors.purple[700],
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ID: ${request['userId']}',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              color: Colors.purple[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Book info section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0096C7).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0096C7).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.book,
                                color: const Color(0xFF0096C7),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Book',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      color: const Color(0xFF0096C7),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    request['bookTitle'] ?? 'Unknown Book',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      color: const Color(0xFF0096C7),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Request date
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          request['requestDate'] ?? 'Unknown Date',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Column(
                    children: [
                      // View Details button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showRequestDetailsDialog(request),
                          icon: Icon(
                            Icons.visibility,
                            size: 16,
                            color: const Color(0xFF0096C7),
                          ),
                          label: Text(
                            'View Details',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: const Color(0xFF0096C7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0096C7).withOpacity(0.1),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: const Color(0xFF0096C7),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      if (isPending) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approveBorrowRequest(request),
                                icon: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Approve',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _rejectBorrowRequest(request),
                                icon: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Reject',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                  ]),
                  ],
                ),
              ));
          }).toList(),
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getCategoryColor(String? category) {
    if (category == null) return Colors.grey;

    switch (category.toLowerCase()) {
      case 'programming':
        return const Color(0xFF0096C7);
      case 'ai/ml':
        return Colors.purple;
      case 'technical':
        return Colors.orange;
      case 'design':
        return Colors.pink;
      case 'business':
        return Colors.teal;
      case 'science':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Filter by Category',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _categories.map((category) {
                    return RadioListTile<String>(
                      title: Text(
                        category,
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                      value: category,
                      groupValue: _selectedCategory,
                      activeColor: const Color(0xFF0096C7),
                      onChanged: (String? value) {
                        if (value != null) {
                          setDialogState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.montserrat(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _applyFilter(_selectedCategory);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0096C7),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRequestDetailsDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Borrow Request Details',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Borrow ID:', request['requestId']),
                    _buildDetailRow('User Name:', request['userName']),
                    _buildDetailRow('User Email:', request['userEmail'] ?? ''),
                    _buildDetailRow('Book Title:', request['bookTitle']),
                    _buildDetailRow('Reason:', request['reason'] ?? 'No reason provided'),
                    _buildDetailRow('Collection Date:', request['startDate'] != null 
                        ? DateFormat('dd MMM yyyy').format(DateTime.parse(request['startDate']))
                        : 'Not specified'),
                    _buildDetailRow('Return Date:', request['endDate'] != null 
                        ? DateFormat('dd MMM yyyy').format(DateTime.parse(request['endDate']))
                        : 'Not specified'),
                    _buildDetailRow('Request Date:', request['requestDate']),
                    _buildDetailRow('Status:', request['status']),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.montserrat(color: Colors.grey[600]),
                  ),
                ),
                if (request['status'] == 'pending') ...[
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _approveBorrowRequest(request, dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading ? Colors.grey : Colors.green,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Approve',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _rejectBorrowRequest(request, dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading ? Colors.grey : Colors.red,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Reject',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // Approve borrow request
  Future<void> _approveBorrowRequest(Map<String, dynamic> request, [BuildContext? dialogContext]) async {
    print('🟢 Starting approval process for request: ${request['requestId']}');
    
    // Prevent multiple calls
    if (_isLoading) {
      print('🟡 Already loading, skipping approval');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      print('🟢 Updating database status to accepted');
      // Perform database update
      await supabase
          .from('borrow_requests')
          .update({'status': 'accepted'})
          .eq('id', request['requestId']);
      
      print('🟢 Database updated successfully');
      
      // Try to create notification (handle gracefully if it fails)
      try {
        print('🔔 Creating notification...');
        await NotificationService.createNotification(
          userId: request['userId'],
          type: 'borrow_approved',
          title: 'Request Approved',
          body: 'Your borrow request for "${request['bookTitle'] ?? 'book'}" has been approved!',
          data: {
            'request_id': request['requestId'],
            'book_id': request['bookId'],
            'book_title': request['bookTitle'],
          },
        );
        print('🔔 Notification created successfully');
      } catch (notificationError) {
        print('🟡 Failed to create notification (non-critical): $notificationError');
      }
      
      print('🚪 Closing dialog...');
      // Close ONLY the dialog using the specific dialog context
      if (dialogContext != null && mounted) {
        Navigator.of(dialogContext).pop();
      }
      
      // Ensure we stay on Book Request tab (index 2)
      if (_tabController.index != 2) {
        print('📊 Switching to Book Request tab (index 2)');
        _tabController.animateTo(2);
      } else {
        print('📊 Already on Book Request tab (index 2)');
      }
      
      print('🔄 Refreshing data...');
      // Refresh data and show success message
      await _loadBorrowRequests();
      print('🔄 Data refreshed successfully');
      
      print('✅ Showing success message...');
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Borrow request approved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        print('✅ Success message shown');
      }
      
    } catch (e) {
      print('🔴 Error in approval: $e');
      // Close dialog on error too using the specific dialog context
      if (dialogContext != null && mounted) {
        Navigator.of(dialogContext).pop();
      }
      
      // Ensure we stay on Book Request tab (index 2)
      if (_tabController.index != 2) {
        print('📊 Switching to Book Request tab (index 2) after approval error');
        _tabController.animateTo(2);
      } else {
        print('📊 Already on Book Request tab (index 2)');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to approve request: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      print('🏁 Finalizing approval process...');
      if (mounted) {
        setState(() => _isLoading = false);
        print('🏁 Loading state set to false');
      }
    }
  }

  // Reject borrow request  
  Future<void> _rejectBorrowRequest(Map<String, dynamic> request, [BuildContext? dialogContext]) async {
    // Prevent multiple calls
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Perform database update
      await supabase
          .from('borrow_requests')
          .update({'status': 'rejected'})
          .eq('id', request['requestId']);
      
      // Try to create notification (handle gracefully if it fails)
      try {
        await NotificationService.createNotification(
          userId: request['userId'],
          type: 'borrow_rejected',
          title: 'Request Rejected',
          body: 'Your borrow request for "${request['bookTitle'] ?? 'book'}" has been rejected.',
          data: {
            'request_id': request['requestId'],
            'book_id': request['bookId'],
            'book_title': request['bookTitle'],
          },
        );
      } catch (notificationError) {
        print('Failed to create notification (non-critical): $notificationError');
      }
      
      // Close ONLY the dialog using the specific dialog context
      if (dialogContext != null && mounted) {
        Navigator.of(dialogContext).pop();
      }
      
      // Ensure we stay on Book Request tab (index 2)
      if (_tabController.index != 2) {
        print('📊 Switching to Book Request tab (index 2)');
        _tabController.animateTo(2);
      } else {
        print('📊 Already on Book Request tab (index 2)');
      }
      
      // Refresh data
      await _loadBorrowRequests();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Borrow request rejected.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e) {
      print('Error in rejection: $e');
      // Close dialog on error too using the specific dialog context
      if (dialogContext != null && mounted) {
        Navigator.of(dialogContext).pop();
      }
      
      // Ensure we stay on Book Request tab (index 2)
      if (_tabController.index != 2) {
        print('📊 Switching to Book Request tab (index 2) after rejection error');
        _tabController.animateTo(2);
      } else {
        print('📊 Already on Book Request tab (index 2)');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to reject request: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showBookReviewsDialog(String bookId) {
    // Sample reviews data for the book
    List<Map<String, dynamic>> reviews = [
      {
        'userName': 'User Name',
        'userImage': 'Asset/images/arif.jpg',
        'rating': 5,
        'date': 'Month DD, YYYY',
        'reviewText':
            'Ut commodo elit adipiscing hendrerit non non elementum id ui cursus non odio vel tincidunt quam et, ac sit Nam et, malesuada non placerat Nunc orci ex, eget.\n\nIpsum ex sapien Lorem varius libero, placerat Cras nec dui Donec in ex felis, volutpat sit amet, varius tincidunt non tortor, elit. Morbi turpis venenatis dui.\n\nNullam tincidunt lorem, ipsum Donec fringilla Vestibulum sit consectetur Nam qui, hendrerit vitae turpis lorem. Quisque placerat ex. Cras massa ex ex rutli ex.',
        'likes': 54,
        'viewReacts': true,
        'viewComment': true,
      },
      {
        'userName': 'User Name',
        'userImage': 'Asset/images/loren.jpg',
        'rating': 4,
        'date': 'Month DD, YYYY',
        'reviewText':
            'Ut commodo elit adipiscing hendrerit non non elementum id ui cursus non odio vel tincidunt quam et, ac sit Nam et, malesuada non placerat Nunc orci ex, eget.\n\nIpsum ex sapien Lorem varius libero, placerat Cras nec dui Donec in ex felis, volutpat sit amet, varius tincidunt non tortor, elit. Morbi turpis venenatis dui.\n\nNullam tincidunt lorem, ipsum Donec fringilla Vestibulum sit consectetur Nam qui, hendrerit vitae turpis lorem. Quisque placerat ex. Cras massa ex ex rutli ex.',
        'likes': 54,
        'viewReacts': true,
        'viewComment': true,
      },
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Book Reviews - Book ID: $bookId',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 16,
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Reviews List
                Expanded(
                  child: ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Info Row
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage: AssetImage(
                                    review['userImage'],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review['userName'],
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: const Color(0xFF2D3748),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          // Star Rating
                                          Row(
                                            children: List.generate(5, (
                                              starIndex,
                                            ) {
                                              return Icon(
                                                starIndex < review['rating']
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber[600],
                                                size: 16,
                                              );
                                            }),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            review['date'],
                                            style: GoogleFonts.montserrat(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Review Text
                            Text(
                              review['reviewText'],
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: const Color(0xFF4A5568),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Action Buttons
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Text(
                                    '${review['likes']} Likes',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  if (review['viewReacts'])
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'View reacts',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  if (review['viewComment'])
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'View Comment',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0096C7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Hide',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Delete',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF4A5568),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation during operations
        if (_isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⏳ Please wait for the current operation to complete'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Stack(
          children: [
            // Main Content
            Column(
              children: [
                _buildHeader(),
                _buildSearchAndFilter(),
                _buildFilterSummary(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: _isLoading ? NeverScrollableScrollPhysics() : null,
                    children: [
                      SingleChildScrollView(child: _buildReadingBooksTable()),
                      SingleChildScrollView(child: _buildMostReadableBooksTable()),
                      SingleChildScrollView(child: _buildBookRequestsTable()),
                    ],
                  ),
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
                activePage: 'Catalog', // Set Catalog as active
              ),
            ),
          ],
        ),
      ),
    );
  }
}
