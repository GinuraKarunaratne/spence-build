import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spence/buttons/imagerecordbutton.dart';
import 'package:spence/buttons/recordbutton.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Stack(
        children: [
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
                  padding: const EdgeInsets.fromLTRB(0, 12, 23, 0),
                  child: SvgPicture.asset(
                    'assets/light.svg',
                    height: 38,
                  ),
                ),
              ],
                ),
              ),
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
