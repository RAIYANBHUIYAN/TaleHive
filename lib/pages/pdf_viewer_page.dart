import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends StatelessWidget {
  final String pdfUrl;
  final String bookTitle;
  
  const PdfViewerPage({
    Key? key,
    required this.pdfUrl,
    required this.bookTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(bookTitle),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
      ),
    );
  }
}