import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// --- ENUMS for State Management ---

/// Represents the various states of the PDF loading process.
///
/// Using an enum for state management provides better type safety and code
/// clarity compared to using multiple boolean flags.
enum PdfState {
  /// The initial state before loading begins.
  initial,

  /// The state when the PDF document is actively being loaded.
  loading,

  /// The state when the PDF has been successfully loaded and is ready for display.
  ready,

  /// The state when an error has occurred during the loading process.
  error,
}


// --- DIALOG HELPER ---

/// A utility class for displaying dialogs related to the PDF preview screen.
///
/// Encapsulating dialog logic in a separate class keeps the UI state code
/// cleaner and more focused on its primary responsibilities.
class PreviewDialogHelper {
  /// Shows a dialog informing the user that they have reached the page limit.
  ///
  /// This dialog provides an option to dismiss or to proceed to the
  /// full access / login prompt.
  ///
  /// [context]: The BuildContext required to show the dialog.
  /// [maxPages]: The maximum number of pages allowed in the preview.
  /// [onLoginRequested]: A callback function to be executed when the user
  ///                    opts to get full access.
  static void showPageLimitDialog(
    BuildContext context,
    int maxPages, {
    required VoidCallback onLoginRequested,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // --- Dialog Title ---
          title: Text(
            'Preview Limit Reached',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          // --- Dialog Content ---
          content: Text(
            'You can only preview the first $maxPages pages of this book. '
            'Please login to read the complete book.',
            style: GoogleFonts.montserrat(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          // --- Dialog Actions ---
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
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
                Navigator.of(dialogContext).pop();
                onLoginRequested();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0096C7),
              ),
              child: Text(
                'Login to Read',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Shows a dialog explaining the benefits of full access and prompting to log in.
  ///
  /// This dialog is shown when the user explicitly taps the "Read Full Book" button.
  ///
  /// [context]: The BuildContext required to show the dialog.
  /// [onLoginConfirmed]: A callback function to execute when the user confirms
  ///                     they want to log in.
  static void showFullAccessDialog(
    BuildContext context, {
    required VoidCallback onLoginConfirmed,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // --- Dialog Title ---
          title: Text(
            'Full Access Required',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          // --- Dialog Content ---
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To read the complete book, you need to log in to your account.',
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
                // --- Feature List ---
                ...[
                  '• Read complete books',
                  '• Bookmark your favorites',
                  '• Access to entire library',
                  '• Offline reading',
                ].map((feature) => Padding(
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
          ),
          // --- Dialog Actions ---
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onLoginConfirmed();
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
        );
      },
    );
  }
}


// --- MAIN WIDGET ---

/// A screen to display a limited preview of a PDF file from a local path.
///
/// This widget is responsible for coordinating the display of the PDF viewer,
/// handling page change events to enforce a page limit, and showing relevant
/// UI elements like loading indicators, error messages, and dialogs.
class PdfPreviewScreen extends StatefulWidget {
  /// The local file system path to the PDF file.
  final String pdfPath;

  /// The title of the book, displayed in the AppBar.
  final String bookTitle;

  /// The maximum number of pages the user is allowed to view in this preview.
  final int maxPages;

  /// The constructor for the PdfPreviewScreen.
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
  // --- Controllers ---
  late final PdfViewerController _pdfViewerController;

  // --- State Variables ---

  /// The current state of the PDF loading process.
  PdfState _pdfState = PdfState.loading;

  /// The error message to be displayed if the PDF fails to load.
  String _errorMessage = '';

  /// The current page number the user is viewing.
  int _currentPage = 1;

  /// The total number of pages in the entire PDF document.
  int _totalPages = 0;


  // --- Lifecycle Methods ---

  @override
  void initState() {
    super.initState();
    // Initialize the controller used to interact with the SfPdfViewer.
    _pdfViewerController = PdfViewerController();
    // A simple log to indicate the screen has been initialized.
    debugPrint("PdfPreviewScreen initialized for: ${widget.bookTitle}");
  }

  @override
  void dispose() {
    // It's crucial to dispose of the controller to free up resources.
    _pdfViewerController.dispose();
    debugPrint("PdfPreviewScreen disposed.");
    super.dispose();
  }


  // --- Event Handlers ---

  /// Callback for when the PDF document has been successfully loaded.
  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    debugPrint("PDF document loaded successfully. Total pages: ${details.document.pages.count}");
    // Update the state to reflect that the document is ready.
    if (mounted) {
      setState(() {
        _totalPages = details.document.pages.count;
        _pdfState = PdfState.ready;
      });
    }
  }

  /// Callback for when the PDF document fails to load.
  void _onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    debugPrint("Failed to load PDF document. Error: ${details.error}, Description: ${details.description}");
    // Update the state to show an error message.
    if (mounted) {
      setState(() {
        _errorMessage = 'Failed to load PDF: ${details.description}';
        _pdfState = PdfState.error;
      });
    }
  }

  /// Callback for when the current page changes.
  void _onPageChanged(PdfPageChangedDetails details) {
    final newPageNumber = details.newPageNumber;
    debugPrint("Page changed to: $newPageNumber");

    // Enforce the page limit. If the user tries to go beyond the max preview
    // pages, jump them back to the last allowed page and show a dialog.
    if (newPageNumber > widget.maxPages) {
      // Use a post-frame callback to ensure the jump happens after the
      // current frame is built, preventing potential race conditions.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pdfViewerController.jumpToPage(widget.maxPages);
        // We do not update the state here, as the page number will be corrected back.
      });
      PreviewDialogHelper.showPageLimitDialog(
        context,
        widget.maxPages,
        onLoginRequested: _handleLoginRequest,
      );
      return;
    }

    // If the page change is valid, update the current page number state.
    if (mounted) {
      setState(() {
        _currentPage = newPageNumber;
      });
    }
  }

