import 'dart:io';
import 'dart:math';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class OcrService {
  TextRecognizer? _textRecognizer;

  /// Creates a new text recognizer instance for each request to avoid reuse issues
  TextRecognizer _getTextRecognizer() {
    return GoogleMlKit.vision.textRecognizer();
  }

  /// Closes any active text recognizer to free up resources.
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
    
    // Clean up any remaining temporary files
    _cleanupTempFiles();
  }
  
  /// Cleans up temporary OCR files in the system temp directory
  void _cleanupTempFiles() {
    try {
      final tempDir = Directory.systemTemp;
      final tempFiles = tempDir.listSync()
          .where((entity) => entity is File)
          .cast<File>()
          .where((file) => path.basename(file.path).startsWith('ocr_processed_'))
          .toList();
      
      for (final file in tempFiles) {
        try {
          file.deleteSync();
          print("Cleaned up temp file: ${file.path}");
        } catch (e) {
          print("Could not delete temp file ${file.path}: $e");
        }
      }
    } catch (e) {
      print("Error during temp file cleanup: $e");
    }
  }

  /// Enhanced image preprocessing for better OCR performance.
  /// Steps:
  /// - Converts the image to grayscale.
  /// - Applies adaptive thresholding with noise reduction.
  /// - Enhances contrast and sharpness.
  /// - Optionally resizes for optimal OCR processing.
  /// Returns the file path of the processed image.
  Future<String> _preprocessImage(String imagePath) async {
    img.Image? originalImage;
    img.Image? resizedImage;
    img.Image? grayscaleImage;
    img.Image? blurredImage;
    img.Image? contrastImage;
    img.Image? thresholdedImage;
    img.Image? sharpenedImage;
    
    try {
      // Read the image file.
      final imageBytes = await File(imagePath).readAsBytes();
      originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception("Could not decode image.");
      }

      // Resize image if it's too large or too small (optimal range: 600-1200px width)
      resizedImage = originalImage;
      if (originalImage.width < 600 || originalImage.width > 1200) {
        final targetWidth = originalImage.width < 600 ? 800 : 1000;
        final targetHeight = (originalImage.height * targetWidth / originalImage.width).round();
        resizedImage = img.copyResize(originalImage, width: targetWidth, height: targetHeight);
      }

      // Convert image to grayscale.
      grayscaleImage = img.grayscale(resizedImage);

      // Apply noise reduction using a simple blur
      blurredImage = img.convolution(grayscaleImage, 
        filter: [
          1, 1, 1,
          1, 2, 1,
          1, 1, 1
        ], 
        div: 10);

      // Enhance contrast using histogram stretching
      contrastImage = _enhanceContrast(blurredImage);

      // Apply adaptive thresholding instead of fixed threshold
      thresholdedImage = _adaptiveThreshold(contrastImage);

      // Apply sharpening filter to enhance text edges
      sharpenedImage = img.convolution(thresholdedImage, 
        filter: [
          0, -1, 0,
          -1, 5, -1,
          0, -1, 0
        ]);

      // Create a temporary file to save the processed image with timestamp for uniqueness
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = "ocr_processed_${timestamp}_${Random().nextInt(1000)}.png";
      final processedImagePath = path.join(tempDir.path, newFileName);

      // Encode the image (using PNG for lossless quality).
      final processedImageBytes = img.encodePng(sharpenedImage);
      final processedFile = File(processedImagePath);
      await processedFile.writeAsBytes(processedImageBytes);

      print("Created temporary processed image: $processedImagePath");
      return processedImagePath;
    } catch (e) {
      print("Preprocessing Error: $e");
      rethrow;
    } finally {
      // Clear image references to help with memory management
      originalImage = null;
      resizedImage = null;
      grayscaleImage = null;
      blurredImage = null;
      contrastImage = null;
      thresholdedImage = null;
      sharpenedImage = null;
    }
  }

  /// Enhances image contrast using histogram stretching
  img.Image _enhanceContrast(img.Image image) {
    // Find min and max pixel values
    int minVal = 255;
    int maxVal = 0;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        var pixel = image.getPixel(x, y);
        int intensity = pixel.r.toInt();
        if (intensity < minVal) minVal = intensity;
        if (intensity > maxVal) maxVal = intensity;
      }
    }
    
    // Apply histogram stretching
    final range = maxVal - minVal;
    if (range > 0) {
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          var pixel = image.getPixel(x, y);
          int intensity = pixel.r.toInt();
          int stretched = ((intensity - minVal) * 255 / range).round().clamp(0, 255);
          image.setPixel(x, y, img.ColorRgb8(stretched, stretched, stretched));
        }
      }
    }
    
    return image;
  }

  /// Applies adaptive thresholding for better text separation
  img.Image _adaptiveThreshold(img.Image image) {
    const int blockSize = 15; // Size of the neighborhood for threshold calculation
    const double c = 10; // Constant subtracted from the mean
    
    img.Image result = img.Image.from(image);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        // Calculate local mean in the neighborhood
        int sum = 0;
        int count = 0;
        
        for (int dy = -blockSize ~/ 2; dy <= blockSize ~/ 2; dy++) {
          for (int dx = -blockSize ~/ 2; dx <= blockSize ~/ 2; dx++) {
            int nx = x + dx;
            int ny = y + dy;
            
            if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
              var pixel = image.getPixel(nx, ny);
              sum += pixel.r.toInt();
              count++;
            }
          }
        }
        
        double localMean = sum / count;
        double threshold = localMean - c;
        
        var pixel = image.getPixel(x, y);
        int intensity = pixel.r.toInt();
        
        // Apply threshold
        if (intensity > threshold) {
          result.setPixel(x, y, img.ColorRgb8(255, 255, 255)); // White
        } else {
          result.setPixel(x, y, img.ColorRgb8(0, 0, 0)); // Black
        }
      }
    }
    
    return result;
  }

  /// Processes the image at [imagePath] and returns a map containing the extracted 'title' and 'amount'.
  /// The method first preprocesses the image to improve OCR accuracy.
  Future<Map<String, String>?> processImage(String imagePath) async {
    TextRecognizer? textRecognizer;
    String? processedPath;
    final startTime = DateTime.now();
    
    try {
      // Create a fresh text recognizer instance for this request
      textRecognizer = _getTextRecognizer();
      
      // Preprocess the image before OCR.
      processedPath = await _preprocessImage(imagePath);
      final inputImage = InputImage.fromFilePath(processedPath);

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      final blocks = recognizedText.blocks.toList();
      final lines = blocks.expand((block) => block.lines).toList();

      // Extract heading from the first block.
      String? title = _extractTitle(blocks);

      // Extract total amount using enhanced keyword matching.
      String? amount = _extractTotalAmount(lines);

      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      
      // Calculate confidence scores
      final confidenceMetrics = _calculateConfidenceMetrics(
        recognizedText, title, amount, lines.length
      );

      return {
        'title': title ?? '',
        'amount': amount ?? '',
        'confidence_title': confidenceMetrics['title_confidence'].toString(),
        'confidence_amount': confidenceMetrics['amount_confidence'].toString(),
        'overall_confidence': confidenceMetrics['overall_confidence'].toString(),
        'processing_time_ms': processingTime.toString(),
        'total_text_blocks': blocks.length.toString(),
        'total_text_lines': lines.length.toString(),
        'extraction_metadata': _generateExtractionMetadata(recognizedText, blocks, lines),
      };
    } catch (e) {
      print("OCR Processing Error: $e");
      return null;
    } finally {
      // Critical cleanup to prevent resource leaks and freezing
      try {
        // Always close the text recognizer after use
        textRecognizer?.close();
        
        // Clean up the temporary processed image file
        if (processedPath != null) {
          final processedFile = File(processedPath);
          if (await processedFile.exists()) {
            await processedFile.delete();
            print("Cleaned up temporary file: $processedPath");
          }
        }
      } catch (cleanupError) {
        print("Cleanup error (non-critical): $cleanupError");
      }
    }
  }

  /// Calculates confidence metrics for OCR extraction
  Map<String, double> _calculateConfidenceMetrics(
    RecognizedText recognizedText,
    String? title,
    String? amount,
    int totalLines,
  ) {
    double titleConfidence = 0.0;
    double amountConfidence = 0.0;

    // Calculate title confidence based on text quality and patterns
    if (title != null && title.isNotEmpty) {
      // Check if title looks valid (contains alphabetic characters)
      if (RegExp(r'^[a-zA-Z\s&.-]+$').hasMatch(title)) {
        titleConfidence += 40.0;
      }
      // Length-based confidence (reasonable business name length)
      if (title.length >= 3 && title.length <= 50) {
        titleConfidence += 30.0;
      }
      // Word count confidence (2-8 words is typical for business names)
      final wordCount = title.split(' ').where((w) => w.isNotEmpty).length;
      if (wordCount >= 2 && wordCount <= 8) {
        titleConfidence += 20.0;
      }
      // Capitalization pattern (proper business names are often capitalized)
      if (title.split(' ').any((word) => word.isNotEmpty && word[0].toUpperCase() == word[0])) {
        titleConfidence += 10.0;
      }
    }

    // Calculate amount confidence based on format and context
    if (amount != null && amount.isNotEmpty) {
      // Valid number format
      if (double.tryParse(amount) != null) {
        amountConfidence += 50.0;
      }
      // Reasonable amount range (0.01 to 10000)
      final numAmount = double.tryParse(amount);
      if (numAmount != null && numAmount >= 0.01 && numAmount <= 10000) {
        amountConfidence += 30.0;
      }
      // Decimal places (typical for currency)
      if (amount.contains('.') && amount.split('.')[1].length <= 2) {
        amountConfidence += 20.0;
      }
    }

    // Overall text quality factor
    final textQualityFactor = _assessTextQuality(recognizedText);
    titleConfidence *= textQualityFactor;
    amountConfidence *= textQualityFactor;

    final overallConfidence = (titleConfidence + amountConfidence) / 2;

    return {
      'title_confidence': titleConfidence.clamp(0.0, 100.0),
      'amount_confidence': amountConfidence.clamp(0.0, 100.0),
      'overall_confidence': overallConfidence.clamp(0.0, 100.0),
    };
  }

  /// Assesses the overall quality of recognized text
  double _assessTextQuality(RecognizedText recognizedText) {
    double qualityScore = 1.0;
    int totalBlocks = recognizedText.blocks.length;
    int highConfidenceBlocks = 0;

    for (final block in recognizedText.blocks) {
      // Google ML Kit doesn't directly provide confidence scores for text blocks
      // We'll estimate quality based on text characteristics
      final blockText = block.text;
      
      // Check for clear, readable text patterns
      if (blockText.length > 2 && 
          RegExp(r'[a-zA-Z0-9]').hasMatch(blockText)) {
        highConfidenceBlocks++;
      }
    }

    if (totalBlocks > 0) {
      qualityScore = highConfidenceBlocks / totalBlocks;
    }

    // Boost quality if we have a reasonable amount of text
    if (totalBlocks >= 5) {
      qualityScore = (qualityScore + 0.2).clamp(0.0, 1.0);
    }

    return qualityScore;
  }

  /// Generates metadata about the extraction process for accuracy tracking
  String _generateExtractionMetadata(
    RecognizedText recognizedText,
    List<TextBlock> blocks,
    List<TextLine> lines,
  ) {
    final metadata = {
      'extraction_timestamp': DateTime.now().millisecondsSinceEpoch,
      'total_characters': recognizedText.text.length,
      'text_blocks_found': blocks.length,
      'text_lines_found': lines.length,
      'keywords_found': _countKeywordsFound(lines),
      'number_patterns_found': _countNumberPatterns(lines),
    };

    return metadata.toString();
  }

  /// Counts receipt-related keywords found in the text
  int _countKeywordsFound(List<TextLine> lines) {
    const keywords = ['total', 'amount', 'gst', 'tax', 'receipt', 'bill', 'invoice'];
    int count = 0;
    
    for (final line in lines) {
      final lineText = line.text.toLowerCase();
      for (final keyword in keywords) {
        if (lineText.contains(keyword)) {
          count++;
          break; // Count each line only once
        }
      }
    }
    
    return count;
  }

  /// Counts number patterns that could be amounts
  int _countNumberPatterns(List<TextLine> lines) {
    int count = 0;
    final numberPattern = RegExp(r'\d+\.?\d*');
    
    for (final line in lines) {
      if (numberPattern.hasMatch(line.text)) {
        count++;
      }
    }
    
    return count;
  }

  /// Enhanced title extraction with better handling of store names and special characters
  String? _extractTitle(List<TextBlock> blocks) {
    if (blocks.isEmpty) return null;
    
    print("\n=== OCR DEBUG: Starting title extraction ===");
    print("Total blocks available: ${blocks.length}");
    
    // Look through first few blocks for the best title candidate
    final blocksToCheck = blocks.take(3).toList();
    List<String> candidates = [];
    
    for (int blockIndex = 0; blockIndex < blocksToCheck.length; blockIndex++) {
      final block = blocksToCheck[blockIndex];
      print("Block $blockIndex lines:");
      
      for (int lineIndex = 0; lineIndex < block.lines.length; lineIndex++) {
        final line = block.lines[lineIndex];
        final text = line.text.trim();
        print("  Line $lineIndex: '$text'");
        
        if (text.isNotEmpty && text.length >= 2) {
          // Enhanced patterns for business names - now includes special characters
          final patterns = [
            RegExp(r'^[a-zA-Z][a-zA-Z\s&.-]{2,}$'), // Traditional business names
            RegExp(r'^[a-zA-Z][a-zA-Z\s&.\x27\-]{2,}$'), // With apostrophes
            RegExp(r'^[A-Z][a-zA-Z\s&.\x27\-]*$'), // Starts with capital
            RegExp(r'^[a-zA-Z]{3,}[\s]?[a-zA-Z\s&.\x27\-]*$'), // At least 3 chars
          ];
          
          for (int patternIndex = 0; patternIndex < patterns.length; patternIndex++) {
            if (patterns[patternIndex].hasMatch(text)) {
              final score = _scoreTitleCandidate(text, blockIndex, lineIndex);
              print("    Title candidate: '$text' (pattern ${patternIndex+1}, score: $score)");
              candidates.add(text);
              break;
            }
          }
        }
      }
    }
    
    String? bestTitle;
    if (candidates.isNotEmpty) {
      // Score and select the best candidate
      candidates.sort((a, b) {
        final scoreA = _scoreTitleCandidate(a, 0, 0);
        final scoreB = _scoreTitleCandidate(b, 0, 0);
        return scoreB.compareTo(scoreA); // Descending order
      });
      bestTitle = candidates.first;
      print("Selected title: '$bestTitle'");
    } else {
      // Fallback: use first non-empty line, cleaned up
      for (final block in blocksToCheck) {
        for (final line in block.lines) {
          final text = _cleanupTitle(line.text.trim());
          if (text.isNotEmpty && text.length >= 2) {
            bestTitle = text;
            print("Fallback title: '$bestTitle'");
            break;
          }
        }
        if (bestTitle != null) break;
      }
    }
    
    print("=== OCR DEBUG: Title extraction complete ===\n");
    return bestTitle;
  }
  
  /// Scores a title candidate based on various factors
  double _scoreTitleCandidate(String text, int blockIndex, int lineIndex) {
    double score = 0.0;
    
    // Position bonus (earlier is better)
    score += (3 - blockIndex) * 2.0; // Block position
    score += max(0, 5 - lineIndex) * 1.0; // Line position
    
    // Length bonus (reasonable business name length)
    if (text.length >= 5 && text.length <= 30) {
      score += 3.0;
    } else if (text.length >= 3 && text.length <= 50) {
      score += 1.0;
    }
    
    // Word count bonus (2-6 words typical for business names)
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount >= 2 && wordCount <= 6) {
      score += 2.0;
    } else if (wordCount == 1 && text.length >= 5) {
      score += 1.0; // Single word but substantial
    }
    
    // Capitalization bonus
    if (text[0].toUpperCase() == text[0]) {
      score += 1.0;
    }
    
    // Mixed case bonus (indicates proper business name)
    if (RegExp(r'[a-z]').hasMatch(text) && RegExp(r'[A-Z]').hasMatch(text)) {
      score += 1.0;
    }
    
    // Common business word bonus
    final businessWords = ['store', 'shop', 'mart', 'market', 'restaurant', 'cafe', 'coffee', 'hotel', 'inn'];
    final lowerText = text.toLowerCase();
    if (businessWords.any((word) => lowerText.contains(word))) {
      score += 2.0;
    }
    
    // Penalty for all caps (often headers/receipts details)
    if (text == text.toUpperCase() && text.length > 10) {
      score -= 2.0;
    }
    
    return score;
  }
  
  /// Cleans up title text by removing unwanted characters
  String _cleanupTitle(String text) {
    // Remove common receipt artifacts
    String cleaned = text;
    cleaned = cleaned.replaceAll(RegExp(r'^[\*\-=]+'), ''); // Remove leading symbols
    cleaned = cleaned.replaceAll(RegExp(r'[\*\-=]+$'), ''); // Remove trailing symbols
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
    cleaned = cleaned.trim();
    
    return cleaned;
  }

  /// Enhanced total amount extraction with improved keyword matching and context analysis
  String? _extractTotalAmount(List<TextLine> lines) {
    print("\n=== OCR DEBUG: Starting amount extraction ===");
    print("Total lines to analyze: ${lines.length}");
    
    // Log all extracted text for debugging
    for (int i = 0; i < lines.length; i++) {
      print("Line $i: '${lines[i].text}'");
    }
    
    // Enhanced keyword list with priority scores (increased TOTAL priority as suggested)
    const Map<String, int> totalKeywords = {
      'total': 20,  // Increased priority for simple "TOTAL" keyword
      'grand total': 18,
      'gross total': 18,
      'final total': 18,
      'total amount': 18,
      'total payable': 18,
      'amount due': 15,
      'balance due': 15,
      'net total': 15,
      'subtotal': 12,
      'gross amount': 12,
      'amount': 8,
      'balance': 7,
      'due': 7,
      'payable': 7,
      'gst total': 10,
      'tax total': 10,
      'grand': 6,
      'net': 6,
      'final': 6,
      'sum': 5,
      'bill': 5,
      'amt': 8,
      'tot': 10,
      'invoice total': 15,
      'receipt total': 15,
      'checkout total': 15,
      'order total': 15,
    };

    List<Map<String, dynamic>> potentialTotals = [];
    
    // First pass: Enhanced fulltext pattern matching (TOTAL 160.92 format)
    final fullText = lines.map((line) => line.text).join(' ').toLowerCase();
    print("Full OCR text: '$fullText'");
    
    // Try to find "TOTAL [amount]" patterns in full text
    final totalPatterns = [
      RegExp(r'total\s+([\d,]+\.\d{2})', caseSensitive: false),
      RegExp(r'total\s+\$?\s*([\d,]+\.\d{2})', caseSensitive: false),
      RegExp(r'total\s+([\d,]+)', caseSensitive: false),
      RegExp(r'total[:\-]?\s*\$?\s*([\d,]+\.?\d*)', caseSensitive: false),
    ];
    
    for (final pattern in totalPatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null && match.group(1) != null) {
        final amount = match.group(1)!.replaceAll(',', '');
        final amountValue = double.tryParse(amount);
        if (amountValue != null && amountValue > 0 && amountValue <= 50000) {
          print("Found fulltext pattern match: '$amount' with value $amountValue");
          potentialTotals.add({
            'amount': amount,
            'index': -1,
            'keyword': 'total_fulltext',
            'priority': 25, // High priority for fulltext matches
            'context_score': 5.0,
            'source': 'fulltext_pattern'
          });
          break; // Use first match
        }
      }
    }

    // Second pass: Look for keyword-amount pairs in the same line
    for (int i = 0; i < lines.length; i++) {
      final lineText = lines[i].text.toLowerCase().trim();
      print("Analyzing line $i: '$lineText'");
      
      for (final entry in totalKeywords.entries) {
        final keyword = entry.key;
        final priority = entry.value;
        
        if (lineText.contains(keyword)) {
          print("Found keyword '$keyword' in line $i");
          
          // Extract amount from current line using multiple methods
          String? amount = _extractAmountImproved(lineText);
          
          if (amount != null) {
            final amountValue = double.tryParse(amount);
            if (amountValue != null && amountValue > 0 && amountValue <= 50000) {
              print("Extracted amount '$amount' (value: $amountValue) from same line");
              potentialTotals.add({
                'amount': amount,
                'index': i,
                'keyword': keyword,
                'priority': priority,
                'context_score': _calculateContextScore(lineText, keyword, amountValue),
                'source': 'same_line'
              });
            }
          }
          
          // Also check the next line for amounts
          if (i + 1 < lines.length) {
            final nextLineText = lines[i + 1].text.trim();
            String? nextAmount = _extractAmountImproved(nextLineText);
            
            if (nextAmount != null) {
              final amountValue = double.tryParse(nextAmount);
              if (amountValue != null && amountValue > 0 && amountValue <= 50000) {
                print("Extracted amount '$nextAmount' (value: $amountValue) from next line");
                potentialTotals.add({
                  'amount': nextAmount,
                  'index': i,
                  'keyword': keyword,
                  'priority': priority - 1, // Slight penalty for next line
                  'context_score': _calculateContextScore(nextLineText, keyword, amountValue),
                  'source': 'next_line'
                });
              }
            }
          }
        }
      }
    }

    // Third pass: Look for standalone amounts in bottom half if no keyword matches
    if (potentialTotals.isEmpty) {
      print("No keyword matches found, looking for standalone amounts in bottom half");
      final bottomHalfStart = (lines.length * 0.5).round();
      
      for (int i = bottomHalfStart; i < lines.length; i++) {
        final lineText = lines[i].text.trim();
        String? amount = _extractAmountImproved(lineText);
        
        if (amount != null) {
          final amountValue = double.tryParse(amount);
          if (amountValue != null && amountValue > 0) {
            final positionScore = _calculatePositionScore(i, lines.length);
            final standaloneScore = _calculateStandaloneAmountScore(lineText, amountValue);
            
            if (positionScore + standaloneScore > 5) {
              print("Found standalone amount '$amount' (value: $amountValue) in bottom half");
              potentialTotals.add({
                'amount': amount,
                'index': i,
                'keyword': 'standalone_bottom',
                'priority': 3,
                'context_score': standaloneScore + positionScore,
                'source': 'standalone_bottom'
              });
            }
          }
        }
      }
    }
    
    // Fourth pass: Find largest amount in bottom third as last resort
    if (potentialTotals.isEmpty) {
      print("No matches found, using largest amount in bottom third as fallback");
      final bottomThirdStart = (lines.length * 0.67).round();
      double largestAmount = 0.0;
      String? largestAmountStr;
      
      for (int i = bottomThirdStart; i < lines.length; i++) {
        final lineText = lines[i].text.trim();
        String? amount = _extractAmountImproved(lineText);
        
        if (amount != null) {
          final amountValue = double.tryParse(amount);
          if (amountValue != null && amountValue > largestAmount && amountValue <= 10000) {
            largestAmount = amountValue;
            largestAmountStr = amount;
          }
        }
      }
      
      if (largestAmountStr != null) {
        print("Using largest amount in bottom third: '$largestAmountStr'");
        potentialTotals.add({
          'amount': largestAmountStr,
          'index': -1,
          'keyword': 'largest_bottom',
          'priority': 1,
          'context_score': 1.0,
          'source': 'largest_fallback'
        });
      }
    }

    if (potentialTotals.isEmpty) {
      print("No potential totals found at all");
      return null;
    }

    // Sort by combined score (priority + context score)
    potentialTotals.sort((a, b) {
      final aScore = (a['priority'] as int) + (a['context_score'] as double);
      final bScore = (b['priority'] as int) + (b['context_score'] as double);
      return bScore.compareTo(aScore); // Descending order
    });
    
    print("\nFinal candidates (sorted by score):");
    for (int i = 0; i < potentialTotals.length && i < 5; i++) {
      final candidate = potentialTotals[i];
      final score = (candidate['priority'] as int) + (candidate['context_score'] as double);
      print("  ${i+1}. Amount: '${candidate['amount']}', Keyword: '${candidate['keyword']}', Score: $score, Source: ${candidate['source']}");
    }
    
    final selectedAmount = potentialTotals.first['amount'] as String;
    print("Selected amount: '$selectedAmount'");
    print("=== OCR DEBUG: Amount extraction complete ===\n");

    return selectedAmount;
  }

  /// Calculates context score based on keyword relevance and amount characteristics
  double _calculateContextScore(String lineText, String keyword, double amount) {
    double score = 0.0;
    
    // Bonus for currency symbols
    if (lineText.contains(RegExp(r'[\$\u00a3\u20ac\u00a5\u20b9\u20bd]'))) {
      score += 2.0;
    }
    
    // Bonus for decimal places (typical for currency)
    if (amount.toString().contains('.') && amount.toString().split('.')[1].length <= 2) {
      score += 1.5;
    }
    
    // Bonus for reasonable total amounts
    if (amount >= 5.0 && amount <= 1000.0) {
      score += 2.0;
    } else if (amount >= 1.0 && amount <= 2000.0) {
      score += 1.0;
    }
    
    // Penalty for very small or very large amounts
    if (amount < 0.1 || amount > 10000) {
      score -= 3.0;
    }
    
    // Bonus for being at the end of line (common for totals)
    if (lineText.trim().endsWith(amount.toString())) {
      score += 1.0;
    }
    
    return score;
  }

  /// Calculates position score based on where the amount appears in the receipt
  double _calculatePositionScore(int lineIndex, int totalLines) {
    // Totals are usually in the bottom half of receipts
    final relativePosition = lineIndex / totalLines;
    
    if (relativePosition >= 0.7) {
      return 3.0; // Bottom 30%
    } else if (relativePosition >= 0.5) {
      return 2.0; // Middle-bottom
    } else if (relativePosition >= 0.3) {
      return 1.0; // Middle
    } else {
      return 0.0; // Top (unlikely for totals)
    }
  }

  /// Calculates score for standalone amounts that might be totals
  double _calculateStandaloneAmountScore(String lineText, double amount) {
    double score = 0.0;
    
    // Check if the line is mostly just the amount (indicating it's prominent)
    final textWithoutAmount = lineText.replaceAll(RegExp(r'[\d.,]+'), '').trim();
    if (textWithoutAmount.length <= 3) { // Just currency symbols or spaces
      score += 3.0;
    }
    
    // Bonus for currency formatting
    if (RegExp(r'^[\$\u00a3\u20ac\u00a5\u20b9\u20bd]?\s*\d+[.,]?\d*$').hasMatch(lineText.trim())) {
      score += 2.0;
    }
    
    // Bonus for typical total amounts
    if (amount >= 10.0 && amount <= 500.0) {
      score += 2.0;
    }
    
    return score;
  }

  /// Enhanced amount extraction with multiple patterns and better handling
  String? _extractAmountImproved(String text) {
    print("    Extracting amount from: '$text'");
    
    // Multiple regex patterns to handle various formats
    final patterns = [
      // Standard decimal numbers with currency symbols: $12.34, £45.67
      RegExp(r'[\$\u00a3\u20ac\u00a5\u20b9\u20bd]\s*(\d{1,4}(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
      // Numbers with spaces: 12 34, 12.34, 1 234.56
      RegExp(r'(\d{1,4}(?:[\s,]\d{3})*(?:[.,]\d{2})?)', caseSensitive: false),
      // Plain price formats: 12.34, 1,234.56
      RegExp(r'(\d{1,4}(?:,\d{3})*\.\d{2})', caseSensitive: false),
      // Whole numbers: 123, 1,234
      RegExp(r'(\d{1,4}(?:,\d{3})*)', caseSensitive: false),
      // Decimal with various separators: 12,34 or 12.34
      RegExp(r'(\d{1,4}[.,]\d{2})', caseSensitive: false),
      // Any sequence of digits with optional decimal
      RegExp(r'(\d+(?:[.,]\d{1,2})?)', caseSensitive: false),
    ];
    
    for (int i = 0; i < patterns.length; i++) {
      final matches = patterns[i].allMatches(text);
      if (matches.isNotEmpty) {
        for (final match in matches.toList().reversed) { // Try last match first (usually the total)
          final matchedText = match.group(1);
          if (matchedText != null) {
            String number = _normalizeNumber(matchedText);
            final value = double.tryParse(number);
            if (value != null && value > 0 && value <= 50000) {
              print("    Pattern ${i+1} matched: '$matchedText' -> normalized: '$number' -> value: $value");
              return number;
            }
          }
        }
      }
    }
    
    print("    No amount found in text");
    return null;
  }
  
  /// Normalizes a number string by handling different decimal/thousand separators
  String _normalizeNumber(String numberStr) {
    String normalized = numberStr.trim();
    
    // Remove any currency symbols or extra spaces
    normalized = normalized.replaceAll(RegExp(r'[^\d.,\s]'), '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), '');
    
    // Handle different separator formats
    final lastDot = normalized.lastIndexOf('.');
    final lastComma = normalized.lastIndexOf(',');
    
    if (lastDot > lastComma && lastDot != -1) {
      // Format: 1,234.56 (comma as thousands separator)
      normalized = normalized.replaceAll(',', '');
    } else if (lastComma > lastDot && lastComma != -1) {
      // Format: 1.234,56 (dot as thousands separator, comma as decimal)
      normalized = normalized.replaceAll('.', '');
      normalized = normalized.replaceAll(',', '.');
    } else if (normalized.contains(',') && !normalized.contains('.')) {
      // Format: 12,34 (comma as decimal separator)
      normalized = normalized.replaceAll(',', '.');
    } else if (normalized.contains('.') && !normalized.contains(',')) {
      // Format: 12.34 (dot as decimal separator) - already correct
    } else {
      // Remove all separators for whole numbers
      normalized = normalized.replaceAll(RegExp(r'[.,]'), '');
    }
    
    return normalized;
  }
  
}


img.Image thresholdImage(img.Image src, {int threshold = 128}) {
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      // Get the pixel which now is of type Pixel.
      var pixel = src.getPixel(x, y);
      // Access the red component of the pixel.
      num intensity = pixel.r; 
      
      // Set the pixel to white or black depending on the threshold.
      if (intensity > threshold) {
        // White color: 0xFFFFFFFF (ARGB format: fully opaque white).
        src.setPixel(x, y, 0xFFFFFFFF as img.Color);
      } else {
        // Black color: 0xFF000000 (ARGB format: fully opaque black).
        src.setPixel(x, y, 0xFF000000 as img.Color);
      }
    }
  }
  return src;
}