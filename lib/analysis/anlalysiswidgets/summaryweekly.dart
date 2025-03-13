import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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
            label: 'Total Weekly Expense',
            value: '$currency ${totalExpense.toStringAsFixed(2)}',
          ),
          _buildSummaryRow(
            label: 'Most Spent Category',
            value: mostSpentCategory,
          ),
          _buildSummaryRow(
            label: 'Compared to Last Week',
            value: '${comparedToLastWeekPercent.toStringAsFixed(0)}%',
            showArrow: true,
            isIncrease: isIncrease,
          ),
          _buildSummaryRow(
            label: 'Most Spent Week',
            value: mostSpentWeek,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    bool showArrow = false,
    bool isIncrease = false,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 25.w),
      width: double.infinity,
      height: 48.h,
      padding: EdgeInsets.all(10.h),
      decoration: const BoxDecoration(color: Color(0xFFEBEBEB)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            color: const Color(0xFFCCF20D),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
          // Value box
          Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            color: const Color(0x26CCF20D),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                if (showArrow) ...[
                  SizedBox(width: 5.w),
                  Container(
                    width: 9.w,
                    height: 9.w,
                    color: isIncrease ? Colors.red : Colors.green,
                    child: Icon(
                      isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 7.w,
                      color: Colors.white,
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