  /// Handles the request to log in, typically triggered from a dialog.
  void _handleLoginRequest() {
    debugPrint("Login requested. Navigating away from preview.");
    // In a real app, you would navigate to the login screen.
    // Here, we pop the preview screen to simulate returning to the main app.
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }


  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A light grey background provides a subtle contrast for the viewer.
      backgroundColor: Colors.grey[100],

      // --- AppBar ---
      appBar: AppBar(
        title: _AppBarContent(
          bookTitle: widget.bookTitle,
          maxPages: widget.maxPages,
        ),
        backgroundColor: const Color(0xFF0096C7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // --- Body ---
      body: Stack(
        children: [
          // The core content is determined by the current PDF loading state.
          _buildBodyContent(),

          // The page indicator overlay is shown only when the PDF is ready.
          if (_pdfState == PdfState.ready)
            _PageIndicator(
              currentPage: _currentPage,
              maxPages: widget.maxPages,
            ),
        ],
      ),

      // --- Floating Action Button ---
      floatingActionButton: _pdfState == PdfState.ready
          ? _ReadFullBookFAB(
              onPressed: () => PreviewDialogHelper.showFullAccessDialog(
                context,
                onLoginConfirmed: _handleLoginRequest,
              ),
            )
          : null,
    );
  }


  // --- UI Helper Methods ---

  /// Determines which widget to display in the body based on [_pdfState].
  Widget _buildBodyContent() {
    switch (_pdfState) {
      case PdfState.loading:
      case PdfState.initial:
        // Show the PDF viewer and a loading indicator on top.
        return Stack(
          children: [
            _PdfViewerCore(
              pdfPath: widget.pdfPath,
              controller: _pdfViewerController,
              onDocumentLoaded: _onDocumentLoaded,
              onDocumentLoadFailed: _onDocumentLoadFailed,
              onPageChanged: _onPageChanged,
            ),
            const _LoadingIndicator(),
          ],
        );

      case PdfState.ready:
        // When ready, only show the PDF viewer itself.
        return _PdfViewerCore(
          pdfPath: widget.pdfPath,
          controller: _pdfViewerController,
          onDocumentLoaded: _onDocumentLoaded,
          onDocumentLoadFailed: _onDocumentLoadFailed,
          onPageChanged: _onPageChanged,
        );

      case PdfState.error:
        // When an error occurs, show a dedicated error message widget.
        return _ErrorDisplay(errorMessage: _errorMessage);
    }
  }
}

// --- UI Components (Broken Down for Readability and Maintainability) ---

/// A stateless widget for the content of the AppBar.
class _AppBarContent extends StatelessWidget {
  final String bookTitle;
  final int maxPages;

  const _AppBarContent({
    required this.bookTitle,
    required this.maxPages,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bookTitle,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Preview (First $maxPages pages)',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

/// A stateless widget that encapsulates the core `SfPdfViewer`.
class _PdfViewerCore extends StatelessWidget {
  final String pdfPath;
  final PdfViewerController controller;
  final Function(PdfDocumentLoadedDetails) onDocumentLoaded;
  final Function(PdfDocumentLoadFailedDetails) onDocumentLoadFailed;
  final Function(PdfPageChangedDetails) onPageChanged;

  const _PdfViewerCore({
    required this.pdfPath,
    required this.controller,
    required this.onDocumentLoaded,
    required this.onDocumentLoadFailed,
    required this.onPageChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SfPdfViewer.file(
      File(pdfPath),
      controller: controller,
      onDocumentLoaded: onDocumentLoaded,
      onDocumentLoadFailed: onDocumentLoadFailed,
      onPageChanged: onPageChanged,
    );
  }
}

/// A stateless widget for displaying a loading indicator overlay.
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // A semi-transparent overlay to dim the background.
      color: Colors.white.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF0096C7),
              strokeWidth: 3.0,
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
    );
  }
}

/// A stateless widget for displaying an error message in the center of the screen.
class _ErrorDisplay extends StatelessWidget {
  final String errorMessage;

  const _ErrorDisplay({
    required this.errorMessage,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
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
            'Error Loading PDF',
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
    );
  }
}

/// A stateless widget for the page indicator overlay at the bottom of the screen.
class _PageIndicator extends StatelessWidget {
  final int currentPage;
  final int maxPages;

  const _PageIndicator({
    required this.currentPage,
    required this.maxPages,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
              'Page $currentPage of $maxPages',
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
    );
  }
}

/// A stateless widget for the 'Read Full Book' floating action button.
class _ReadFullBookFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const _ReadFullBookFAB({
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF0096C7),
      icon: const Icon(Icons.lock_open, color: Colors.white),
      label: Text(
        'Read Full Book',
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}