import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSidebar extends StatelessWidget {
  final Function(String label)? onItemTap;
  final bool isDashboard;
  const AdminSidebar({Key? key, this.onItemTap, this.isDashboard = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: const Color(0xFF0096C7),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          const SizedBox(height: 24),
          // Profile Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'Asset/images/loren.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Color(0xFF0096C7),
                          size: 30,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'System Administrator',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Online',
                            style: GoogleFonts.montserrat(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Navigation Menu
          Expanded(
            child: Column(
              children: [
                _sidebarItem(context, Icons.dashboard, 'Dashboard', isDashboard),
                _sidebarItem(context, Icons.menu_book, 'Catalog'),
                _sidebarItem(context, Icons.book, 'Books'),
                _sidebarItem(context, Icons.people, 'Users'),
              ],
            ),
          ),
          // Logout Button
          Container(
            margin: const EdgeInsets.all(24),
            child: _sidebarItem(context, Icons.logout, 'Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, IconData icon, String label, [bool isSelected = false]) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        title: Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        onTap: () => onItemTap?.call(label),
      ),
    );
  }
}
