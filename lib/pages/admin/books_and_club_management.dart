import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class BooksAndClubManagementPage extends StatefulWidget {
  const BooksAndClubManagementPage({Key? key}) : super(key: key);

  @override
  State<BooksAndClubManagementPage> createState() => _BooksAndClubManagementPageState();
}

class _BooksAndClubManagementPageState extends State<BooksAndClubManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _bookSearchController = TextEditingController();
  
  // Filter categories
  List<String> _bookCategories = [
    'Machine learning',
    'System Design',
    'Frameworks mastery',
    'Javascript Mastery',
    'UI/UX Journey',
    'Next.js easy way',
    'C, C++, Python in one',
  ];
  
  List<String> _selectedCategories = [];
  
  // Sample data for demonstration
  List<Map<String, dynamic>> _books = [
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'type': 'Technical',
      'language': 'English',
      'availability': 'Available',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'type': 'IT',
      'language': 'English',
      'availability': 'Borrowed',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'type': 'IT',
      'language': 'English',
      'availability': 'Available',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'type': 'Educational',
      'language': 'English',
      'availability': 'Available',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'type': 'Educational',
      'language': 'English',
      'availability': 'Borrowed',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'type': 'Educational',
      'language': 'English',
      'availability': 'Available',
    },
  ];

  // Sample data for book clubs
  List<Map<String, dynamic>> _bookClubs = [
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'category': 'Trainee',
      'status': 'Active',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'category': 'Trainee',
      'status': 'Active',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'category': 'Trainee',
      'status': 'Active',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'category': 'Trainee',
      'status': 'Active',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'category': 'Trainee',
      'status': 'Active',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'category': 'Trainee',
      'status': 'Active',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'category': 'Trainee',
      'status': 'Active',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'category': 'Trainee',
      'status': 'Active',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'category': 'Trainee',
      'status': 'Active',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'category': 'Trainee',
      'status': 'Active',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'category': 'Trainee',
      'status': 'Active',
    },
    {
      'id': 1,
      'name': 'Hibernate Core -11th',
      'category': 'Trainee',
      'status': 'Active',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _bookSearchController.dispose();
    super.dispose();
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
                labelPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                indicatorPadding: EdgeInsets.zero,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Book Management'),
                  Tab(text: 'Manage Book Club'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
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
                      hintText: 'Search by ID or Type',
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
                  color: const Color(0xFF0096C7),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0096C7).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _showAddBookDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add Book',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _showBookCategoryFilterDialog();
                  },
                  child: Row(
                    children: [
                      Text(
                        'Books Category',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: const Color(0xFF0096C7),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
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
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FBFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        'ID',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 180,
                      child: Text(
                        'Name',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Type',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 80,
                      child: Text(
                        'Language',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Availability',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: Text(
                        'Action',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Table Body
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final book = _books[index];
                  final isEven = index % 2 == 0;
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : const Color(0xFFFAFCFF),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${book['id']}',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 180,
                            child: Text(
                              book['name'],
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 100,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(book['type']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                book['type'],
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 80,
                            child: Text(
                              book['language'],
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 100,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: book['availability'] == 'Available'
                                    ? Colors.green[100]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                book['availability'],
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: book['availability'] == 'Available'
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: Icons.edit,
                                  color: const Color(0xFF0096C7),
                                  onTap: () {
                                    _showUpdateBookDialog(book);
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.delete,
                                  color: Colors.red,
                                  onTap: () {
                                    _showDeleteConfirmationDialog(book);
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.remove_red_eye,
                                  color: Colors.green,
                                  onTap: () {
                                    _showViewBookDialog(book);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Icon(
            icon,
            color: color,
            size: 14,
          ),
        ),
      ),
    );
  }

  void _showUpdateBookDialog(Map<String, dynamic> book) {
    final nameController = TextEditingController(text: book['name']);
    final languageController = TextEditingController(text: book['language']);
    final typeController = TextEditingController(text: book['type']);
    final quantityController = TextEditingController(text: '1'); // Default quantity

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0096C7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          color: Color(0xFF0096C7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Update Book',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0096C7),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Form content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Name field
                        _buildTextField(
                          controller: nameController,
                          label: 'Name',
                          hint: 'Enter book name',
                        ),
                        const SizedBox(height: 16),
                        // Language field
                        _buildTextField(
                          controller: languageController,
                          label: 'Language',
                          hint: 'Enter language',
                        ),
                        const SizedBox(height: 16),
                        // Type and Quantity row
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: typeController,
                                label: 'Type',
                                hint: 'Enter type',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: quantityController,
                                label: 'Quantity',
                                hint: 'Enter quantity',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogActionButton(
                                text: 'CANCEL',
                                backgroundColor: Colors.grey[300]!,
                                textColor: Colors.grey[700]!,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDialogActionButton(
                                text: 'UPDATE',
                                backgroundColor: const Color(0xFF0096C7),
                                textColor: Colors.white,
                                onPressed: () {
                                  _updateBook(
                                    book: book,
                                    name: nameController.text,
                                    language: languageController.text,
                                    type: typeController.text,
                                    quantity: quantityController.text,
                                  );
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateBook({
    required Map<String, dynamic> book,
    required String name,
    required String language,
    required String type,
    required String quantity,
  }) {
    // Update the book in the list
    setState(() {
      final index = _books.indexOf(book);
      if (index != -1) {
        _books[index] = {
          ..._books[index],
          'name': name,
          'language': language,
          'type': type,
          // Note: quantity would be stored if your data model supports it
        };
      }
    });
    
    _showSnackBar(
      'Book "$name" updated successfully!',
      isSuccess: true,
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> book) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and close button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Delete Confirmation',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Divider
                Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 24),
                // Confirmation message
                Text(
                  '"Are you certain you wish to proceed with the deletion of the selected entry?"',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deleteBook(book);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0096C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'CONFIRM',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteBook(Map<String, dynamic> book) {
    setState(() {
      _books.remove(book);
    });
    
    _showSnackBar(
      'Book "${book['name']}" deleted successfully!',
      isSuccess: true,
    );
  }

  void _showViewBookDialog(Map<String, dynamic> book) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(
              maxWidth: 450,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0096C7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          color: Color(0xFF0096C7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'View Book',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0096C7),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 24),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side - Book details
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildViewDetailItem('Book ID :', '${book['id']}'),
                              const SizedBox(height: 16),
                              _buildViewDetailItem('Name :', book['name']),
                              const SizedBox(height: 16),
                              _buildViewDetailItem('Type :', book['type']),
                              const SizedBox(height: 16),
                              _buildViewDetailItem('Language :', book['language']),
                            ],
                          ),
                        ),
                        // Vertical divider
                        Container(
                          width: 1,
                          height: 150,
                          color: Colors.grey[300],
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        // Right side - Saved by info
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saved by :',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mr. XYZ',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '(Admin)',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Close button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0096C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'CLOSE',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddBookDialog() {
    final nameController = TextEditingController();
    final languageController = TextEditingController();
    final typeController = TextEditingController();
    final quantityController = TextEditingController();
    
    String? selectedBookFile;
    String? selectedPdfFile;
    String? selectedSummaryFile;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0096C7).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.menu_book,
                              color: Color(0xFF0096C7),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Add Book',
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0096C7),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Form content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Name field
                            _buildTextField(
                              controller: nameController,
                              label: 'Name',
                              hint: 'Enter book name',
                            ),
                            const SizedBox(height: 16),
                            // Language field
                            _buildTextField(
                              controller: languageController,
                              label: 'Language',
                              hint: 'Enter language',
                            ),
                            const SizedBox(height: 16),
                            // Type and Quantity row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: typeController,
                                    label: 'Type',
                                    hint: 'Enter type',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: quantityController,
                                    label: 'Quantity',
                                    hint: 'Enter quantity',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // File selection indicators
                            if (selectedBookFile != null) 
                              _buildFileIndicator('Book File', selectedBookFile!),
                            if (selectedPdfFile != null) 
                              _buildFileIndicator('PDF File', selectedPdfFile!),
                            if (selectedSummaryFile != null) 
                              _buildFileIndicator('Summary File', selectedSummaryFile!),
                            
                            const SizedBox(height: 16),
                            
                            // Action buttons
                            Column(
                              children: [
                                // Add Book row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDialogActionButton(
                                        text: 'CANCEL',
                                        backgroundColor: Colors.grey[300]!,
                                        textColor: Colors.grey[700]!,
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDialogActionButton(
                                        text: 'ADD BOOK',
                                        backgroundColor: const Color(0xFF0096C7),
                                        textColor: Colors.white,
                                        onPressed: () async {
                                          final result = await _pickFile(['pdf', 'epub', 'txt']);
                                          if (result != null) {
                                            setState(() {
                                              selectedBookFile = result;
                                            });
                                            _showSnackBar('Book file selected: ${result.split('/').last}');
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Add PDF row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDialogActionButton(
                                        text: 'CANCEL',
                                        backgroundColor: Colors.grey[300]!,
                                        textColor: Colors.grey[700]!,
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDialogActionButton(
                                        text: 'ADD PDF',
                                        backgroundColor: const Color(0xFF0096C7),
                                        textColor: Colors.white,
                                        onPressed: () async {
                                          final result = await _pickFile(['pdf']);
                                          if (result != null) {
                                            setState(() {
                                              selectedPdfFile = result;
                                            });
                                            _showSnackBar('PDF file selected: ${result.split('/').last}');
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Add Summary row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDialogActionButton(
                                        text: 'CANCEL',
                                        backgroundColor: Colors.grey[300]!,
                                        textColor: Colors.grey[700]!,
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDialogActionButton(
                                        text: 'ADD SUMMARY',
                                        backgroundColor: const Color(0xFF0096C7),
                                        textColor: Colors.white,
                                        onPressed: () async {
                                          final result = await _pickFile(['pdf', 'txt', 'doc', 'docx']);
                                          if (result != null) {
                                            setState(() {
                                              selectedSummaryFile = result;
                                            });
                                            _showSnackBar('Summary file selected: ${result.split('/').last}');
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Save button
                                SizedBox(
                                  width: double.infinity,
                                  child: _buildDialogActionButton(
                                    text: 'SAVE BOOK',
                                    backgroundColor: Colors.green,
                                    textColor: Colors.white,
                                    onPressed: () {
                                      _saveBook(
                                        name: nameController.text,
                                        language: languageController.text,
                                        type: typeController.text,
                                        quantity: quantityController.text,
                                        bookFile: selectedBookFile,
                                        pdfFile: selectedPdfFile,
                                        summaryFile: selectedSummaryFile,
                                      );
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _pickFile(List<String> allowedExtensions) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path!;
      }
      return null;
    } catch (e) {
      _showSnackBar('Error picking file: $e');
      return null;
    }
  }

  Widget _buildFileIndicator(String label, String filePath) {
    final fileName = filePath.split('/').last;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  fileName,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.green[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveBook({
    required String name,
    required String language,
    required String type,
    required String quantity,
    String? bookFile,
    String? pdfFile,
    String? summaryFile,
  }) {
    // Here you would implement the actual save logic
    // For now, we'll just show a success message
    final fileCount = [bookFile, pdfFile, summaryFile].where((f) => f != null).length;
    
    _showSnackBar(
      'Book "$name" saved successfully with $fileCount file(s)!',
      isSuccess: true,
    );
    
    // You can add the book to your list here
    // setState(() {
    //   _books.add({
    //     'id': _books.length + 1,
    //     'name': name,
    //     'type': type,
    //     'language': language,
    //     'availability': 'Available',
    //   });
    // });
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        backgroundColor: isSuccess ? Colors.green : const Color(0xFF0096C7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0096C7), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDialogActionButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'technical':
        return const Color(0xFF6366F1);
      case 'it':
        return const Color(0xFF8B5CF6);
      case 'educational':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF0096C7);
    }
  }

  void _showBookCategoryFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(
                  maxWidth: 400,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0096C7).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.menu_book,
                              color: Color(0xFF0096C7),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Book Category',
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0096C7),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    // Category list
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _bookCategories.length,
                                itemBuilder: (context, index) {
                                  final category = _bookCategories[index];
                                  final isSelected = _selectedCategories.contains(category);
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedCategories.remove(category);
                                            } else {
                                              _selectedCategories.add(category);
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? const Color(0xFF0096C7).withOpacity(0.1)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            border: isSelected 
                                                ? Border.all(
                                                    color: const Color(0xFF0096C7),
                                                    width: 1,
                                                  )
                                                : null,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  category,
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 14,
                                                    color: isSelected 
                                                        ? const Color(0xFF0096C7)
                                                        : Colors.black87,
                                                    fontWeight: isSelected 
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                              if (isSelected)
                                                Icon(
                                                  Icons.check,
                                                  color: const Color(0xFF0096C7),
                                                  size: 18,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildDialogActionButton(
                              text: 'REMOVE',
                              backgroundColor: Colors.grey[300]!,
                              textColor: Colors.grey[700]!,
                              onPressed: () {
                                setState(() {
                                  _selectedCategories.clear();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDialogActionButton(
                              text: 'ADD',
                              backgroundColor: const Color(0xFF0096C7),
                              textColor: Colors.white,
                              onPressed: () {
                                Navigator.of(context).pop();
                                _applyBookCategoryFilter();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _applyBookCategoryFilter() {
    if (_selectedCategories.isEmpty) {
      _showSnackBar('No categories selected for filtering');
      return;
    }
    
    _showSnackBar(
      'Filter applied for ${_selectedCategories.length} category(ies): ${_selectedCategories.join(', ')}',
      isSuccess: true,
    );
    
    // Here you would implement the actual filtering logic
    // For example, filter the _books list based on selected categories
  }

  // Book Club Dialog Methods
  void _showUpdateBookClubDialog(Map<String, dynamic> bookClub) {
    final nameController = TextEditingController(text: bookClub['name']);
    final categoryController = TextEditingController(text: bookClub['category']);
    final statusController = TextEditingController(text: bookClub['status']);
    final quantityController = TextEditingController(text: '1'); // Default quantity

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0096C7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.groups,
                          color: Color(0xFF0096C7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Update Book Club',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0096C7),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Form content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Name field
                        _buildTextField(
                          controller: nameController,
                          label: 'Name',
                          hint: 'Enter book club name',
                        ),
                        const SizedBox(height: 16),
                        // Category field
                        _buildTextField(
                          controller: categoryController,
                          label: 'Category',
                          hint: 'Enter category',
                        ),
                        const SizedBox(height: 16),
                        // Status and Quantity row
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: statusController,
                                label: 'Status',
                                hint: 'Enter status',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: quantityController,
                                label: 'Quantity',
                                hint: 'Enter quantity',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogActionButton(
                                text: 'CANCEL',
                                backgroundColor: Colors.grey[300]!,
                                textColor: Colors.grey[700]!,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDialogActionButton(
                                text: 'UPDATE',
                                backgroundColor: const Color(0xFF0096C7),
                                textColor: Colors.white,
                                onPressed: () {
                                  _updateBookClub(
                                    bookClub: bookClub,
                                    name: nameController.text,
                                    category: categoryController.text,
                                    status: statusController.text,
                                    quantity: quantityController.text,
                                  );
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateBookClub({
    required Map<String, dynamic> bookClub,
    required String name,
    required String category,
    required String status,
    required String quantity,
  }) {
    // Update the book club in the list
    setState(() {
      final index = _bookClubs.indexOf(bookClub);
      if (index != -1) {
        _bookClubs[index] = {
          ..._bookClubs[index],
          'name': name,
          'category': category,
          'status': status,
        };
      }
    });
    
    _showSnackBar(
      'Book Club "$name" updated successfully!',
      isSuccess: true,
    );
  }

  void _showDeleteBookClubConfirmationDialog(Map<String, dynamic> bookClub) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and close button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Delete Confirmation',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Divider
                Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 24),
                // Confirmation message
                Text(
                  '"Are you certain you wish to proceed with the deletion of the selected entry?"',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deleteBookClub(bookClub);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0096C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'CONFIRM',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteBookClub(Map<String, dynamic> bookClub) {
    setState(() {
      _bookClubs.remove(bookClub);
    });
    
    _showSnackBar(
      'Book Club "${bookClub['name']}" deleted successfully!',
      isSuccess: true,
    );
  }

  void _showViewBookClubDialog(Map<String, dynamic> bookClub) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(
              maxWidth: 450,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0096C7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.groups,
                          color: Color(0xFF0096C7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'View Book Club',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0096C7),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 24),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side - Book club details
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildViewDetailItem('Club ID :', '${bookClub['id']}'),
                              const SizedBox(height: 16),
                              _buildViewDetailItem('Name :', bookClub['name']),
                              const SizedBox(height: 16),
                              _buildViewDetailItem('Category :', bookClub['category']),
                              const SizedBox(height: 16),
                              _buildViewDetailItem('Status :', bookClub['status']),
                            ],
                          ),
                        ),
                        // Vertical divider
                        Container(
                          width: 1,
                          height: 150,
                          color: Colors.grey[300],
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        // Right side - Saved by info
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saved by :',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mr. XYZ',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '(Admin)',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Close button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0096C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'CLOSE',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookClubManagement() {
    return Column(
      children: [
        _buildBookClubSearchAndActions(),
        _buildBookClubDataTable(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBookClubSearchAndActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
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
                    controller: _bookSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search by ID or Type',
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
                  color: const Color(0xFF0096C7),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0096C7).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _showAddBookDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add Book',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
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
        ],
      ),
    );
  }

  Widget _buildBookClubDataTable() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
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
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F8FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        'ID',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 300,
                      child: Text(
                        'Name',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 150,
                      child: Text(
                        'Category',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: Text(
                        'Status',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: Text(
                        'Action',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0096C7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Table Body
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _bookClubs.length,
                itemBuilder: (context, index) {
                  final bookClub = _bookClubs[index];
                  final isEven = index % 2 == 0;
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : const Color(0xFFFAFCFF),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              '${bookClub['id']}',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 300,
                            child: Text(
                              bookClub['name'],
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 150,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0096C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                bookClub['category'],
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 120,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                bookClub['status'],
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: Icons.edit,
                                  color: const Color(0xFF0096C7),
                                  onTap: () {
                                    _showUpdateBookClubDialog(bookClub);
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.delete,
                                  color: Colors.red,
                                  onTap: () {
                                    _showDeleteBookClubConfirmationDialog(bookClub);
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.remove_red_eye,
                                  color: Colors.green,
                                  onTap: () {
                                    _showViewBookClubDialog(bookClub);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Book Management Tab
                Column(
                  children: [
                    _buildSearchAndActions(),
                    _buildDataTable(),
                    const SizedBox(height: 24),
                  ],
                ),
                // Book Club Management Tab
                _buildBookClubManagement(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
