import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// PDF text extraction service
class PDFService {
  /// Extract text from PDF bytes
  Future<String> extractTextFromBytes(Uint8List bytes) async {
    try {
      // Load PDF document
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // Extract text
      final StringBuffer textBuffer = StringBuffer();
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      
      final int pageCount = document.pages.count;
      
      // Process pages in chunks to keep UI responsive
      for (int i = 0; i < pageCount; i++) {
        // Extract one page at a time
        final String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
        
        if (pageText.isNotEmpty) {
          textBuffer.writeln(pageText);
          textBuffer.writeln(); 
        }
        
        // Yield to let the UI thread breathe on EVERY page for maximum responsiveness
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      // Dispose document
      document.dispose();
      
      final result = textBuffer.toString().trim();
      
      if (result.isEmpty) {
        throw Exception('PDF dosyasından metin çıkarılamadı. Dosya görsel tabanlı (taranmış) olabilir.');
      }
      
      return result;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('PDF işlenirken hata oluştu: $e');
    }
  }
  
  /// Get page count from PDF
  Future<int> getPageCount(Uint8List bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final int pageCount = document.pages.count;
      document.dispose();
      return pageCount;
    } catch (e) {
      throw Exception('PDF sayfa sayısı alınamadı: $e');
    }
  }
  
  /// Extract text from specific pages
  Future<String> extractTextFromPages(Uint8List bytes, int startPage, int endPage) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // Validate page range
      final maxPage = document.pages.count - 1;
      final safeStart = startPage.clamp(0, maxPage);
      final safeEnd = endPage.clamp(0, maxPage);
      
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText(startPageIndex: safeStart, endPageIndex: safeEnd);
      
      document.dispose();
      
      return text.trim();
    } catch (e) {
      throw Exception('PDF sayfaları işlenirken hata oluştu: $e');
    }
  }
}
