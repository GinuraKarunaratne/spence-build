import 'package:flutter/material.dart';
import 'package:spence/buttons/imagerecordbutton.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/widgets/header.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart'; 

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Stack(
        children: [
          Column(
            children: [
              const Header(), 
              SizedBox(height: 100.h), 
              Expanded(child: Container()),
            ],
          ),
          Positioned(
            bottom: 20.h, 
            left: 20.w, 
            right: 20.w, 
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 0.w), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ImageRecordButton(onPressed: () {}),
                  SizedBox(width: 11.w), 
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