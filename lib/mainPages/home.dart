import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:spence/buttons/imagerecordbutton.dart';
import 'package:spence/buttons/navigationbar.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/widgets/budgetdisplay.dart';
import 'package:spence/widgets/dailyexpenses.dart';
import 'package:spence/widgets/header.dart';
import '../otherPages/allexpenses.dart';
import './analysis.dart';
import './reports.dart';
import './recurring.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle; // Import for SystemUiOverlayStyle

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double spacingHeight;
    double budgetSpacing;
    double buttonSpacing;

    if (screenHeight > 800) {
      spacingHeight = 55.h;
      budgetSpacing = 40.h;
      buttonSpacing = 20.h;
    } else if (screenHeight < 600) {
      spacingHeight = 28.h;
      budgetSpacing = 30.h;
      buttonSpacing = 20.h;
    } else {
      spacingHeight = 70.h;
      budgetSpacing = 70.h;
      buttonSpacing = 20.h;
    }

    final Widget homeContent = Column(
      children: [
        const Header(),
        SizedBox(height: spacingHeight),
        const BudgetDisplay(),
        SizedBox(height: budgetSpacing),
        const DailyExpenses(),
        const Spacer(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 0.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageRecordButton(onPressed: () => _captureAndProcessImage(context)),
              SizedBox(width: screenWidth * 0.03.w),
              RecordExpenseButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/addexpense');
                },
              ),
            ],
          ),
        ),
        SizedBox(height: buttonSpacing),
      ],
    );

    final List<Widget> screens = [
      LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(child: homeContent),
            ),
          );
        },
      ),
      const AnalysisScreen(),
      const ReportsScreen(),
      const RecurringScreen(),
      const AllExpensesScreen(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Transparent status bar
        statusBarIconBrightness: Brightness.dark, // Dark icons for contrast
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        body: screens[_currentIndex],
        bottomNavigationBar: CustomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}