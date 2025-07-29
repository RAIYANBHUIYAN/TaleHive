import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AllUsersBookRequestCatalogManagementPage extends StatefulWidget {
  const AllUsersBookRequestCatalogManagementPage({Key? key}) : super(key: key);

  @override
  State<AllUsersBookRequestCatalogManagementPage> createState() => _AllUsersBookRequestCatalogManagementPageState();
}

class _AllUsersBookRequestCatalogManagementPageState extends State<AllUsersBookRequestCatalogManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Filter state
  String _selectedCategory = 'All';
  List<String> _categories = ['All', 'Programming', 'AI/ML', 'Technical', 'Design', 'Business', 'Science'];
  
  // Sample data for reading books requests (from the image)
  List<Map<String, dynamic>> _readingBooksRequests = [
    {
      'bookId': '001',
      'userId': '1',
      'amount': '002 Books',
      'dueDate': '13 - 03 - 2024',
      'dateTime': '25-02-2024 10:39:43',
      'reviews': '★',
      'category': 'Programming',
    },
    {
      'bookId': '002',
      'userId': '2',
      'amount': '001 Books',
      'dueDate': '15 - 03 - 2024',
      'dateTime': '26-02-2024 14:22:15',
      'reviews': '★',
      'category': 'AI/ML',
    },
    {
      'bookId': '003',
      'userId': '3',
      'amount': '003 Books',
      'dueDate': '18 - 03 - 2024',
      'dateTime': '27-02-2024 09:45:30',
      'reviews': '★',
      'category': 'Technical',
    },
    {
      'bookId': '004',
      'userId': '4',
      'amount': '002 Books',
      'dueDate': '20 - 03 - 2024',
      'dateTime': '28-02-2024 16:18:45',
      'reviews': '★',
      'category': 'Design',
    },
    {
      'bookId': '005',
      'userId': '5',
      'amount': '001 Books',
      'dueDate': '22 - 03 - 2024',
      'dateTime': '29-02-2024 11:30:20',
      'reviews': '★',
      'category': 'Business',
    },
    {
      'bookId': '006',
      'userId': '6',
      'amount': '004 Books',
      'dueDate': '25 - 03 - 2024',
      'dateTime': '01-03-2024 13:55:10',
      'reviews': '★',
      'category': 'Science',
    },
    {
      'bookId': '007',
      'userId': '1',
      'amount': '002 Books',
      'dueDate': '13 - 03 - 2024',
      'dateTime': '25-02-2024 10:39:43',
      'reviews': '★',
      'category': 'Programming',
    },
    {
      'bookId': '008',
      'userId': '2',
      'amount': '002 Books',
      'dueDate': '13 - 03 - 2024',
      'dateTime': '25-02-2024 10:39:43',
      'reviews': '★',
      'category': 'AI/ML',
    },
    {
      'bookId': '009',
      'userId': '3',
      'amount': '002 Books',
      'dueDate': '13 - 03 - 2024',
      'dateTime': '25-02-2024 10:39:43',
      'reviews': '★',
      'category': 'Technical',
    },
    {
      'bookId': '010',
      'userId': '4',
      'amount': '002 Books',
      'dueDate': '13 - 03 - 2024',
      'dateTime': '25-02-2024 10:39:43',
      'reviews': '★',
      'category': 'Design',
    },
    {
      'bookId': '011',
      'userId': '5',
      'amount': '002 Books',
      'dueDate': '13 - 03 - 2024',
      'dateTime': '25-02-2024 10:39:43',
      'reviews': '★',
      'category': 'Business',
    },
    {
      'bookId': '012',
      'userId': '6',
      'amount': '002 Books',
      'dueDate': '13 - 03 - 2024',
      'dateTime': '25-02-2024 10:39:43',
      'reviews': '★',
      'category': 'Science',
    },
  ];

  // Sample data for most readable books
  List<Map<String, dynamic>> _mostReadableBooks = [
    {
      'bookId': '101',
      'userId': '5',
      'amount': '003 Books',
      'dueDate': '20 - 03 - 2024',
      'dateTime': '28-02-2024 14:25:18',
      'reviews': '★',
      'category': 'Programming',
    },
    {
      'bookId': '102',
      'userId': '7',
      'amount': '001 Books',
      'dueDate': '18 - 03 - 2024',
      'dateTime': '26-02-2024 09:15:32',
      'reviews': '★',
      'category': 'AI/ML',
    },
    {
      'bookId': '103',
      'userId': '12',
      'amount': '002 Books',
      'dueDate': '25 - 03 - 2024',
      'dateTime': '29-02-2024 16:42:07',
      'reviews': '★',
      'category': 'Technical',
    },
    {
      'bookId': '104',
      'userId': '3',
      'amount': '004 Books',
      'dueDate': '15 - 03 - 2024',
      'dateTime': '24-02-2024 11:30:45',
      'reviews': '★',
      'category': 'Design',
    },
    {
      'bookId': '105',
      'userId': '8',
      'amount': '002 Books',
      'dueDate': '22 - 03 - 2024',
      'dateTime': '27-02-2024 13:18:29',
      'reviews': '★',
      'category': 'Business',
    },
  ];

  // Sample data for book requests
  List<Map<String, dynamic>> _bookRequests = [
    {
      'requestId': 'REQ001',
      'userId': '1',
      'userName': 'John Doe',
      'bookTitle': 'Advanced Flutter',
      'requestDate': '25-02-2024',
      'status': 'Pending',
    },
    {
      'requestId': 'REQ002',
      'userId': '2',
      'userName': 'Jane Smith',
      'bookTitle': 'React Native Guide',
      'requestDate': '24-02-2024',
      'status': 'Approved',
    },
    {
      'requestId': 'REQ003',
      'userId': '3',
      'userName': 'Mike Johnson',
      'bookTitle': 'Python for Data Science',
      'requestDate': '23-02-2024',
      'status': 'Rejected',
    },
    {
      'requestId': 'REQ004',
      'userId': '4',
      'userName': 'Emily Davis',
      'bookTitle': 'Cloud Computing',
      'requestDate': '22-02-2024',
      'status': 'Pending',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        // Trigger rebuild when search text changes
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Filter methods
  List<Map<String, dynamic>> _getFilteredReadingBooks() {
    List<Map<String, dynamic>> filteredBooks = _selectedCategory == 'All' 
        ? _readingBooksRequests 
        : _readingBooksRequests.where((book) => (book['category'] ?? 'Unknown') == _selectedCategory).toList();
    
    // Apply search filter if search text is not empty
    if (_searchController.text.isNotEmpty) {
      String searchText = _searchController.text.toLowerCase();
      filteredBooks = filteredBooks.where((book) => 
        (book['bookId'] ?? '').toString().toLowerCase().contains(searchText) ||
        (book['userId'] ?? '').toString().toLowerCase().contains(searchText) ||
        (book['category'] ?? '').toString().toLowerCase().contains(searchText)
      ).toList();
    }
    
    return filteredBooks;
  }

  List<Map<String, dynamic>> _getFilteredMostReadableBooks() {
    List<Map<String, dynamic>> filteredBooks = _selectedCategory == 'All' 
        ? _mostReadableBooks 
        : _mostReadableBooks.where((book) => (book['category'] ?? 'Unknown') == _selectedCategory).toList();
    
    // Apply search filter if search text is not empty
    if (_searchController.text.isNotEmpty) {
      String searchText = _searchController.text.toLowerCase();
      filteredBooks = filteredBooks.where((book) => 
        (book['bookId'] ?? '').toString().toLowerCase().contains(searchText) ||
        (book['userId'] ?? '').toString().toLowerCase().contains(searchText) ||
        (book['category'] ?? '').toString().toLowerCase().contains(searchText)
      ).toList();
    }
    
    return filteredBooks;
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
                labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                  hintStyle: TextStyle(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCategory == 'All' ? 'Books Category' : _selectedCategory,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _selectedCategory == 'All' ? Colors.grey[700] : const Color(0xFF0096C7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.filter_list,
                        color: _selectedCategory == 'All' ? Colors.grey[700] : const Color(0xFF0096C7),
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
          Icon(
            Icons.info_outline,
            color: const Color(0xFF0096C7),
            size: 16,
          ),
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
    return Container(
      margin: const EdgeInsets.all(24),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    child: Text(
                      'Book ID',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    child: Text(
                      'User ID',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 120,
                    child: Text(
                      'Amount',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 140,
                    child: Text(
                      'Due Date',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 180,
                    child: Text(
                      'Date & Time',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    child: Text(
                      'Reviews',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    child: Text(
                      'Category',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Table Rows
            ...List.generate(_getFilteredReadingBooks().length, (index) {
              final request = _getFilteredReadingBooks()[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0096C7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request['bookId'],
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: const Color(0xFF0096C7),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request['userId'] ?? '',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.purple[700],
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      width: 120,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request['amount'] ?? '',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      width: 140,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request['dueDate'] ?? '',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      width: 180,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request['dateTime'] ?? '',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF4A5568),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _showBookReviewsDialog(request['bookId'] ?? ''),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.star,
                                color: Colors.amber[700],
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 100,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(request['category'] ?? 'Unknown').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request['category'] ?? 'Unknown',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: _getCategoryColor(request['category'] ?? 'Unknown'),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMostReadableBooksTable() {
    return Container(
      margin: const EdgeInsets.all(24),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    child: Text(
                      'Book ID',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    child: Text(
                      'User ID',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 120,
                    child: Text(
                      'Amount',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 140,
                    child: Text(
                      'Due Date',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 180,
                    child: Text(
                      'Date & Time',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    child: Text(
                      'Reviews',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    child: Text(
                      'Category',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Table Rows
            ...List.generate(_getFilteredMostReadableBooks().length, (index) {
              final book = _getFilteredMostReadableBooks()[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0096C7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book['bookId'] ?? '',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: const Color(0xFF0096C7),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book['userId'] ?? '',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.purple[700],
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      width: 120,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book['amount'] ?? '',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      width: 140,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book['dueDate'] ?? '',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      width: 180,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book['dateTime'] ?? '',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF4A5568),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _showBookReviewsDialog(book['bookId'] ?? ''),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.star,
                                color: Colors.amber[700],
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 100,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(book['category'] ?? 'Unknown').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book['category'] ?? 'Unknown',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: _getCategoryColor(book['category'] ?? 'Unknown'),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBookRequestsTable() {
    return Container(
      margin: const EdgeInsets.all(24),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 120,
                    child: Text(
                      'Request ID',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 150,
                    child: Text(
                      'User',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 200,
                    child: Text(
                      'Book Title',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 130,
                    child: Text(
                      'Request Date',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    child: Text(
                      'Status',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    child: Text(
                      'Action',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Table Rows
            ...List.generate(_bookRequests.length, (index) {
              final request = _bookRequests[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 120,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0096C7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request['requestId'],
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: const Color(0xFF0096C7),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      width: 150,
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['userName'],
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: const Color(0xFF4A5568),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ID: ${request['userId']}',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: const Color(0xFF7C3AED),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 200,
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      child: Text(
                        request['bookTitle'],
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: const Color(0xFF4A5568),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    Container(
                      width: 130,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request['requestDate'],
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF4A5568),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(request['status']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request['status'],
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      child: InkWell(
                        onTap: () => _showRequestDetailsDialog(request),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0096C7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF0096C7),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.visibility,
                            size: 16,
                            color: Color(0xFF0096C7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
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
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[600],
                    ),
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
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                    ),
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Request Details',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Request ID:', request['requestId']),
              _buildDetailRow('User:', request['userName']),
              _buildDetailRow('Book Title:', request['bookTitle']),
              _buildDetailRow('Request Date:', request['requestDate']),
              _buildDetailRow('Status:', request['status']),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[600],
                ),
              ),
            ),
            if (request['status'] == 'Pending') ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Handle approve action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text(
                  'Approve',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Handle reject action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(
                  'Reject',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showBookReviewsDialog(String bookId) {
    // Sample reviews data for the book
    List<Map<String, dynamic>> reviews = [
      {
        'userName': 'User Name',
        'userImage': 'Asset/images/arif.jpg',
        'rating': 5,
        'date': 'Month DD, YYYY',
        'reviewText': 'Ut commodo elit adipiscing hendrerit non non elementum id ui cursus non odio vel tincidunt quam et, ac sit Nam et, malesuada non placerat Nunc orci ex, eget.\n\nIpsum ex sapien Lorem varius libero, placerat Cras nec dui Donec in ex felis, volutpat sit amet, varius tincidunt non tortor, elit. Morbi turpis venenatis dui.\n\nNullam tincidunt lorem, ipsum Donec fringilla Vestibulum sit consectetur Nam qui, hendrerit vitae turpis lorem. Quisque placerat ex. Cras massa ex ex rutli ex.',
        'likes': 54,
        'viewReacts': true,
        'viewComment': true,
      },
      {
        'userName': 'User Name',
        'userImage': 'Asset/images/loren.jpg',
        'rating': 4,
        'date': 'Month DD, YYYY',
        'reviewText': 'Ut commodo elit adipiscing hendrerit non non elementum id ui cursus non odio vel tincidunt quam et, ac sit Nam et, malesuada non placerat Nunc orci ex, eget.\n\nIpsum ex sapien Lorem varius libero, placerat Cras nec dui Donec in ex felis, volutpat sit amet, varius tincidunt non tortor, elit. Morbi turpis venenatis dui.\n\nNullam tincidunt lorem, ipsum Donec fringilla Vestibulum sit consectetur Nam qui, hendrerit vitae turpis lorem. Quisque placerat ex. Cras massa ex ex rutli ex.',
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
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
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
                                  backgroundImage: AssetImage(review['userImage']),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                            children: List.generate(5, (starIndex) {
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
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilter(),
          _buildFilterSummary(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  child: _buildReadingBooksTable(),
                ),
                SingleChildScrollView(
                  child: _buildMostReadableBooksTable(),
                ),
                SingleChildScrollView(
                  child: _buildBookRequestsTable(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
