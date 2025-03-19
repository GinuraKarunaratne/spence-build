import 'dart:io';
import 'dart:math';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class OcrService {
  final TextRecognizer _textRecognizer;

  /// Initializes the text recognizer using the default Latin script options.
  OcrService() : _textRecognizer = GoogleMlKit.vision.textRecognizer();

  /// Closes the text recognizer to free up resources.
  void dispose() {
    _textRecognizer.close();
  }

  /// Preprocesses the image for better OCR performance.
  /// Steps:
  /// - Converts the image to grayscale.
  /// - Applies thresholding to binarize the image.
  /// Returns the file path of the processed image.
  Future<String> _preprocessImage(String imagePath) async {
    try {
      // Read the image file.
      final imageBytes = await File(imagePath).readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception("Could not decode image.");
      }

      // Convert image to grayscale.
      img.Image grayscaleImage = img.grayscale(originalImage);

      // Apply thresholding for binarization using the custom thresholdImage function.
      img.Image thresholdedImage =
          thresholdImage(grayscaleImage, threshold: 128);

      // Create a temporary file to save the processed image.
      final tempDir = Directory.systemTemp;
      final newFileName =
          "processed_${Random().nextInt(100000)}${path.extension(imagePath)}";
      final processedImagePath = path.join(tempDir.path, newFileName);

      // Encode the image (using PNG for lossless quality).
      final processedImageBytes = img.encodePng(thresholdedImage);
      final processedFile = File(processedImagePath);
      await processedFile.writeAsBytes(processedImageBytes);

      return processedImagePath;
    } catch (e) {
      print("Preprocessing Error: $e");
      rethrow;
    }
  }

  /// Processes the image at [imagePath] and returns a map containing the extracted 'title' and 'amount'.
  /// The method first preprocesses the image to improve OCR accuracy.
  Future<Map<String, String>?> processImage(String imagePath) async {
    try {
      // Preprocess the image before OCR.
      final processedPath = await _preprocessImage(imagePath);
      final inputImage = InputImage.fromFilePath(processedPath);

      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final blocks = recognizedText.blocks.toList();
      final lines = blocks.expand((block) => block.lines).toList();

      // Extract heading from the first block.
      String? title = _extractTitle(blocks);

      // Extract total amount using enhanced keyword matching.
      String? amount = _extractTotalAmount(lines);

      return {
        'title': title ?? '',
        'amount': amount ?? '',
      };
    } catch (e) {
      print("OCR Processing Error: $e");
      return null;
    }
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

  /// Searches through the text lines for keywords and extracts the total amount.
  /// The method first looks for lines containing receipt total keywords, then attempts to extract a number.
  String? _extractTotalAmount(List<TextLine> lines) {
    const totalKeywords = [
      'total',
      'gross total',
      'gross amount',
      'amount',
      'balance',
      'due',
      'payable',
      'gst',
      'grand',
      'net',
      'final',
      'sum',
      'bill',
      'amt',
      'tot',
      'subtotal',
      'final total',
      'amount due',
      'total payable',
    ];

    List<Map<String, dynamic>> potentialTotals = [];

    for (int i = 0; i < lines.length; i++) {
      final lineText = lines[i].text.toLowerCase().trim();
      if (totalKeywords.any((keyword) => lineText.contains(keyword))) {
        // Try to extract an amount from the current line.
        String? amount = _extractAmount(lineText);
        // If no amount is found, try the next line if available.
        if (amount == null && i + 1 < lines.length) {
          amount = _extractAmount(lines[i + 1].text.trim());
        }
        if (amount != null) {
          potentialTotals.add({
            'amount': amount,
            'index': i,
            'keyword': totalKeywords.firstWhere((kw) => lineText.contains(kw)),
          });
        }
      }
    }

    if (potentialTotals.isEmpty) return null;

    // Sort to prioritize occurrences with priority keywords like "total" or "grand".
    potentialTotals.sort((a, b) {
      if (a['index'] == b['index']) {
        final aPriority = (a['keyword'] as String).contains('total') ||
            (a['keyword'] as String).contains('grand');
        final bPriority = (b['keyword'] as String).contains('total') ||
            (b['keyword'] as String).contains('grand');
        if (aPriority && !bPriority) return -1;
        if (!aPriority && bPriority) return 1;
      }
      return a['index'].compareTo(b['index']);
    });

    return potentialTotals.first['amount'];
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