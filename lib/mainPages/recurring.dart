import 'package:flutter/material.dart';
import 'package:spence/buttons/recordbutton_alt.dart';
import 'package:spence/buttons/schedulebutton.dart';
import 'package:spence/widgets/header.dart';
import '../widgets/allrecurring.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

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
              const SizedBox(height: 45),
              const Expanded(
                child: AllRecurringWidget(),
              ),
              const SizedBox(height: 87),
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
                  RecordButton_alt(onPressed: () {
                    Navigator.of(context).pushNamed('/addexpense');
                  }),
                  const SizedBox(width: 11),
                  ScheduleButton(onPressed: () {
                    Navigator.of(context).pushNamed('/addrecurring');
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}