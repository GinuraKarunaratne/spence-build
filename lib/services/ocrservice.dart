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
  }

  /// Enhanced image preprocessing for better OCR performance.
  /// Steps:
  /// - Converts the image to grayscale.
  /// - Applies adaptive thresholding with noise reduction.
  /// - Enhances contrast and sharpness.
  /// - Optionally resizes for optimal OCR processing.
  /// Returns the file path of the processed image.
  Future<String> _preprocessImage(String imagePath) async {
    try {
      // Read the image file.
      final imageBytes = await File(imagePath).readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception("Could not decode image.");
      }

      // Resize image if it's too large or too small (optimal range: 600-1200px width)
      img.Image resizedImage = originalImage;
      if (originalImage.width < 600 || originalImage.width > 1200) {
        final targetWidth = originalImage.width < 600 ? 800 : 1000;
        final targetHeight = (originalImage.height * targetWidth / originalImage.width).round();
        resizedImage = img.copyResize(originalImage, width: targetWidth, height: targetHeight);
      }

      // Convert image to grayscale.
      img.Image grayscaleImage = img.grayscale(resizedImage);

      // Apply noise reduction using a simple blur
      img.Image blurredImage = img.convolution(grayscaleImage, 
        filter: [
          1, 1, 1,
          1, 2, 1,
          1, 1, 1
        ], 
        div: 10);

      // Enhance contrast using histogram stretching
      img.Image contrastImage = _enhanceContrast(blurredImage);

      // Apply adaptive thresholding instead of fixed threshold
      img.Image thresholdedImage = _adaptiveThreshold(contrastImage);

      // Apply sharpening filter to enhance text edges
      img.Image sharpenedImage = img.convolution(thresholdedImage, 
        filter: [
          0, -1, 0,
          -1, 5, -1,
          0, -1, 0
        ]);

      // Create a temporary file to save the processed image.
      final tempDir = Directory.systemTemp;
      final newFileName =
          "processed_${Random().nextInt(100000)}${path.extension(imagePath)}";
      final processedImagePath = path.join(tempDir.path, newFileName);

      // Encode the image (using PNG for lossless quality).
      final processedImageBytes = img.encodePng(sharpenedImage);
      final processedFile = File(processedImagePath);
      await processedFile.writeAsBytes(processedImageBytes);

      return processedImagePath;
    } catch (e) {
      print("Preprocessing Error: $e");
      rethrow;
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
    final startTime = DateTime.now();
    
    try {
      // Create a fresh text recognizer instance for this request
      textRecognizer = _getTextRecognizer();
      
      // Preprocess the image before OCR.
      final processedPath = await _preprocessImage(imagePath);
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
      // Always close the text recognizer after use to prevent resource leaks
      textRecognizer?.close();
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

  /// Extracts a title from the first block of text using a basic heuristic.
  /// The first non-empty, alphabetic line is chosen as the title.
  String? _extractTitle(List<TextBlock> blocks) {
    if (blocks.isEmpty) return null;
    final firstBlock = blocks.first;

    // Look for a line that is mainly alphabetic characters.
    for (final line in firstBlock.lines) {
      final text = line.text.trim();
      if (text.isNotEmpty &&
          text.length > 3 &&
          RegExp(r'^[a-zA-Z\s]+$').hasMatch(text)) {
        return text;
      }
    }
    // Fallback to the first non-empty line.
    return firstBlock.lines
        .firstWhere(
          (line) => line.text.trim().isNotEmpty,
          orElse: () => firstBlock.lines.first,
        )
        .text
        .trim();
  }

  /// Enhanced total amount extraction with improved keyword matching and context analysis
  String? _extractTotalAmount(List<TextLine> lines) {
    // Enhanced keyword list with priority scores
    const Map<String, int> totalKeywords = {
      'total': 10,
      'grand total': 15,
      'gross total': 15,
      'final total': 15,
      'total amount': 15,
      'total payable': 15,
      'amount due': 12,
      'balance due': 12,
      'net total': 10,
      'subtotal': 8,
      'gross amount': 8,
      'amount': 6,
      'balance': 5,
      'due': 5,
      'payable': 5,
      'gst total': 7,
      'tax total': 7,
      'grand': 4,
      'net': 4,
      'final': 4,
      'sum': 3,
      'bill': 3,
      'amt': 5,
      'tot': 5,
    };

    List<Map<String, dynamic>> potentialTotals = [];

    // First pass: Look for keyword-amount pairs in the same line
    for (int i = 0; i < lines.length; i++) {
      final lineText = lines[i].text.toLowerCase().trim();
      
      for (final entry in totalKeywords.entries) {
        final keyword = entry.key;
        final priority = entry.value;
        
        if (lineText.contains(keyword)) {
          // Extract amount from current line
          String? amount = _extractAmount(lineText);
          
          if (amount != null) {
            // Check if this amount makes sense contextually
            final amountValue = double.tryParse(amount);
            if (amountValue != null && amountValue > 0 && amountValue <= 50000) {
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
            String? nextAmount = _extractAmount(nextLineText);
            
            if (nextAmount != null) {
              final amountValue = double.tryParse(nextAmount);
              if (amountValue != null && amountValue > 0 && amountValue <= 50000) {
                potentialTotals.add({
                  'amount': nextAmount,
                  'index': i,
                  'keyword': keyword,
                  'priority': priority - 2, // Slight penalty for next line
                  'context_score': _calculateContextScore(nextLineText, keyword, amountValue),
                  'source': 'next_line'
                });
              }
            }
          }
        }
      }
    }

    // Second pass: Look for standalone amounts that might be totals
    if (potentialTotals.isEmpty) {
      for (int i = 0; i < lines.length; i++) {
        final lineText = lines[i].text.trim();
        String? amount = _extractAmount(lineText);
        
        if (amount != null) {
          final amountValue = double.tryParse(amount);
          if (amountValue != null && amountValue > 0) {
            // Check if this could be a total based on position and context
            final positionScore = _calculatePositionScore(i, lines.length);
            final standaloneScore = _calculateStandaloneAmountScore(lineText, amountValue);
            
            if (positionScore + standaloneScore > 5) {
              potentialTotals.add({
                'amount': amount,
                'index': i,
                'keyword': 'standalone',
                'priority': 2,
                'context_score': standaloneScore,
                'source': 'standalone'
              });
            }
          }
        }
      }
    }

    if (potentialTotals.isEmpty) return null;

    // Sort by combined score (priority + context score)
    potentialTotals.sort((a, b) {
      final aScore = (a['priority'] as int) + (a['context_score'] as double);
      final bScore = (b['priority'] as int) + (b['context_score'] as double);
      return bScore.compareTo(aScore); // Descending order
    });

    return potentialTotals.first['amount'];
  }

  /// Calculates context score based on keyword relevance and amount characteristics
  double _calculateContextScore(String lineText, String keyword, double amount) {
    double score = 0.0;
    
    // Bonus for currency symbols
    if (lineText.contains(RegExp(r'[\$£€¥₹₽]'))) {
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
    if (RegExp(r'^[\$£€¥₹₽]?\s*\d+[.,]?\d*$').hasMatch(lineText.trim())) {
      score += 2.0;
    }
    
    // Bonus for typical total amounts
    if (amount >= 10.0 && amount <= 500.0) {
      score += 2.0;
    }
    
    return score;
  }

  /// Uses a regular expression to extract a numerical value from [text].
  /// It handles potential currency symbols and different decimal/thousand separators.
  String? _extractAmount(String text) {
    final regex = RegExp(
      r'''((?:[\$£€¥₹₽]?\s*)?\d{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{1,2})?)''',
      caseSensitive: false,
    );
    final matches = regex.allMatches(text);
    if (matches.isEmpty) return null;
    final lastMatch = matches.last.group(1)!;
    String number = lastMatch.replaceAll(RegExp(r'[^\d.,]'), '');

    final lastDot = number.lastIndexOf('.');
    final lastComma = number.lastIndexOf(',');

    // Determine the grouping or decimal separator.
    if (lastDot > lastComma && lastDot != -1) {
      number = number.replaceAll(',', '');
    } else if (lastComma > lastDot && lastComma != -1) {
      number = number.replaceAll('.', '');
      number = number.replaceAll(',', '.');
    } else {
      number = number.replaceAll(RegExp(r'[.,]'), '');
    }
    return number;
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