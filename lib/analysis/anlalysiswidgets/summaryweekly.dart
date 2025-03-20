import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class SummaryWeekly extends StatelessWidget {
  final double totalExpense;
  final String mostSpentCategory;
  final String mostSpentWeek;
  final double comparedToLastWeekPercent;
  final bool isIncrease;
  final String currency;

  const SummaryWeekly({
    super.key,
    required this.totalExpense,
    required this.mostSpentCategory,
    required this.mostSpentWeek,
    required this.comparedToLastWeekPercent,
    required this.isIncrease,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 349.w,
      child: Column(
        children: [
          _buildSummaryRow(
            context: context,
            label: 'Total Weekly Expense',
            value: '$currency ${totalExpense.toStringAsFixed(2)}',
          ),
          _buildSummaryRow(
            context: context,
            label: 'Most Spent Category',
            value: mostSpentCategory,
          ),
          _buildSummaryRow(
            context: context,
            label: 'Compared to Last Week',
            value: '${comparedToLastWeekPercent.toStringAsFixed(0)}%',
            showArrow: true,
            isIncrease: isIncrease,
          ),
          _buildSummaryRow(
            context: context,
            label: 'Most Spent Week',
            value: mostSpentWeek,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required BuildContext context,
    required String label,
    required String value,
    bool showArrow = false,
    bool isIncrease = false,
  }) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Container(
      margin: EdgeInsets.only(left: 25.w),
      width: double.infinity,
      height: 48.h,
      padding: EdgeInsets.all(10.h),
      decoration: BoxDecoration(color: AppColors.secondaryBackground[themeMode]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            color: AppColors.accentColor[themeMode],
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textColor[themeMode],
              ),
            ),
          ),
          // Value box
          Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            color: AppColors.budgetLabelBackground[themeMode],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.alttextColor[themeMode],
                  ),
                ),
                if (showArrow) ...[
                  SizedBox(width: 5.w),
                  Container(
                    width: 9.w,
                    height: 9.w,
                    color: isIncrease
                        ? AppColors.logoutButtonBackground[themeMode]
                        : AppColors.accentColor[themeMode], // Using accentColor for decrease
                    child: Icon(
                      isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 7.w,
                      color: AppColors.logoutButtonTextColor[themeMode],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}