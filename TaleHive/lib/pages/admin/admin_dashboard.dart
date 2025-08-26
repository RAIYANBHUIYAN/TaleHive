import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'catalog/all_users_books_reqst_Catalog_management.dart';
import 'books/books_and_club_management.dart';
import 'users/user_management.dart';
import '../../components/admin_sidebar.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
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
  bool _isSidebarOpen = false;

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _handleSidebarTap(String label) {
    if (label == 'Log Out') {
      // TODO: Implement logout logic
    } else if (label == 'Catalog') {
      Navigator.of(context).push(_createRoute(const AllUsersBookRequestCatalogManagementPage()));
      _toggleSidebar();
    } else if (label == 'Books') {
      Navigator.of(context).push(_createRoute(const BooksAndClubManagementPage()));
      _toggleSidebar();
    } else if (label == 'Users') {
      Navigator.of(context).push(_createRoute(const UserManagementPage()));
      _toggleSidebar();
    } else {
      _toggleSidebar();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: isMobile ? _buildMobileContent() : _buildDesktopContent(),
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
              isDashboard: true,
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
          
          // Empty space to balance the layout
          const SizedBox(width: 44),
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
          
          // Empty space to balance the layout (same width as hamburger button)
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildMobileContent() {
    return SingleChildScrollView(
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
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              color: const Color(0xFF0096C7),
                              value: 70,
                              title: '',
                              radius: 60,
                            ),
                            PieChartSectionData(
                              color: const Color(0xFF2D3748),
                              value: 30,
                              title: '',
                              radius: 60,
                            ),
                          ],
                          sectionsSpace: 0,
                          centerSpaceRadius: 0,
                          borderData: FlBorderData(show: false),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    _buildLegendItem(
                      color: const Color(0xFF0096C7),
                      label: 'Total Readable Books',
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      color: const Color(0xFF2D3748),
                      label: 'Most Readable Books',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Stats Cards Section

          Column(
            children: [
              // First row - User Base and Book Count side by side
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.person,
                      value: '0150',
                      label: 'Total User Base',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.menu_book,
                      value: '01500',
                      label: 'Total Book Count',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Second row - Book Borrow Requests full width
              _buildStatCard(
                icon: Icons.menu_book,
                value: '067',
                label: 'Total Book Borrow Requests',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Info Cards Section
          Column(
            children: [
              _buildInfoCard(
                title: 'User Details',
                items: List.generate(4, (index) => _buildUserDetailItem()),
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Book Readers Update',
                items: List.generate(5, (index) => _buildBookReaderItem()),
              ),
            ],
          ),
        ],
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
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                color: const Color(0xFF0096C7),
                                value: 70,
                                title: '',
                                radius: 80,
                              ),
                              PieChartSectionData(
                                color: const Color(0xFF2D3748),
                                value: 30,
                                title: '',
                                radius: 80,
                              ),
                            ],
                            sectionsSpace: 0,
                            centerSpaceRadius: 0,
                            borderData: FlBorderData(show: false),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _buildLegendItem(
                        color: const Color(0xFF0096C7),
                        label: 'Total Readable Books',
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        color: const Color(0xFF2D3748),
                        label: 'Most Readable Books',
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
                        icon: Icons.person,
                        value: '0150',
                        label: 'Total User Base',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.menu_book,
                        value: '01500',
                        label: 'Total Book Count',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.menu_book,
                        value: '067',
                        label: 'Total Book Borrow Requests',
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
                          title: 'User Details',
                          items: List.generate(4, (index) => _buildUserDetailItem()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          title: 'Book Readers Update',
                          items: List.generate(5, (index) => _buildBookReaderItem()),
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
        color: const Color(0xFFE3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isMobile ? Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
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
              color: Colors.white,
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
    required List<Widget> items,
  }) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      height: isMobile ? null : 400,
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
          isMobile ? Column(
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: item,
            )).toList(),
          ) : Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) => items[index],
            ),
          ),
          if (isMobile) const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUserDetailItem() {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
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
                  'Nisal Gunasekara',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 12 : 14,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                Text(
                  'User ID: 1',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 10 : 12,
                    color: const Color(0xFF4A5568),
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
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Active',
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
              Icons.sync,
              color: const Color(0xFF0096C7),
              size: isMobile ? 12 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookReaderItem() {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
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
                  'Sasmith Gunasekara',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 12 : 14,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                Text(
                  'Book ID: 10',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 10 : 12,
                    color: const Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ),
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


}