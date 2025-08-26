import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class PDFService {
  static final _supabase = Supabase.instance.client;
  static final Map<String, String> _urlCache = {}; // ✅ Add URL caching
  static final Map<String, File> _fileCache = {}; // ✅ Add file caching

  // ✅ Optimized getPDFUrl with caching
  static Future<String?> getPDFUrl(String bookId) async {
    try {
      // Check cache first
      if (_urlCache.containsKey(bookId)) {
        print('✅ Using cached URL for book $bookId');
        return _urlCache[bookId];
      }

      print('🔍 Fetching PDF URL for book ID: $bookId');
      
      // ✅ Use select specific fields only for faster query
      final response = await _supabase
          .from('books')
          .select('pdf_url, title')
          .eq('id', bookId)
          .eq('is_active', true)
          .single()
          .timeout(const Duration(seconds: 8)); // ✅ Add timeout

      final pdfUrl = response['pdf_url'] as String?;
      
      if (pdfUrl == null || pdfUrl.isEmpty) {
        print('❌ No PDF URL found for book $bookId');
        return null;
      }

      // ✅ Cache the URL for future use
      _urlCache[bookId] = pdfUrl;
      print('✅ PDF URL cached for book $bookId');
      
      return pdfUrl;
    } catch (e) {
      print('❌ Error getting PDF URL: $e');
      return null;
    }
  }

  // ✅ Optimized download with progress and caching
  static Future<String?> downloadPDF({
    required String url,
    required String fileName,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      // Check if file already exists in cache
      final cacheKey = '${fileName}_${url.hashCode}';
      if (_fileCache.containsKey(cacheKey)) {
        final cachedFile = _fileCache[cacheKey]!;
        if (await cachedFile.exists()) {
          print('✅ Using cached file: ${cachedFile.path}');
          onProgress?.call(1, 1); // Report as complete
          return cachedFile.path;
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${fileName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      print('📥 Starting download: $url');
      
      // ✅ Use HTTP client with better configuration
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      
      // ✅ Add headers for better compatibility
      request.headers.addAll({
        'User-Agent': 'Mozilla/5.0 (compatible; PDFViewer/1.0)',
        'Accept': 'application/pdf,*/*',
        'Connection': 'keep-alive',
      });

      final response = await client.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Download timeout'),
      );

      if (response.statusCode != 200) {
        client.close();
        throw Exception('HTTP ${response.statusCode}: Failed to download PDF');
      }

      final contentLength = response.contentLength ?? 0;
      var downloadedBytes = 0;
      
      final fileStream = file.openWrite();
      
      await response.stream.listen(
        (chunk) {
          fileStream.add(chunk);
          downloadedBytes += chunk.length;
          onProgress?.call(downloadedBytes, contentLength);
        },
        onDone: () async {
          await fileStream.close();
          client.close();
        },
        onError: (error) async {
          await fileStream.close();
          client.close();
          throw error;
        },
      ).asFuture();

      // ✅ Cache the downloaded file
      _fileCache[cacheKey] = file;
      print('✅ Download completed: $filePath');
      
      return filePath;
    } catch (e) {
      print('❌ Download error: $e');
      rethrow;
    }
  }

  // ✅ Add method to preload PDF for faster access
  static Future<void> preloadPDF(String bookId) async {
    try {
      final url = await getPDFUrl(bookId);
      if (url != null) {
        // Just check if PDF is accessible without downloading
        final response = await http.head(Uri.parse(url)).timeout(
          const Duration(seconds: 5),
        );
        if (response.statusCode == 200) {
          print('✅ PDF preloaded and verified for book $bookId');
        }
      }
    } catch (e) {
      print('⚠️ PDF preload failed for book $bookId: $e');
    }
  }

  // ✅ Clear cache to free memory
  static void clearCache() {
    _urlCache.clear();
    _fileCache.clear();
    print('🧹 PDF cache cleared');
  }

  // ✅ Get cache size for debugging
  static int getCacheSize() {
    return _urlCache.length + _fileCache.length;
  }
}