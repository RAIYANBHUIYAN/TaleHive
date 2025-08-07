import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class PdfPreviewScreen extends StatefulWidget {
  final String pdfPath;
  final String bookTitle;
  final int maxPages;

  const PdfPreviewScreen({
    Key? key,
    required this.pdfPath,
    required this.bookTitle,
    required this.maxPages,
  }) : super(key: key);

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late PdfViewerController _pdfViewerController;
  int currentPage = 1;
  int totalPages = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bookTitle,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Preview (First ${widget.maxPages} pages)',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0096C7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          if (errorMessage.isNotEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading PDF',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      errorMessage,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          else
            SfPdfViewer.file(
              File(widget.pdfPath),
              controller: _pdfViewerController,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  totalPages = details.document.pages.count;
                  isReady = true;
                });
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                setState(() {
                  errorMessage = 'Failed to load PDF: ${details.error}';
                });
              },
              onPageChanged: (PdfPageChangedDetails details) {
                final newPage = details.newPageNumber;
                
                // Check if user is trying to go beyond the allowed pages
                if (newPage > widget.maxPages) {
                  // Jump back to the last allowed page
                  _pdfViewerController.jumpToPage(widget.maxPages);
                  _showPageLimitDialog();
                  return;
                }
                
                setState(() {
                  currentPage = newPage;
                });
              },
            ),
          
          // Loading indicator
          if (!isReady && errorMessage.isEmpty)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF0096C7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading PDF...',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Page indicator
          if (isReady && errorMessage.isEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page $currentPage of ${widget.maxPages}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0096C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'PREVIEW',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: isReady && errorMessage.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _showFullAccessDialog,
              backgroundColor: const Color(0xFF0096C7),
              icon: const Icon(Icons.lock_open, color: Colors.white),
              label: Text(
                'Read Full Book',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  void _showPageLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Preview Limit Reached',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        content: Text(
          'You can only preview the first ${widget.maxPages} pages of this book. Please login to read the complete book.',
          style: GoogleFonts.montserrat(
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.montserrat(
                color: const Color(0xFF0096C7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showFullAccessDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0096C7),
            ),
            child: Text(
              'Login to Read Full Book',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullAccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Full Access Required',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To read the complete book, you need to login to your account.',
              style: GoogleFonts.montserrat(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'With full access you get:',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            ...['• Read complete books', '• Bookmark your favorites', '• Access to entire library', '• Offline reading']
                .map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        feature,
                        style: GoogleFonts.montserrat(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe Later',
              style: GoogleFonts.montserrat(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to main screen
              // Navigate to login screen would be implemented here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0096C7),
            ),
            child: Text(
              'Login Now',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
