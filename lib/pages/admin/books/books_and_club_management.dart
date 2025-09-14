import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../components/admin_sidebar.dart';
import '../catalog/all_users_books_reqst_Catalog_management.dart';
import '../users/user_management.dart';
import '../../main_home_page/main_page.dart';
import '../../../services/notification_service.dart';

class BooksAndClubManagementPage extends StatefulWidget {
  const BooksAndClubManagementPage({Key? key}) : super(key: key);

  @override
  State<BooksAndClubManagementPage> createState() =>
      _BooksAndClubManagementPageState();
}

class _BooksAndClubManagementPageState extends State<BooksAndClubManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _bookSearchController = TextEditingController();
  final supabase = Supabase.instance.client;
  
  // Sidebar state
  bool _isSidebarOpen = false;
  bool _isLoading = false;
  
  // Club requests data
  List<Map<String, dynamic>> _clubRequests = [];
  List<Map<String, dynamic>> _filteredClubRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Only Club Management
    _loadClubRequests();
    
    // Add search listener
    _searchController.addListener(_filterClubs);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _bookSearchController.dispose();
    super.dispose();
  }

  // Filter clubs based on search
  void _filterClubs() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredClubRequests = List.from(_clubRequests);
      });
    } else {
      setState(() {
        _filteredClubRequests = _clubRequests.where((club) {
          final clubName = (club['name'] ?? '').toLowerCase();
          final description = (club['description'] ?? '').toLowerCase();
          final status = (club['approval_status'] ?? '').toLowerCase();
          final author = club['authors'] as Map<String, dynamic>?;
          final authorName = '${author?['first_name'] ?? ''} ${author?['last_name'] ?? ''}'.toLowerCase();
          
          return clubName.contains(query) || 
                 description.contains(query) || 
                 status.contains(query) ||
                 authorName.contains(query);
        }).toList();
      });
    }
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
      // Already on Books page, just close sidebar
    } else if (label == 'Catalog') {
      _toggleSidebar();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(_createRoute(const AllUsersBookRequestCatalogManagementPage()));
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
      barrierDismissible: false, // Prevent dismissing by tapping outside
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
                    'Premium Club Management',
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
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search premium clubs, authors, or status...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0096C7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get detailed membership statistics for a club
  Future<Map<String, int>> _getClubMembershipStats(String clubId) async {
    try {
      // Get all memberships for this club
      final allMemberships = await supabase
          .from('club_memberships')
          .select('status, membership_type')
          .eq('club_id', clubId);
      
      final stats = <String, int>{
        'total': allMemberships.length,
        'active': 0,
        'pending': 0,
        'expired': 0,
        'cancelled': 0,
        'free_members': 0,
        'premium_members': 0,
      };
      
      for (var membership in allMemberships) {
        final status = membership['status'] ?? 'pending';
        final type = membership['membership_type'] ?? 'free';
        
        // Count by status
        stats[status] = (stats[status] ?? 0) + 1;
        
        // Count by membership type
        if (type == 'free') {
          stats['free_members'] = stats['free_members']! + 1;
        } else {
          stats['premium_members'] = stats['premium_members']! + 1;
        }
      }
      
      return stats;
    } catch (e) {
      debugPrint('Error getting membership stats for club $clubId: $e');
      return {
        'total': 0,
        'active': 0,
        'pending': 0,
        'expired': 0,
        'cancelled': 0,
        'free_members': 0,
        'premium_members': 0,
      };
    }
  }

  // Load club requests from database (only premium clubs that need approval)
  Future<void> _loadClubRequests() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await supabase
          .from('clubs')
          .select('''
            id,
            name,
            description,
            cover_image_url,
            author_id,
            membership_price,
            member_count,
            is_premium,
            approval_status,
            created_at,
            authors(first_name, last_name, email, photo_url)
          ''')
          .eq('is_premium', true) // Only load premium clubs
          .order('created_at', ascending: false);
      
      debugPrint('Raw club requests response: $response');
      debugPrint('Response length: ${response.length}');
      
      // Get actual member counts from club_memberships table
      for (var club in response) {
        try {
          final memberCountResponse = await supabase
              .from('club_memberships')
              .select('id')
              .eq('club_id', club['id'])
              .eq('status', 'active'); // Only count active members
          
          final actualMemberCount = memberCountResponse.length;
          club['actual_member_count'] = actualMemberCount;
          
          debugPrint('Club ${club['name']}: DB count = ${club['member_count']}, Actual count = $actualMemberCount');
        } catch (e) {
          debugPrint('Error getting member count for club ${club['id']}: $e');
          club['actual_member_count'] = club['member_count'] ?? 0; // Fallback to DB count
        }
      }
      
      if (mounted) {
        setState(() {
          _clubRequests = List<Map<String, dynamic>>.from(response);
          _filteredClubRequests = List.from(_clubRequests);
        });
      }
    } catch (e) {
      debugPrint('Error loading club requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading clubs: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Approve club request
  Future<void> _approveClubRequest(Map<String, dynamic> club, [BuildContext? dialogContext]) async {
    debugPrint('🟢 Starting approval process for club: ${club['id']}');
    
    if (_isLoading) {
      debugPrint('🟡 Already loading, skipping approval');
      return;
    }
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      debugPrint('🟢 Updating database status to approved');
      await supabase
          .from('clubs')
          .update({'approval_status': 'approved'})
          .eq('id', club['id']);
      
      debugPrint('🟢 Database updated successfully');
      
      // Try to create notification
      try {
        await NotificationService.createNotification(
          userId: club['author_id'],
          type: 'club_approved',
          title: 'Club Approved',
          body: 'Your club "${club['name']}" has been approved by admin!',
          data: {
            'club_id': club['id'],
            'club_name': club['name'],
          },
        );
        debugPrint('🔔 Notification created successfully');
      } catch (notificationError) {
        debugPrint('🟡 Failed to create notification (non-critical): $notificationError');
      }
      
      // Close dialog if present
      if (dialogContext != null && Navigator.canPop(dialogContext)) {
        Navigator.of(dialogContext).pop();
      }
      
      // Refresh data
      await _loadClubRequests();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Club approved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e) {
      debugPrint('🔴 Error in approval: $e');
      if (dialogContext != null && Navigator.canPop(dialogContext)) {
        Navigator.of(dialogContext).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to approve club: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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

  // Reject club request
  Future<void> _rejectClubRequest(Map<String, dynamic> club, [BuildContext? dialogContext]) async {
    if (_isLoading || !mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      await supabase
          .from('clubs')
          .update({'approval_status': 'rejected'})
          .eq('id', club['id']);
      
      // Try to create notification
      try {
        await NotificationService.createNotification(
          userId: club['author_id'],
          type: 'club_rejected',
          title: 'Club Rejected',
          body: 'Your club "${club['name']}" has been rejected by admin.',
          data: {
            'club_id': club['id'],
            'club_name': club['name'],
          },
        );
      } catch (notificationError) {
        debugPrint('🟡 Failed to create notification (non-critical): $notificationError');
      }
      
      // Close dialog if present
      if (dialogContext != null && Navigator.canPop(dialogContext)) {
        Navigator.of(dialogContext).pop();
      }
      
      // Refresh data
      await _loadClubRequests();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Club rejected successfully!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e) {
      debugPrint('Error in rejection: $e');
      if (dialogContext != null && Navigator.canPop(dialogContext)) {
        Navigator.of(dialogContext).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to reject club: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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

  // Delete club permanently from database
  Future<void> _deleteClubPermanently(Map<String, dynamic> club, [BuildContext? dialogContext]) async {
    debugPrint('🗑️ Starting permanent deletion for club: ${club['id']}');
    
    if (_isLoading || !mounted) return;
    
    // Show confirmation dialog first
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Club Permanently',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete this club?',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Club: ${club['name']}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This action cannot be undone!',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Delete Permanently',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
    
    if (shouldDelete != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      debugPrint('🗑️ Deleting club from database: ${club['id']}');
      
      // Delete the club permanently from database
      await supabase
          .from('clubs')
          .delete()
          .eq('id', club['id']);
      
      debugPrint('🗑️ Club deleted successfully from database');
      
      // Try to create notification for the author
      try {
        await NotificationService.createNotification(
          userId: club['author_id'],
          type: 'club_deleted',
          title: 'Club Deleted',
          body: 'Your club "${club['name']}" has been permanently deleted by admin.',
          data: {
            'club_id': club['id'],
            'club_name': club['name'],
          },
        );
        debugPrint('🔔 Deletion notification sent successfully');
      } catch (notificationError) {
        debugPrint('🟡 Failed to create notification (non-critical): $notificationError');
      }
      
      // Close any open dialogs
      if (dialogContext != null && Navigator.canPop(dialogContext)) {
        Navigator.of(dialogContext).pop();
      }
      
      // Refresh data
      await _loadClubRequests();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ Club "${club['name']}" deleted permanently!'),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e) {
      debugPrint('🔴 Error deleting club: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to delete club: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

  // Show club details dialog
  void _showClubDetailsDialog(Map<String, dynamic> club) {
    final author = club['authors'] as Map<String, dynamic>?;
    DateTime? createdAt;
    
    try {
      createdAt = DateTime.parse(club['created_at']);
    } catch (e) {
      debugPrint('Error parsing date: $e');
      createdAt = DateTime.now(); // fallback
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.groups,
                color: Color(0xFF0096C7),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Club Details',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Club Image
                    if (club['cover_image_url'] != null && club['cover_image_url'].toString().isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            club['cover_image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.groups, size: 50, color: Colors.grey[400]),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            },
                          ),
                        ),
                      ),
                    if (club['cover_image_url'] != null) const SizedBox(height: 16),
                    
                    // Club Details
                    _buildDetailRow('Club Name:', club['name'] ?? 'Unknown'),
                    _buildDetailRow('Description:', club['description'] ?? 'No description'),
                    _buildDetailRow('Type:', club['is_premium'] == true ? 'Premium' : 'Free'),
                    if (club['is_premium'] == true)
                      _buildDetailRow('Price:', '৳${(club['membership_price'] ?? 0).toStringAsFixed(2)}/month'),
                    _buildDetailRow('Members:', '${club['actual_member_count'] ?? club['member_count'] ?? 0}'),
                    _buildDetailRow('Status:', club['approval_status'] ?? 'pending'),
                    _buildDetailRow('Created:', createdAt != null ? DateFormat('dd-MM-yyyy HH:mm').format(createdAt) : 'Unknown'),
                    
                    // Membership Statistics Section
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.blue[600], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Membership Statistics',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    FutureBuilder<Map<String, int>>(
                      future: _getClubMembershipStats(club['id']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        
                        if (snapshot.hasError || !snapshot.hasData) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Unable to load membership statistics',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }
                        
                        final stats = snapshot.data!;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatRow('Active:', '${stats['active']}', Colors.green),
                                  ),
                                  Expanded(
                                    child: _buildStatRow('Pending:', '${stats['pending']}', Colors.orange),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatRow('Expired:', '${stats['expired']}', Colors.red),
                                  ),
                                  Expanded(
                                    child: _buildStatRow('Cancelled:', '${stats['cancelled']}', Colors.grey),
                                  ),
                                ],
                              ),
                              if (stats['free_members']! > 0 || stats['premium_members']! > 0) ...[
                                const SizedBox(height: 8),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatRow('Free:', '${stats['free_members']}', Colors.blue),
                                    ),
                                    Expanded(
                                      child: _buildStatRow('Premium:', '${stats['premium_members']}', Colors.purple),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Author Details
                    Text(
                      'Author Information',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: author?['photo_url'] != null && author!['photo_url'].toString().isNotEmpty
                              ? NetworkImage(author['photo_url'])
                              : null,
                          backgroundColor: Colors.grey[300],
                          child: author?['photo_url'] == null || author!['photo_url'].toString().isEmpty
                              ? Icon(Icons.person, color: Colors.grey[600])
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${author?['first_name'] ?? ''} ${author?['last_name'] ?? ''}'.trim(),
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                author?['email'] ?? 'No email',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
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
            ),
          ),
          actions: [
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Delete button (always available for admin)
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _deleteClubPermanently(club, dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete_forever, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Delete',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (club['approval_status'] == 'pending') ...[
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _rejectClubRequest(club, dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _approveClubRequest(club, dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Approve',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
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
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Build clubs table
  Widget _buildClubsTable() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(24),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading clubs...'),
            ],
          ),
        ),
      );
    }

    if (_filteredClubRequests.isEmpty && _searchController.text.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No clubs found',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search terms.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_clubRequests.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.groups, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No premium clubs found',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Premium clubs will appear here when authors create them.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClubRequests,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0096C7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Premium Club Requests (${_filteredClubRequests.length})',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Club items
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredClubRequests.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final club = _filteredClubRequests[index];
                  final author = club['authors'] as Map<String, dynamic>?;
                  DateTime createdAt;
                  
                  try {
                    createdAt = DateTime.parse(club['created_at']);
                  } catch (e) {
                    createdAt = DateTime.now(); // fallback
                  }
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with image, basic info and status
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Club Image
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                              ),
                              child: club['cover_image_url'] != null && club['cover_image_url'].toString().isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        club['cover_image_url'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(Icons.groups, color: Colors.grey[400]);
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(Icons.groups, color: Colors.grey[400]),
                            ),
                            const SizedBox(width: 12),
                            
                            // Club basic info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Club name and status in separate rows for mobile
                                  Text(
                                    club['name'] ?? 'Unknown Club',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(club['approval_status'] ?? 'pending'),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      (club['approval_status'] ?? 'pending').toUpperCase(),
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // View details button
                            IconButton(
                              onPressed: () => _showClubDetailsDialog(club),
                              icon: const Icon(Icons.visibility, color: Color(0xFF0096C7)),
                              tooltip: 'View Details',
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Description
                        Text(
                          club['description'] ?? 'No description',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Club type and pricing in a flexible row
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (club['is_premium'] == true) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Premium',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '৳${(club['membership_price'] ?? 0).toStringAsFixed(2)}/month',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Free',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${club['actual_member_count'] ?? club['member_count'] ?? 0} members',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Author info and actions row
                        Row(
                          children: [
                            // Author info
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: author?['photo_url'] != null && author!['photo_url'].toString().isNotEmpty
                                  ? NetworkImage(author['photo_url'])
                                  : null,
                              backgroundColor: Colors.grey[300],
                              child: author?['photo_url'] == null || author!['photo_url'].toString().isEmpty
                                  ? Icon(Icons.person, size: 12, color: Colors.grey[600])
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${author?['first_name'] ?? ''} ${author?['last_name'] ?? ''}'.trim(),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DateFormat('dd-MM-yyyy').format(createdAt),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Action buttons for pending clubs
                            if (club['approval_status'] == 'pending') ...[
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      onPressed: _isLoading ? null : () => _rejectClubRequest(club),
                                      icon: Icon(Icons.close, color: Colors.red[600], size: 18),
                                      tooltip: 'Reject',
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      onPressed: _isLoading ? null : () => _approveClubRequest(club),
                                      icon: Icon(Icons.check, color: Colors.green[600], size: 18),
                                      tooltip: 'Approve',
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            // Delete button (always available for admin)
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: _isLoading ? null : () => _deleteClubPermanently(club),
                                icon: Icon(Icons.delete_forever, color: Colors.red[700], size: 18),
                                tooltip: 'Delete Permanently',
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        body: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildClubsTable(),
                ),
              ],
            ),
            // Sidebar
            if (_isSidebarOpen)
              GestureDetector(
                onTap: _toggleSidebar,
                child: Container(
                  color: Colors.black54,
                  child: Row(
                    children: [
                      Container(
                        width: 280,
                        height: double.infinity,
                        color: Colors.white,
                        child: AdminSidebar(
                          onItemTap: _handleSidebarTap,
                          activePage: 'Books', // Mark Books as the current active page
                        ),
                      ),
                      const Expanded(
                        child: SizedBox(), // Transparent area to close sidebar
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