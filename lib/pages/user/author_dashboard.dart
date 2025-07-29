import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AuthorDashboardPage extends StatefulWidget {
  const AuthorDashboardPage({Key? key}) : super(key: key);

  @override
  State<AuthorDashboardPage> createState() => _AuthorDashboardPageState();
}

class _AuthorDashboardPageState extends State<AuthorDashboardPage> {
  final author = {
    'name': 'Md Raiyan Buhiyan',
    'bio':
        'Award-winning author of modern fiction. Passionate about storytelling and inspiring readers.',
    'avatar': 'Asset/images/loren.jpg',
    'email': 'loreen@email.com',
  };

  final stats = {
    'books': 12,
    'transactions': 340,
    'followers': 1200,
    'ratings': 4.7,
  };

  final List<Map<String, dynamic>> books = [
    {
      'title': 'The Last Dawn',
      'cover': 'https://covers.openlibrary.org/b/id/10523338-L.jpg',
      'year': 2022,
      'status': 'Published',
    },
    {
      'title': 'Whispers of Time',
      'cover': 'https://covers.openlibrary.org/b/id/10523339-L.jpg',
      'year': 2021,
      'status': 'Published',
    },
    {
      'title': 'Echoes in the Wind',
      'cover': 'https://covers.openlibrary.org/b/id/10523340-L.jpg',
      'year': 2020,
      'status': 'Draft',
    },
  ];

  String search = '';
  String transactionRange = 'Yearly';

  // Sample data for charts
  final List<int> booksPublishedYearly = [2, 3, 1, 4, 2];
  final List<String> years = ['2019', '2020', '2021', '2022', '2023'];
  final List<int> transactionsMonthly = [
    20,
    35,
    50,
    40,
    60,
    80,
    70,
    90,
    100,
    110,
    95,
    120,
  ];
  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredBooks = books
        .where((b) => b['title'].toLowerCase().contains(search.toLowerCase()))
        .toList();
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        title: const Text(
          'Author Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () => _showEditProfileDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage(author['avatar']!),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            author['bio']!,
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.email,
                                size: 16,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  author['email']!,
                                  style: const TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isMobile)
                      ElevatedButton.icon(
                        onPressed: () => _showEditProfileDialog(context),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6C63FF),
                          side: const BorderSide(color: Color(0xFF6C63FF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Publish Book Button
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _showPublishBookDialog,
                icon: const Icon(Icons.add_box_rounded),
                label: const Text('Publish Book'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Analytics Section
            Text(
              'Analytics Overview',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            // Books Published Bar Chart
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Books Published (Yearly)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                          ),
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 6,
                          barTouchData: BarTouchData(enabled: true),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(
                            booksPublishedYearly.length,
                            (i) => BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: booksPublishedYearly[i].toDouble(),
                                  color: const Color(0xFF6C63FF),
                                  width: 22,
                                  borderRadius: BorderRadius.circular(6),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: 6,
                                    color: Color(0xFFE0EAFc),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Transactions Line Chart
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transactions Trend',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        DropdownButton<String>(
                          value: transactionRange,
                          items: const [
                            DropdownMenuItem(
                              value: 'Yearly',
                              child: Text('Yearly'),
                            ),
                            DropdownMenuItem(
                              value: 'Monthly',
                              child: Text('Monthly'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => transactionRange = val!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minY: 0,
                          maxY: transactionRange == 'Monthly' ? 140 : 400,
                          lineBarsData: [
                            LineChartBarData(
                              spots: transactionRange == 'Monthly'
                                  ? List.generate(
                                      transactionsMonthly.length,
                                      (i) => FlSpot(
                                        i.toDouble(),
                                        transactionsMonthly[i].toDouble(),
                                      ),
                                    )
                                  : List.generate(
                                      years.length,
                                      (i) => FlSpot(i.toDouble(), (i + 1) * 60),
                                    ),
                              isCurved: true,
                              color: const Color(0xFF6C63FF),
                              barWidth: 4,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Color(0xFF6C63FF).withOpacity(0.12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Performance Summary Donut Chart
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              color: Colors.deepPurple,
                              value: (stats['books'] ?? 0).toDouble(),
                              title: 'Books',
                              radius: 38,
                              titleStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              badgeWidget: const Icon(
                                Icons.menu_book,
                                color: Colors.white,
                                size: 18,
                              ),
                              badgePositionPercentageOffset: .98,
                            ),
                            PieChartSectionData(
                              color: Colors.teal,
                              value: (stats['transactions'] ?? 0).toDouble(),
                              title: 'Trans',
                              radius: 36,
                              titleStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              badgeWidget: const Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: 18,
                              ),
                              badgePositionPercentageOffset: .98,
                            ),
                            PieChartSectionData(
                              color: Colors.orange,
                              value: (stats['followers'] ?? 0).toDouble(),
                              title: 'Followers',
                              radius: 34,
                              titleStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              badgeWidget: const Icon(
                                Icons.people,
                                color: Colors.white,
                                size: 18,
                              ),
                              badgePositionPercentageOffset: .98,
                            ),
                            PieChartSectionData(
                              color: Colors.amber,
                              value: ((stats['ratings'] ?? 0) * 100).toDouble(),
                              title: 'Ratings',
                              radius: 32,
                              titleStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              badgeWidget: const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 18,
                              ),
                              badgePositionPercentageOffset: .98,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Published Books List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Published Books',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(
                  width: isMobile ? 140 : 220,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search books...',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => search = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredBooks.length,
                separatorBuilder: (context, i) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final book = filteredBooks[i];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        book['cover'],
                        width: 48,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      book['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Year: ${book['year']}  |  Status: ${book['status']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit Book',
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.grey),
                          tooltip: 'Manage Book',
                          onPressed: () {},
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
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: author['name']);
        final bioController = TextEditingController(text: author['bio']);
        final emailController = TextEditingController(text: author['email']);
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  author['name'] = nameController.text;
                  author['bio'] = bioController.text;
                  author['email'] = emailController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showPublishBookDialog() {
    final titleController = TextEditingController();
    final yearController = TextEditingController();
    final statusController = TextEditingController();
    final coverController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Publish New Book'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: yearController,
                  decoration: const InputDecoration(labelText: 'Year'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: statusController,
                  decoration: const InputDecoration(
                    labelText: 'Status (Published/Draft)',
                  ),
                ),
                TextField(
                  controller: coverController,
                  decoration: const InputDecoration(
                    labelText: 'Cover Image URL',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  books.add({
                    'title': titleController.text,
                    'year':
                        int.tryParse(yearController.text) ??
                        DateTime.now().year,
                    'status': statusController.text,
                    'cover': coverController.text.isNotEmpty
                        ? coverController.text
                        : 'https://covers.openlibrary.org/b/id/10523338-L.jpg',
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Publish'),
            ),
          ],
        );
      },
    );
  }
}
