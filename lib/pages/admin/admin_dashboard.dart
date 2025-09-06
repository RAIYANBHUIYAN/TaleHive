
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'catalog/all_users_books_reqst_Catalog_management.dart';
import 'books/books_and_club_management.dart';
import 'users/user_management.dart';
import '../../components/admin_sidebar.dart';
import '../main_home_page/main_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;
  bool _isSidebarOpen = false;
  bool _isLoading = true;
  
  // Dashboard stats
  Map<String, int> _stats = {
    'users': 0,
    'authors': 0,
    'books': 0,
    'requests': 0,
  };

  // Real user data
  List<Map<String, dynamic>> _recentUsers = [];
  List<Map<String, dynamic>> _currentReaders = [];
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    print('🏗️ AdminDashboard: initState called');
    _loadDashboardData();
  }

  @override
  void dispose() {
    print('🗑️ AdminDashboard: dispose called');
    super.dispose();
  }

  // Load dashboard statistics from Supabase
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all data in parallel
      await Future.wait([
        _loadBasicStats(),
        _loadRecentUsers(),
        _loadCurrentReaders(),
        _loadAnalyticsData(),
      ]);
    } catch (e) {
      print('Error loading dashboard data: $e');
      // Set default values on error
      setState(() {
        _stats = {
          'users': 150,
          'authors': 25,
          'books': 1500,
          'requests': 67,
        };
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Load basic statistics
  Future<void> _loadBasicStats() async {
    try {
      // Load users count
      final usersData = await supabase
          .from('users')
          .select();
      
      // Load books count  
      final booksData = await supabase
          .from('books')
          .select();
      
      // Get unique author count
      final authorBooksData = await supabase
          .from('books')
          .select('author_id')
          .not('author_id', 'is', null);

      final uniqueAuthors = authorBooksData
          .map((book) => book['author_id'])
          .toSet()
          .length;

      // Load real borrow requests count
      final requestsData = await supabase
          .from('borrow_requests')
          .select();

      setState(() {
        _stats['users'] = usersData.length;
        _stats['books'] = booksData.length;
        _stats['authors'] = uniqueAuthors;
        _stats['requests'] = requestsData.length;
      });
    } catch (e) {
      print('Error loading basic stats: $e');
    }
  }

  // Load recent users (last 5)
  Future<void> _loadRecentUsers() async {
    try {
      final response = await supabase
          .from('users')
          .select('id, first_name, last_name, email, created_at')
          .order('created_at', ascending: false)
          .limit(5);
      
      setState(() {
        _recentUsers = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading recent users: $e');
    }
  }

  // Load current readers (from borrow_requests with accepted status)
  Future<void> _loadCurrentReaders() async {
    try {
      final response = await supabase
          .from('borrow_requests')
          .select('''
            id,
            user_id,
            book_id,
            start_date,
            end_date,
            status,
            users:user_id (first_name, last_name, email),
            books:book_id (title, id)
          ''')
          .eq('status', 'accepted')
          .gte('end_date', DateTime.now().toIso8601String().split('T')[0])
          .order('start_date', ascending: false)
          .limit(5);
      
      setState(() {
        _currentReaders = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading current readers: $e');
    }
  }

  // Load analytics data
  Future<void> _loadAnalyticsData() async {
    try {
      // Get overdue books count
      final overdueResponse = await supabase
          .from('borrow_requests')
          .select('id')
          .eq('status', 'accepted')
          .lt('end_date', DateTime.now().toIso8601String().split('T')[0]);

      // Get current borrows count (full count, not limited)
      final currentResponse = await supabase
          .from('borrow_requests')
          .select('id')
          .eq('status', 'accepted')
          .gte('end_date', DateTime.now().toIso8601String().split('T')[0]);

      // Get books borrowed this month
      final thisMonth = DateTime.now();
      final firstDayOfMonth = DateTime(thisMonth.year, thisMonth.month, 1);
      
      final monthlyBorrowsResponse = await supabase
          .from('borrow_requests')
          .select('id')
          .eq('status', 'accepted')
          .gte('created_at', firstDayOfMonth.toIso8601String());

      // Get most popular category
      final categoriesResponse = await supabase
          .from('books')
          .select('category')
          .not('category', 'is', null);

      // Count categories
      final categoryCount = <String, int>{};
      for (final book in categoriesResponse) {
        final category = book['category']?.toString() ?? 'Unknown';
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
      
      final mostPopularCategory = categoryCount.entries
          .reduce((a, b) => a.value > b.value ? a : b);

      setState(() {
        _analyticsData = {
          'overdue_books': overdueResponse.length,
          'current_borrows': currentResponse.length,
          'monthly_borrows': monthlyBorrowsResponse.length,
          'popular_category': mostPopularCategory.key,
          'total_categories': categoryCount.length,
        };
      });
    } catch (e) {
      print('Error loading analytics data: $e');
    }
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

  void _toggleSidebar() {
    print('🔄 AdminDashboard: Toggling sidebar. Current state: $_isSidebarOpen');
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
    print('🔄 AdminDashboard: Sidebar toggled to: $_isSidebarOpen');
  }

  void _handleSidebarTap(String label) {
    print('🎯 AdminDashboard: Sidebar tapped - $label');
    if (label == 'Log Out') {
      _showLogoutDialog();
    } else if (label == 'Catalog') {
      print('📚 AdminDashboard: Navigating to Catalog page');
      // Close sidebar BEFORE navigation to prevent state conflicts
      _toggleSidebar();
      // Add a small delay to ensure sidebar closes completely
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          print('🚀 AdminDashboard: Pushing Catalog page');
          Navigator.of(context).push(_createRoute(const AllUsersBookRequestCatalogManagementPage()));
        } else {
          print('❌ AdminDashboard: Widget not mounted, skipping navigation');
        }
      });
    } else if (label == 'Books') {
      _toggleSidebar();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).push(_createRoute(const BooksAndClubManagementPage()));
        }
      });
    } else if (label == 'Users') {
      _toggleSidebar();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).push(_createRoute(const UserManagementPage()));
        }
      });
    } else {
      _toggleSidebar();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔄 AdminDashboard: build called (sidebar: $_isSidebarOpen)');
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Main Content
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : (isMobile ? _buildMobileContent() : _buildDesktopContent()),
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
              activePage: 'Dashboard', // Set Dashboard as active
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile ? _buildMobileHeader() : _buildDesktopHeader(),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0096C7).withOpacity(0.1),
            const Color(0xFF0096C7).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Hamburger Menu Button (Left)
          GestureDetector(
            onTap: _toggleSidebar,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0096C7),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0096C7).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          // Center Text
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Admin Dashboard',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  Text(
                    'Library Management',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Refresh Button
          GestureDetector(
            onTap: _loadDashboardData,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.refresh,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0096C7).withOpacity(0.1),
            const Color(0xFF0096C7).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Hamburger Menu Button (Left)
          GestureDetector(
            onTap: _toggleSidebar,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0096C7),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0096C7).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          // Center Text
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Admin Dashboard',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  Text(
                    'Manage your library system efficiently',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Refresh Button
          GestureDetector(
            onTap: _loadDashboardData,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.refresh,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: const Color(0xFF0096C7),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Pie Chart Section
            Container(
              key: const ValueKey('mobile_pie_chart'),
              margin: const EdgeInsets.only(bottom: 24),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  '📊 Book Status Overview',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 1.0,
                  child: PieChart(
                    PieChartData(
                      sections: _getPieChartSections(),
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      color: Colors.green,
                      label: '✅ Available Books',
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      color: const Color(0xFF0096C7),
                      label: '📖 Currently Borrowed',
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      color: Colors.red,
                      label: '⚠️ Overdue Books',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Stats Cards Section
          Column(
            children: [
              // First row - Users and Authors
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.people,
                      value: _stats['users'].toString().padLeft(4, '0'),
                      label: 'Total Users',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.person_outline,
                      value: _stats['authors'].toString().padLeft(3, '0'),
                      label: 'Total Authors',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Second row - Books and Requests
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.library_books,
                      value: _stats['books'].toString().padLeft(5, '0'),
                      label: 'Total Books',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.request_page,
                      value: _stats['requests'].toString().padLeft(3, '0'),
                      label: 'Borrow Requests',
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Info Cards Section
          Column(
            children: [
              _buildInfoCard(
                title: '👥 Recent Users',
                content: _recentUsers.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No recent users found', 
                                   style: TextStyle(color: Colors.grey)),
                      ))
                    : Column(
                        children: _recentUsers.map((user) => _buildUserDetailItem(user: user)).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: '📚 Current Readers',
                content: _currentReaders.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No current readers found',
                                   style: TextStyle(color: Colors.grey)),
                      ))
                    : Column(
                        children: _currentReaders.map((reader) => _buildBookReaderItem(reader: reader)).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              // Analytics Card for Mobile
              _buildInfoCard(
                title: '📊 Analytics Overview',
                content: Column(
                  children: [
                    _buildAnalyticsItem(
                      '🔴 Overdue Books',
                      '${_analyticsData['overdue_books'] ?? 0}',
                      Colors.red,
                    ),
                    _buildAnalyticsItem(
                      '📖 Current Borrows',
                      '${_analyticsData['current_borrows'] ?? 0}',
                      Colors.blue,
                    ),
                    _buildAnalyticsItem(
                      '📈 Monthly Borrows',
                      '${_analyticsData['monthly_borrows'] ?? 0}',
                      Colors.green,
                    ),
                    _buildAnalyticsItem(
                      '🏷️ Popular Category',
                      '${_analyticsData['popular_category'] ?? 'N/A'}',
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildDesktopContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side - Pie Chart
          Expanded(
            flex: 2,
            child: Container(
              key: const ValueKey('desktop_pie_chart'),
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Book Status Overview',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: _getPieChartSections(),
                        sectionsSpace: 0,
                        centerSpaceRadius: 60,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                        color: Colors.green,
                        label: '✅ Available Books',
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        color: const Color(0xFF0096C7),
                        label: '📖 Currently Borrowed',
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        color: Colors.red,
                        label: '⚠️ Overdue Books',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Right Side - Stats and Cards
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Top Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.people,
                        value: _stats['users'].toString().padLeft(4, '0'),
                        label: 'Total Users',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.person_outline,
                        value: _stats['authors'].toString().padLeft(3, '0'),
                        label: 'Total Authors',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.library_books,
                        value: _stats['books'].toString().padLeft(5, '0'),
                        label: 'Total Books',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.request_page,
                        value: _stats['requests'].toString().padLeft(3, '0'),
                        label: 'Borrow Requests',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Bottom Cards Row
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          title: '👥 Recent Users',
                          content: _recentUsers.isEmpty
                              ? const Center(child: Text('No recent users found',
                                               style: TextStyle(color: Colors.grey)))
                              : ListView(
                                  children: _recentUsers.map((user) => _buildUserDetailItem(user: user)).toList(),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          title: '📚 Current Readers',
                          content: _currentReaders.isEmpty
                              ? const Center(child: Text('No current readers found',
                                               style: TextStyle(color: Colors.grey)))
                              : ListView(
                                  children: _currentReaders.map((reader) => _buildBookReaderItem(reader: reader)).toList(),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          title: '📊 Analytics',
                          content: ListView(
                            children: [
                              _buildAnalyticsItem(
                                '🔴 Overdue Books',
                                '${_analyticsData['overdue_books'] ?? 0}',
                                Colors.red,
                              ),
                              _buildAnalyticsItem(
                                '📖 Current Borrows',
                                '${_analyticsData['current_borrows'] ?? 0}',
                                const Color(0xFF0096C7),
                              ),
                              _buildAnalyticsItem(
                                '📈 Monthly Borrows',
                                '${_analyticsData['monthly_borrows'] ?? 0}',
                                Colors.green,
                              ),
                              _buildAnalyticsItem(
                                '🏷️ Popular Category',
                                '${_analyticsData['popular_category'] ?? 'N/A'}',
                                Colors.orange,
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFF4A5568),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
      child: isMobile ? Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0096C7),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF4A5568),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ) : Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0096C7),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required Widget content,
  }) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      constraints: isMobile 
          ? null 
          : const BoxConstraints(minHeight: 300),
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
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: content,
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: content,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserDetailItem({required Map<String, dynamic> user}) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    
    final userName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final userEmail = user['email'] ?? 'No email';
    final joinedDate = _formatJoinedDate(user['created_at']);
    final isOnline = _isRecentlyJoined(user['created_at']);
    
    return Container(
      margin: EdgeInsets.only(bottom: 8, left: isMobile ? 16 : 20, right: isMobile ? 16 : 20),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 16 : 20,
            backgroundColor: const Color(0xFF0096C7),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: isMobile ? 16 : 20,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isEmpty ? 'Unknown User' : userName,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 12 : 14,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 10 : 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined: $joinedDate',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 9 : 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'Recent' : 'Offline',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: isOnline ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
          Container(
            padding: EdgeInsets.all(isMobile ? 2 : 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0096C7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.sync,
              color: const Color(0xFF0096C7),
              size: isMobile ? 12 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookReaderItem({required Map<String, dynamic> reader}) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    
    final userInfo = reader['users'] as Map<String, dynamic>?;
    final bookInfo = reader['books'] as Map<String, dynamic>?;
    
    final userName = userInfo != null 
        ? '${userInfo['first_name'] ?? ''} ${userInfo['last_name'] ?? ''}'.trim()
        : 'Unknown User';
    
    final bookTitle = bookInfo?['title'] ?? 'Unknown Book';
    final endDate = reader['end_date'] as String?;
    
    // Calculate days remaining
    String daysRemaining = 'Unknown';
    if (endDate != null) {
      try {
        final endDateTime = DateTime.parse(endDate);
        final now = DateTime.now();
        final difference = endDateTime.difference(now).inDays;
        
        if (difference < 0) {
          daysRemaining = 'Overdue';
        } else if (difference == 0) {
          daysRemaining = 'Due today';
        } else {
          daysRemaining = '$difference days left';
        }
      } catch (e) {
        daysRemaining = 'Unknown';
      }
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 8, left: isMobile ? 16 : 20, right: isMobile ? 16 : 20),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 16 : 20,
            backgroundColor: const Color(0xFF0096C7),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: isMobile ? 16 : 20,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isEmpty ? 'Unknown User' : userName,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 12 : 14,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bookTitle.length > 30 
                      ? '${bookTitle.substring(0, 30)}...'
                      : bookTitle,
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 10 : 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  daysRemaining,
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 9 : 11,
                    color: daysRemaining.contains('Overdue') 
                        ? Colors.red 
                        : daysRemaining.contains('Due today')
                            ? Colors.orange
                            : Colors.grey[500],
                    fontWeight: daysRemaining.contains('Overdue') || daysRemaining.contains('Due today')
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: daysRemaining.contains('Overdue') 
                        ? Colors.red 
                        : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Reading',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
          Container(
            padding: EdgeInsets.all(isMobile ? 2 : 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0096C7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.book,
              color: const Color(0xFF0096C7),
              size: isMobile ? 12 : 16,
            ),
          ),
        ],
      ),
    );
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
              onPressed: _performLogout,
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

  Future<void> _performLogout() async {
    try {
      Navigator.pop(context);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Logging out...'),
            ],
          ),
        ),
      );

      await supabase.auth.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Helper methods for date formatting and status checking
  String _formatJoinedDate(String? createdAt) {
    if (createdAt == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else if (difference < 7) {
        return '$difference days ago';
      } else {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  bool _isRecentlyJoined(String? createdAt) {
    if (createdAt == null) return false;
    
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      return difference <= 7; // Consider users joined within 7 days as "recent/online"
    } catch (e) {
      return false;
    }
  }

  // Get pie chart sections with real analytics data
  List<PieChartSectionData> _getPieChartSections() {
    final overdueBooks = _analyticsData['overdue_books'] as int? ?? 0;
    final currentBorrows = _analyticsData['current_borrows'] as int? ?? 0;
    final totalBooks = _stats['books'] ?? 0;
    final availableBooks = totalBooks - (overdueBooks + currentBorrows);

    return [
      PieChartSectionData(
        color: Colors.green,
        value: availableBooks.toDouble(),
        title: '',
        radius: 60,
      ),
      PieChartSectionData(
        color: const Color(0xFF0096C7),
        value: currentBorrows.toDouble(),
        title: '',
        radius: 60,
      ),
      PieChartSectionData(
        color: Colors.red,
        value: overdueBooks.toDouble(),
        title: '',
        radius: 60,
      ),
    ];
  }

  // Build analytics item for mobile view
  Widget _buildAnalyticsItem(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              label.contains('Overdue') ? Icons.warning
                : label.contains('Current') ? Icons.book
                : label.contains('Monthly') ? Icons.trending_up
                : Icons.category,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

