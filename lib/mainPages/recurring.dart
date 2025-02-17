import 'package:flutter/material.dart';
import 'package:spence/buttons/recordbutton_alt.dart';
import 'package:spence/buttons/schedulebutton.dart';
import 'package:spence/widgets/header.dart';
import '../widgets/allrecurring.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Stack(
        children: [
          Column(
            children: [
              const Header(), 
              SizedBox(height: 35.h), 
              const Expanded(
                child: AllRecurringWidget(),
              ),
              SizedBox(height: 87.h),
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
                  RecordButton_alt(onPressed: () {
                    Navigator.of(context).pushNamed('/addexpense');
                  }),
                  SizedBox(width: 11.w),
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