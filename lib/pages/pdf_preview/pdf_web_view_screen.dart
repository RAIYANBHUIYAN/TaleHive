import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class PdfWebViewScreen extends StatefulWidget {
  final String pdfUrl;
  final String bookTitle;
  final String author;
  final bool isPreview;
  final int maxPages;

  const PdfWebViewScreen({
    Key? key,
    required this.pdfUrl,
    required this.bookTitle,
    this.author = '',
    this.isPreview = true,
    this.maxPages = 10,
  }) : super(key: key);

  @override
  State<PdfWebViewScreen> createState() => _PdfWebViewScreenState();
}

class _PdfWebViewScreenState extends State<PdfWebViewScreen> {
  late PdfViewerController _pdfViewerController;
  int _currentPageNumber = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _loadPdfFromUrl();
  }

  Future<void> _loadPdfFromUrl() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('Loading PDF from: ${widget.pdfUrl}');
      
      // Convert Google Drive URL to download format
      String downloadUrl = widget.pdfUrl;
      if (widget.pdfUrl.contains('drive.google.com')) {
        String fileId = '';
        if (widget.pdfUrl.contains('/file/d/')) {
          fileId = widget.pdfUrl.split('/file/d/')[1].split('/')[0];
        } else if (widget.pdfUrl.contains('id=')) {
          fileId = widget.pdfUrl.split('id=')[1].split('&')[0];
        }
        
        if (fileId.isNotEmpty) {
          downloadUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
        }
      }

      // Download PDF bytes
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode == 200) {
        setState(() {
          _pdfBytes = response.bodyBytes;
          _isLoading = false;
        });
        print('PDF loaded successfully. Size: ${_pdfBytes!.length} bytes');
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading PDF: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load PDF: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0096C7),
        foregroundColor: Colors.white,
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
            if (widget.author.isNotEmpty)
              Text(
                'by ${widget.author}',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          if (widget.isPreview)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Preview Only',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Preview limitation banner
          if (widget.isPreview)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange[50],
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Preview limited to first ${widget.maxPages} pages. Login to read the full book.',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(
                      'Login',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Page counter
          if (!_isLoading && _errorMessage == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isPreview 
                        ? 'Page $_currentPageNumber of ${_totalPages > 0 ? (_totalPages > widget.maxPages ? widget.maxPages : _totalPages) : widget.maxPages}'
                        : 'Page $_currentPageNumber of $_totalPages',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.isPreview && _currentPageNumber >= widget.maxPages)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0096C7),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        'Login to Continue',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // PDF Viewer or Error/Loading state
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingWidget();
    } else if (_errorMessage != null) {
      return _buildErrorWidget();
    } else if (_pdfBytes != null) {
      return _buildPdfViewer();
    } else {
      return _buildErrorWidget();
    }
  }

  Widget _buildPdfViewer() {
    return SfPdfViewer.memory(
      _pdfBytes!,
      controller: _pdfViewerController,
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPageNumber = details.newPageNumber;
        });
        
        // Block navigation beyond preview limit
        if (widget.isPreview && details.newPageNumber > widget.maxPages) {
          _pdfViewerController.jumpToPage(widget.maxPages);
          _showPreviewLimitDialog();
        }
      },
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPages = details.document.pages.count;
        });
        print('PDF loaded successfully. Total pages: $_totalPages');
        
        // If in preview mode and PDF has more than maxPages, show warning
        if (widget.isPreview && _totalPages > widget.maxPages) {
          _showPreviewInfoDialog();
        }
      },
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        setState(() {
          _errorMessage = details.error;
        });
        print('PDF load failed: ${details.error}');
      },
      enableDoubleTapZooming: true,
      enableTextSelection: false, // Disable text selection in preview
      pageSpacing: 4,
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF0096C7),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading PDF preview...',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we prepare your book preview',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                'Unable to load PDF',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'The PDF file could not be loaded. Please try again later.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _loadPdfFromUrl();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0096C7),
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(
                      'Login for Better Access',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF0096C7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPreviewLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Preview Limit Reached',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You can only preview the first ${widget.maxPages} pages. Please login to read the complete book.',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Preview'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close PDF viewer
              Navigator.pushNamed(context, '/login'); // Go to login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0096C7),
            ),
            child: Text(
              'Login',
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

  void _showPreviewInfoDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Preview Mode',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'This book has $_totalPages pages, but you can only view the first ${widget.maxPages} pages in preview mode. Login to access the complete book.',
            style: GoogleFonts.montserrat(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close PDF viewer
                Navigator.pushNamed(context, '/login'); // Go to login
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
    });
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }
}
