import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spence/analysis/monthlyanalysis.dart';
import 'package:spence/analysis/weeklyanalysis.dart';
import 'package:spence/buttons/imagerecordbutton.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/widgets/header.dart';
import 'package:spence/widgets/predictive.dart';
import 'package:spence/analysis/dailyanalysis.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(),
                SizedBox(height: 30.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: Text(
                    'Basic Analysis',
                    style: GoogleFonts.poppins(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSquareIcon(
                      icon: Icons.event_outlined,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const DailyAnalysis()),
                        );
                      },
                    ),
                    SizedBox(width: 12.w),
                    _buildSquareIcon(
                      icon: Icons.date_range_outlined,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const WeeklyAnalysis()),
                        );
                      },
                    ),
                    SizedBox(width: 12.w),
                    _buildSquareIcon(
                      icon: Icons.calendar_month_outlined,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const MonthlyAnalysis()),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                const Predictive(),
                SizedBox(height: 90.h), // Add padding to avoid overlap with buttons
              ],
            ),
          ),
          // Fixed buttons at the bottom
          Positioned(
            bottom: 20.h,
            left: 20.w,
            right: 20.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ImageRecordButton(onPressed: () {}),
                SizedBox(width: 11.w),
                RecordExpenseButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/addexpense');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareIcon({required IconData icon, VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 100.w,
        height: 100.h,
        decoration: BoxDecoration(
          color: const Color(0xFFEBEBEB),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 24.sp,
            color: const Color(0xFF1C1B1F),
          ),
        ),
      ),
    );
  }
}