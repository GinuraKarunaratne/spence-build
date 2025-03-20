import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class SummaryMonthly extends StatelessWidget {
  final double totalExpense;
  final double highestExpense;
  final double comparedToLastMonthPercent;
  final bool isIncrease;
  final String currency;
  final double averageSpendPerDay;
  final String mostSpentDayOfWeek;

  const SummaryMonthly({
    super.key,
    required this.totalExpense,
    required this.highestExpense,
    required this.comparedToLastMonthPercent,
    required this.isIncrease,
    required this.currency,
    required this.averageSpendPerDay,
    required this.mostSpentDayOfWeek,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 349.w,
      child: Column(
        children: [
          _buildSummaryRow(
            context: context,
            label: 'Total Expense This Month',
            value: '$currency ${totalExpense.toStringAsFixed(2)}',
          ),
          _buildSummaryRow(
            context: context,
            label: 'Highest Expense',
            value: '$currency ${highestExpense.toStringAsFixed(2)}',
          ),
          _buildSummaryRow(
            context: context,
            label: 'Compared to Last Month',
            value: '${comparedToLastMonthPercent.toStringAsFixed(0)}%',
            showArrow: true,
            isIncrease: isIncrease,
          ),
          _buildSummaryRow(
            context: context,
            label: 'Average Spend Per Day',
            value: '$currency ${averageSpendPerDay.toStringAsFixed(2)}',
          ),
          _buildSummaryRow(
            context: context,
            label: 'Most Spent Day',
            value: mostSpentDayOfWeek,
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