import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFF7C6AED); // Light purple
    final Color accentColor = Color(0xFFB3A7F6); // Lighter purple
    final Color backgroundColor = Color(0xFFF8F7FC); // Very light background
    final Color cardColor = Colors.white;
    final Color sidebarColor = Color(0xFF7C6AED);
    final Color iconBgColor = Color(0xFFEDE7F6);

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: isMobile
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: accentColor,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MR. XYZ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Admin', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                        Spacer(),
                        Icon(Icons.settings, color: primaryColor),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Pie Chart (Larger on mobile)
                    Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.6,
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      color: primaryColor,
                                      value: 70,
                                      title: '',
                                    ),
                                    PieChartSectionData(
                                      color: Colors.black,
                                      value: 30,
                                      title: '',
                                    ),
                                  ],
                                  sectionsSpace: 0,
                                  centerSpaceRadius: 0,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LegendDot(color: primaryColor),
                                SizedBox(width: 8),
                                Text('Total Readable Books'),
                                SizedBox(width: 24),
                                _LegendDot(color: Colors.black),
                                SizedBox(width: 8),
                                Text('Most Readable Books'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Stat Cards (Stacked vertically)
                    _StatCard(icon: Icons.person, label: 'Total User Base', value: '0150'),
                    SizedBox(height: 8),
                    _StatCard(icon: Icons.menu_book, label: 'Total Book Count', value: '01500'),
                    SizedBox(height: 8),
                    _StatCard(icon: Icons.menu_book, label: 'Total Book Borrow Requests', value: '067'),
                    SizedBox(height: 16),
                    // Info Cards (Stacked vertically)
                    _InfoCard(
                      title: 'User Details',
                      children: List.generate(4, (i) => _UserDetailCard()),
                    ),
                    SizedBox(height: 8),
                    _InfoCard(
                      title: 'Book Readers Update',
                      children: List.generate(4, (i) => _BookReaderUpdateCard()),
                    ),
                    SizedBox(height: 8),
                    _InfoCard(
                      title: 'Most Readable Books',
                      children: List.generate(4, (i) => _MostReadableBookCard()),
                    ),
                  ],
                ),
              ),
            )
          : Row(
              children: [
                // Sidebar
                Container(
                  width: 220,
                  color: sidebarColor,
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.library_books, color: primaryColor, size: 40),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Brain Station 23',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'LIBRARY',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 40),
                      _SidebarButton(icon: Icons.dashboard, label: 'Dashboard', selected: true),
                      _SidebarButton(icon: Icons.menu_book, label: 'Catalog'),
                      _SidebarButton(icon: Icons.book, label: 'Books'),
                      _SidebarButton(icon: Icons.people, label: 'Users'),
                      Spacer(),
                      _SidebarButton(icon: Icons.logout, label: 'Log Out'),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: accentColor,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MR. XYZ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Admin', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                            Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('12:29 PM', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Sep 02, 2023', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.settings, color: primaryColor),
                          ],
                        ),
                        SizedBox(height: 24),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pie Chart
                              Expanded(
                                flex: 2,
                                child: Card(
                                  color: cardColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: PieChart(
                                            PieChartData(
                                              sections: [
                                                PieChartSectionData(
                                                  color: primaryColor,
                                                  value: 70,
                                                  title: '',
                                                ),
                                                PieChartSectionData(
                                                  color: Colors.black,
                                                  value: 30,
                                                  title: '',
                                                ),
                                              ],
                                              sectionsSpace: 0,
                                              centerSpaceRadius: 0,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _LegendDot(color: primaryColor),
                                            SizedBox(width: 8),
                                            Text('Total Readable Books'),
                                            SizedBox(width: 24),
                                            _LegendDot(color: Colors.black),
                                            SizedBox(width: 8),
                                            Text('Most Readable Books'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 24),
                              // Right Side Cards
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        _StatCard(icon: Icons.person, label: 'Total User Base', value: '0150'),
                                        SizedBox(width: 16),
                                        _StatCard(icon: Icons.menu_book, label: 'Total Book Count', value: '01500'),
                                        SizedBox(width: 16),
                                        _StatCard(icon: Icons.menu_book, label: 'Total Book Borrow Requests', value: '067'),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // User Details
                                        Expanded(
                                          child: _InfoCard(
                                            title: 'User Details',
                                            children: List.generate(4, (i) => _UserDetailCard()),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        // Book Readers Update
                                        Expanded(
                                          child: _InfoCard(
                                            title: 'Book Readers Update',
                                            children: List.generate(4, (i) => _BookReaderUpdateCard()),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        // Most Readable Books
                                        Expanded(
                                          child: _InfoCard(
                                            title: 'Most Readable Books',
                                            children: List.generate(4, (i) => _MostReadableBookCard()),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _SidebarButton({required this.icon, required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: selected
          ? BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(label, style: TextStyle(color: Colors.white)),
        onTap: () {},
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: Color(0xFFF5F3FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFEDE7F6),
                child: Icon(icon, color: Color(0xFF7C6AED)),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFFF5F3FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _UserDetailCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(Icons.person),
        title: Text('Nisal Gunasekara'),
        subtitle: Text('User ID: 1'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: Colors.green, size: 12),
            SizedBox(width: 4),
            Text('Active', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _BookReaderUpdateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(Icons.person),
        title: Text('Sasmith Gunasekara'),
        subtitle: Text('Book ID: 10'),
        trailing: Icon(Icons.sync),
      ),
    );
  }
}

class _MostReadableBookCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(Icons.menu_book),
        title: Text('Deep Learning - Matara'),
        subtitle: Text('Branch ID: 1'),
        trailing: Icon(Icons.sync),
      ),
    );
  }
} 