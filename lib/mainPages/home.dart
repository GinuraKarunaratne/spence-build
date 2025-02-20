import 'package:flutter/material.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Define responsive spacing using ScreenUtil
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

    // Build the primary home screen content
    final Widget homeContent = Column(
      children: [
        const Header(),
        SizedBox(height: spacingHeight),
        const BudgetDisplay(),
        SizedBox(height: budgetSpacing),
        const DailyExpenses(),
        const Spacer(), // Pushes the buttons to the bottom when content overflows
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 0.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageRecordButton(onPressed: () {}),
              SizedBox(width: screenWidth * 0.03),
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

    // Wrap the content in a LayoutBuilder to conditionally scroll if needed
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

    return Scaffold(
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
    );
  }
}
