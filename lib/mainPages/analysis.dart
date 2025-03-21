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
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return Scaffold(
      body: Stack(
        children: [
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
                      color: AppColors.textColor[themeMode],
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSquareIcon(
                      themeMode: themeMode,
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
                      themeMode: themeMode,
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
                      themeMode: themeMode,
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
                SizedBox(height: 90.h),
              ],
            ),
          ),
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

  Widget _buildSquareIcon({
    required ThemeMode themeMode,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 100.w,
        height: 100.h,
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground[themeMode],
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 24.sp,
            color: AppColors.iconColor[themeMode],
          ),
        ),
      ),
    );
  }
}