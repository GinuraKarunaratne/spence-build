import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spence/buttons/imagerecordbutton.dart';
import 'package:spence/buttons/navigationbar.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/widgets/budgetdisplay.dart';
import 'package:spence/widgets/dailyexpenses.dart';

import '../otherPages/allexpenses.dart';
import './analysis.dart';
import './reports.dart';
import './recurring.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Adjust spacing based on screen size
    double spacingHeight = screenHeight > 800 ? 55 : 28; 
    double budgetSpacing = screenHeight > 800 ? 40 : 30; 
    double buttonSpacing = screenHeight > 800 ? 20 : 20;

    final List<Widget> screens = [
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 12, 0, 0),
                  child: SvgPicture.asset(
                    'assets/spence.svg',
                    height: 14,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 12, screenWidth * 0.06, 0),
                  child: SvgPicture.asset(
                    'assets/light.svg',
                    height: 38,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacingHeight), 
          const BudgetDisplay(),
          SizedBox(height: budgetSpacing),
          const DailyExpenses(),
          Spacer(), // Ensures that the buttons are pushed to the bottom
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ImageRecordButton(onPressed: () {}),
                SizedBox(width: screenWidth * 0.03),
                RecordExpenseButton(onPressed: () {
                  Navigator.of(context).pushNamed('/addexpense');
                }),
              ],
            ),
          ),
          SizedBox(height: buttonSpacing), // Adjust spacing below buttons
        ],
      ),
      const AnalysisScreen(),
      const ReportsScreen(),
      const RecurringScreen(),
      const AllExpensesScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: screens[_currentIndex], // Ensure we're accessing a valid screen

      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex, // Ensure valid currentIndex (0 to 3)
        onTap: (int index) {
          setState(() {
            if (index >= 0 && index < 4) {  // Ensure the index is within valid range
              _currentIndex = index;
            }
          });
        },
      ),
    );
  }
}
