import 'package:flutter/material.dart';
import 'package:spence/buttons/imagerecordbutton.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/widgets/header.dart'; // Import the Header widget

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
              Header(screenWidth: screenWidth), // Use the Header widget
              const SizedBox(height: 100),
              Expanded(child: Container()),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ImageRecordButton(onPressed: () {}),
                  const SizedBox(width: 11),
                  RecordExpenseButton(onPressed: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}