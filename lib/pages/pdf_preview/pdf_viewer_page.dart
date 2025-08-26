import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class PDFViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String bookTitle;
  final String bookId;

  const PDFViewerPage({
    Key? key,
    required this.pdfUrl,
    required this.bookTitle,
    required this.bookId,
  }) : super(key: key);

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  late PdfViewerController _pdfViewerController;
  String? localFilePath;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  int currentPage = 1;
  int totalPages = 0;
  double zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      // Check if the URL is accessible
      final dio = Dio();
      final response = await dio.head(widget.pdfUrl);

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception('PDF not accessible');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Failed to load PDF: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0096C7),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bookTitle,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (totalPages > 0)
              Text(
                'Page $currentPage of $totalPages',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
            },
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              if (_pdfViewerController.zoomLevel > 0.5) {
                _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
              }
            },
            tooltip: 'Zoom Out',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bookmarked page $currentPage'),
                  backgroundColor: const Color(0xFF0096C7),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Bookmark',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: totalPages > 0 ? _buildBottomControls() : null,
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF0096C7),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading PDF...',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we prepare your book',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Error Loading PDF',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPDF,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0096C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Retry',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Use SfPdfViewer.network for direct URL loading
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SfPdfViewer.network(
        widget.pdfUrl,
        controller: _pdfViewerController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        canShowPaginationDialog: true,
        onPageChanged: (PdfPageChangedDetails details) {
          setState(() {
            currentPage = details.newPageNumber;
          });
        },
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          setState(() {
            totalPages = details.document.pages.count;
          });
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          setState(() {
            hasError = true;
            errorMessage = 'Failed to load PDF: ${details.error}';
          });
        },
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // First page
          IconButton(
            icon: const Icon(Icons.first_page, color: Color(0xFF0096C7)),
            onPressed: currentPage > 1 ? () => _pdfViewerController.jumpToPage(1) : null,
            tooltip: 'First Page',
          ),

          // Previous page
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF0096C7)),
            onPressed: currentPage > 1 ? () => _pdfViewerController.previousPage() : null,
            tooltip: 'Previous Page',
          ),

          // Page info and jump to page
          Expanded(
            child: GestureDetector(
              onTap: _showPageJumpDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0096C7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$currentPage / $totalPages',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0096C7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Next page
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFF0096C7)),
            onPressed: currentPage < totalPages ? () => _pdfViewerController.nextPage() : null,
            tooltip: 'Next Page',
          ),

          // Last page
          IconButton(
            icon: const Icon(Icons.last_page, color: Color(0xFF0096C7)),
            onPressed: currentPage < totalPages ? () => _pdfViewerController.jumpToPage(totalPages) : null,
            tooltip: 'Last Page',
          ),
        ],
      ),
    );
  }

  void _showPageJumpDialog() {
    final TextEditingController pageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Jump to Page',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter page number (1-$totalPages)',
              style: GoogleFonts.montserrat(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelText: 'Page Number',
                hintText: 'e.g., 5',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final pageNumber = int.tryParse(pageController.text);
              if (pageNumber != null && pageNumber >= 1 && pageNumber <= totalPages) {
                _pdfViewerController.jumpToPage(pageNumber);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid page number (1-$totalPages)'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0096C7),
            ),
            child: Text(
              'Jump',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }}
