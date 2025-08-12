import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main_home_page/main_page.dart'; // Fixed path


class UserDashboardPage extends StatelessWidget {
  const UserDashboardPage({
    Key? key,
    required this.onMyBooksTap,
    required this.onEditProfileTap,
    this.userData,
  }) : super(key: key);

  final VoidCallback onMyBooksTap;
  final VoidCallback onEditProfileTap;
  final Map<String, dynamic>? userData;

  @override
  Widget build(BuildContext context) {
    // Use dynamic data if available, otherwise fallback to static
    final user = {
      'name': userData?['firstName'] ?? userData?['name'] ?? 'Arif Abdullah',
      'id': userData?['email']?.split('@')[0] ?? 'BS 1754',
      'books': userData?['booksRead'] ?? 100,
      'friends': userData?['friends'] ?? 1245,
      'following': userData?['following'] ?? 8,
      'joined': userData?['createdAt'] != null
          ? _formatDate(userData!['createdAt'])
          : 'Month DD YEAR',
      'genres': userData?['favoriteGenres'] ?? 'Romance, Mystery/Thriller, Fantasy, Science Fiction, +5 More',
      'photoURL': userData?['photoURL'],
    };
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B4D8),
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF00B4D8)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                user['name'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
          ],
        ),
        actions: [  // Add this actions section
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card at the top
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 500;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                      minWidth: 0,
                    ),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 6,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: isNarrow
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 56,
                                    backgroundColor: Colors.white,
                                    backgroundImage: user['photoURL'] != null && user['photoURL'].isNotEmpty
                                        ? NetworkImage(user['photoURL'])
                                        : const AssetImage('Asset/images/arif.jpg') as ImageProvider,
                                  ),
                                  const SizedBox(height: 18),
                                  _ProfileDetails(
                                    user: user,
                                    onEditProfileTap: onEditProfileTap,
                                    isNarrow: true,
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 56,
                                    backgroundColor: Colors.white,
                                    backgroundImage: user['photoURL'] != null && user['photoURL'].isNotEmpty
                                        ? NetworkImage(user['photoURL'])
                                        : const AssetImage('Asset/images/arif.jpg') as ImageProvider,
                                  ),
                                  const SizedBox(width: 36),
                                  Expanded(
                                    child: _ProfileDetails(
                                      user: user,
                                      onEditProfileTap: onEditProfileTap,
                                      isNarrow: false,
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
            const SizedBox(height: 24),
            // My Books button left-aligned
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ElevatedButton.icon(
                onPressed: onMyBooksTap,
                icon: const Icon(Icons.menu_book),
                label: const Text('My Books'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _statBox(String value, String label, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Color(0xFF4a4e69), size: 22),
            const SizedBox(height: 2),
          ],
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF22223b),
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF4a4e69), fontSize: 13),
          ),
        ],
      ),
    );
  }

  static String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Month DD YEAR';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${_getMonthName(date.month)} ${date.day} ${date.year}';
      }
      return 'Month DD YEAR';
    } catch (e) {
      return 'Month DD YEAR';
    }
  }

  static String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  static void _showLogoutDialog(BuildContext context) {
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
              onPressed: () => _performLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  static void _performLogout(BuildContext context) async {
    try {
      // Show loading dialog
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

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate to main page and clear all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainPage()),
        (Route<dynamic> route) => false,
      );

    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ProfileDetails extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEditProfileTap;
  final bool isNarrow;
  const _ProfileDetails({
    required this.user,
    required this.onEditProfileTap,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isNarrow
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: isNarrow
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Color(0xFF22223b),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['id'] as String,
                    style: const TextStyle(
                      color: Color(0xFF4a4e69),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            if (!isNarrow) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onEditProfileTap,
                icon: const Icon(Icons.edit, size: 20),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFf2e9e4),
                  foregroundColor: Color(0xFF22223b),
                  side: const BorderSide(color: Color(0xFF4a4e69)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
        if (isNarrow) ...[
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: onEditProfileTap,
            icon: const Icon(Icons.edit, size: 20),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFf2e9e4),
              foregroundColor: Color(0xFF22223b),
              side: const BorderSide(color: Color(0xFF4a4e69)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              elevation: 0,
            ),
          ),
        ],
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: isNarrow
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              UserDashboardPage._statBox(
                '${user['books']}',
                'Books',
                icon: Icons.menu_book,
              ),
              UserDashboardPage._statBox(
                '${user['friends']}',
                'Friends',
                icon: Icons.people,
              ),
              UserDashboardPage._statBox(
                '${user['following']}',
                'Following',
                icon: Icons.person_add_alt_1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Joined in ${user['joined'] as String}',
          style: const TextStyle(color: Color(0xFF4a4e69), fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          'Favorite GENRES',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF22223b),
          ),
        ),
        Text(
          user['genres'] as String,
          style: const TextStyle(color: Color(0xFF4a4e69), fontSize: 15),
        ),
      ],
    );
  }
}
