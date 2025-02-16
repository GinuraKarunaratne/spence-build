import 'package:flutter/material.dart';
import 'package:spence/buttons/imagerecordbutton.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/widgets/header.dart';
import '../widgets/topexpense.dart';
import '../widgets/totalexpense.dart';
import '../widgets/piechart.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Stack(
        children: [
          Column(
            children: [
              Header(screenWidth: screenWidth),
              const SizedBox(height: 20),
              Expanded(
                child: Column(
                  children: const [
                    PieChartExpenses(),
                    SizedBox(height: 15),
                    TotalExpense(),
                    SizedBox(height: 15),
                    TopExpense(),
                  ],
                ),
              ),
              const SizedBox(height: 87),
            ],
          ),
          // Bottom control buttons
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ImageRecordButton(onPressed: () {}),
                const SizedBox(width: 11),
                RecordExpenseButton(onPressed: () {
                  Navigator.of(context).pushNamed('/addexpense');
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
