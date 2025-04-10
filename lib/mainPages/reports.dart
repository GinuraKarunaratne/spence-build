import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spence/buttons/imagerecordbutton.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/widgets/header.dart';
import 'package:spence/widgets/piechart.dart';
import 'package:spence/widgets/totalexpense.dart';
import 'package:spence/widgets/topexpense.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  // Capture and process an image from the camera
  Future<void> _captureAndProcessImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final extractedData = await _processImage(image.path);
      if (extractedData != null) {
        Navigator.pushNamed(
          context,
          '/addexpense',
          arguments: {
            'initialTitle': extractedData['title'] ?? '',
            'initialAmount': extractedData['amount'] ?? '',
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn’t extract data from the bill')),
        );
      }
    }
  }

  // Process the image to extract text using Google ML Kit
  Future<Map<String, String>?> _processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    String? title;
    String? amount;

    if (recognizedText.blocks.isNotEmpty) {
      title = recognizedText.blocks.first.lines.first.text;
    }

    const totalKeywords = [
      'total',
      'gross total',
      'full amount',
      'amount due',
      'grand total',
    ];

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String lineText = line.text.toLowerCase();
        if (totalKeywords.any((keyword) => lineText.contains(keyword))) {
          amount = _extractAmount(line.text);
          if (amount != null) break;
        }
      }
      if (amount != null) break;
    }

    textRecognizer.close();
    return (title != null || amount != null) ? {'title': title ?? '', 'amount': amount ?? ''} : null;
  }

  // Extract the amount from text using a regex
  String? _extractAmount(String text) {
    final regex = RegExp(r'[\$£€]?\s*\d+(?:\.\d{1,2})?');
    final match = regex.firstMatch(text);
    return match?.group(0)?.replaceAll(RegExp(r'[^\d.]'), '');
  }

  // Fetch expenses from Firestore for the current user
  Stream<QuerySnapshot> _fetchExpenses() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // Build the content for expenses (charts and stats)
  Widget _buildExpensesContent(String currencySymbol, ThemeMode themeMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fetchExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitThreeBounce(
              color: AppColors.spinnerColor[themeMode],
              size: 40.0,
            ),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading expenses'));
        }
        final expenses = snapshot.data?.docs ?? [];
        if (expenses.isEmpty) {
          return Container(
            width: 288.w,
            height: 570.h,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.summarize_rounded,
                  size: 50.w,
                  color: AppColors.disabledIconColor[themeMode],
                ),
                const SizedBox(height: 10),
                Text(
                  'No expense record available',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor[themeMode],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Record at least one expense to access the reports',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.disabledTextColor[themeMode],
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            const PieChartExpenses(),
            SizedBox(height: 15.h),
            const TotalExpense(),
            SizedBox(height: 15.h),
            const TopExpense(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: Stack(
        children: [
          // Single scroll view for all content
          SingleChildScrollView(
            child: Column(
              children: [
                const Header(),
                SizedBox(height: 20.h),
                _buildExpensesContent('', themeMode),
                SizedBox(height: 87.h), // Space for bottom buttons
              ],
            ),
          ),
          // Bottom buttons positioned at the bottom
          Positioned(
            bottom: 20.h,
            left: 20.w,
            right: 20.w,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 0.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ImageRecordButton(onPressed: () => _captureAndProcessImage(context)),
                  SizedBox(width: 11.w),
                  RecordExpenseButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/addexpense');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}