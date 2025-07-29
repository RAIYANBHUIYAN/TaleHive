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
          ? SafeArea(
              child: _MobileAdminDashboard(
                primaryColor: primaryColor,
                accentColor: accentColor,
                backgroundColor: backgroundColor,
                cardColor: cardColor,
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
                                                  radius: 100,
                                                ),
                                                PieChartSectionData(
                                                  color: Colors.black,
                                                  value: 30,
                                                  title: '',
                                                  radius: 100,
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
                                            children: [
                                              _UserDetailCard(name: 'Arif', imagePath: 'Asset/images/arif.jpg', userId: '1', userType: 'Author'),
                                              _UserDetailCard(name: 'Lt Nahid', imagePath: 'Asset/images/nahid.jpg', userId: '2', userType: 'Reader'),
                                              _UserDetailCard(name: 'Lt Pervez', imagePath: 'Asset/images/parvez.jpg', userId: '3', userType: 'Member'),
                                            ],
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
    // Only use Expanded if parent is a Row (desktop), otherwise just return the Card
    final isInRow = (context.findAncestorWidgetOfExactType<Row>() != null);
    final card = Card(
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
    );
    return isInRow ? Expanded(child: card) : card;
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
  final String name;
  final String imagePath;
  final String userId;
  final String userType;
  final VoidCallback? onRemove;
  const _UserDetailCard({
    required this.name,
    required this.imagePath,
    required this.userId,
    required this.userType,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage(imagePath),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: $userId'),
            Text('Type: $userType'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: onRemove,
            ),
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

class _MobileAdminDashboard extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color cardColor;
  const _MobileAdminDashboard({
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.cardColor,
  });

  @override
  State<_MobileAdminDashboard> createState() => _MobileAdminDashboardState();
}

class _MobileAdminDashboardState extends State<_MobileAdminDashboard> {
  List<Map<String, String>> users = [
    {
      'name': 'Arif',
      'imagePath': 'Asset/images/arif.jpg',
      'userId': '1',
      'userType': 'Author',
    },
    {
      'name': 'Lt Nahid',
      'imagePath': 'Asset/images/nahid.jpg',
      'userId': '2',
      'userType': 'Reader',
    },
    {
      'name': 'Lt Pervez',
      'imagePath': 'Asset/images/parvez.jpg',
      'userId': '3',
      'userType': 'Member',
    },
  ];

  void removeUser(int index) {
    setState(() {
      users.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor;
    final accentColor = widget.accentColor;
    final backgroundColor = widget.backgroundColor;
    final cardColor = widget.cardColor;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                      // Header
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: accentColor,
                            backgroundImage: AssetImage('Asset/images/loren.jpg'),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Raiyan',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Admin',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.settings, color: primaryColor),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Pie Chart (Full width on mobile)
                      Center(
                        child: Card(
                          color: cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 48,
                              height: MediaQuery.of(context).size.width - 48,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      color: primaryColor,
                                      value: 70,
                                      title: '',
                                      radius: 100,
                                    ),
                                    PieChartSectionData(
                                      color: Colors.black,
                                      value: 30,
                                      title: '',
                                      radius: 100,
                                    ),
                                  ],
                                  sectionsSpace: 0,
                                  centerSpaceRadius: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendDot(color: primaryColor),
                          SizedBox(width: 8),
                          Text('Total Readed Books'),
                          SizedBox(width: 24),
                          _LegendDot(color: Colors.black),
                          SizedBox(width: 8),
                          Text('Most Readaed Books'),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Stat Cards (Stacked vertically, no Expanded)
                      _StatCard(icon: Icons.person, label: 'Total User Base', value: '0150'),
                      SizedBox(height: 8),
                      _StatCard(icon: Icons.menu_book, label: 'Total Book Count', value: '01500'),
                      SizedBox(height: 8),
                      _StatCard(icon: Icons.menu_book, label: 'Total Book Borrow Requests', value: '067'),
                      SizedBox(height: 16),
                      // Info Cards (Stacked vertically)
                      _InfoCard(
                        title: 'User Details',
                        children: [
                          for (int i = 0; i < users.length; i++)
                            _UserDetailCard(
                              name: users[i]['name']!,
                              imagePath: users[i]['imagePath']!,
                              userId: users[i]['userId']!,
                              userType: users[i]['userType']!,
                              onRemove: () async {
                                final shouldRemove = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('User Removed'),
                                    content: Text('User ${users[i]['name']} with ID ${users[i]['userId']} is being removed.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: Text('OK'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: Text('Cancel'),
                                      ),
                                    ],
                                  ),
                                );
                                if (shouldRemove == true) {
                                  removeUser(i);
                                }
                              },
                            ),
                        ],
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
              ),
            ),
    );
  }
} 