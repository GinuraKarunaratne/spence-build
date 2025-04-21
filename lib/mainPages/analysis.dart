import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:spence/analysis/monthlyanalysis.dart';
import 'package:spence/analysis/weeklyanalysis.dart';
import 'package:spence/buttons/imagerecordbutton.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/widgets/header.dart';
import 'package:spence/widgets/predictive.dart';
import 'package:spence/analysis/dailyanalysis.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

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
          const SnackBar(content: Text('Couldn\'t extract data from the bill')),
        );
      }
    }
  }

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

  String? _extractAmount(String text) {
    final regex = RegExp(r'[\$£€]?\s*\d+(?:\.\d{1,2})?');
    final match = regex.firstMatch(text);
    return match?.group(0)?.replaceAll(RegExp(r'[^\d.]'), '');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: Stack(
        children: [
          Column(
            children: [
              const Header(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 30.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30.w),
                        child: Text(
                          'Basic Analysis',
                          style: GoogleFonts.poppins(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textColor[themeMode],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSquareIcon(
                            themeMode: themeMode,
                            icon: Icons.event_outlined,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const DailyAnalysis()),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          _buildSquareIcon(
                            themeMode: themeMode,
                            icon: Icons.date_range_outlined,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const WeeklyAnalysis()),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          _buildSquareIcon(
                            themeMode: themeMode,
                            icon: Icons.calendar_month_outlined,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const MonthlyAnalysis()),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      const Predictive(),
                      SizedBox(height: 87.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20.h,
            left: 20.w,
            right: 20.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ImageRecordButton(onPressed: () => _captureAndProcessImage(context)),
                SizedBox(width: 11.w),
                RecordExpenseButton(
                  onPressed: () => Navigator.of(context).pushNamed('/addexpense'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareIcon({
    required ThemeMode themeMode,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 100.w,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground[themeMode],
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 24.sp,
            color: AppColors.iconColor[themeMode],
          ),
        ),
      ),
    );
  }
}