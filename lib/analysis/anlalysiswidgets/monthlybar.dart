import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class MonthlyBarWidget extends StatelessWidget {
  const MonthlyBarWidget({super.key, required List<double> expenses});

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w),
          child: Text(
            "Monthly Analysis",
            style: GoogleFonts.poppins(
              fontSize: 17.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textColor[themeMode],
            ),
          ),
        ),
        SizedBox(height: 27.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w),
          child: Container(
            width: double.infinity,
            height: 240.h,
            padding: EdgeInsets.fromLTRB(16.w, 60.h, 16.w, 0.h),
            decoration: BoxDecoration(
              color: AppColors.whiteColor[themeMode],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: StreamBuilder<List<double>>(
              stream: _getMonthlyExpenses(),
              builder: (BuildContext streamContext, snapshot) {
                final themeMode = Provider.of<ThemeProvider>(streamContext).themeMode;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SpinKitThreeBounce(
                      color: AppColors.accentColor[themeMode],
                      size: 40.0,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(
                        color: AppColors.errorColor[themeMode],
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No data available',
                      style: GoogleFonts.poppins(
                        color: AppColors.secondaryTextColor[themeMode],
                      ),
                    ),
                  );
                } else {
                  final List<double> monthlyExpenses = snapshot.data!;
                  return _buildBarChart(streamContext, monthlyExpenses);
                }
              },
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context, List<double> monthlyExpenses) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    double maxExpense = monthlyExpenses.reduce((a, b) => a > b ? a : b);
    maxExpense = maxExpense > 0 ? maxExpense : 1; // Avoid division by zero
    int currentMonth = DateTime.now().month - 1;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(12, (index) {
            double barHeight = (monthlyExpenses[index] / maxExpense) * 145.h;
            Color barColor = index == currentMonth
                ? Colors.transparent
                : AppColors.monthlyBarColor[themeMode]!;

            BoxDecoration decoration = index == currentMonth
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(60.r),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.barColor[themeMode]!,
                        AppColors.barGradientEnd[themeMode]!,
                      ],
                    ),
                  )
                : BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(60.r),
                  );

            return monthlyExpenses[index] == 0
                ? Container(
                    width: 19.w,
                    height: 19.w,
                    decoration: BoxDecoration(
                      color: AppColors.categoryButtonBackground[themeMode],
                      shape: BoxShape.circle,
                    ),
                  )
                : Container(
                    width: 19.w,
                    height: barHeight,
                    decoration: decoration,
                  );
          }),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
          ].map((month) {
            return Text(
              month,
              style: GoogleFonts.poppins(
                fontSize: 9.sp,
                color: AppColors.logoutDialogCancelColor[themeMode],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Stream<List<double>> _getMonthlyExpenses() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value(List.filled(12, 0.0));
    }

    final startOfYear = DateTime(DateTime.now().year, 1, 1);
    final endOfYear = DateTime(DateTime.now().year, 12, 31, 23, 59, 59, 999);

    return FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfYear)
        .where('date', isLessThanOrEqualTo: endOfYear)
        .snapshots()
        .map((querySnapshot) {
      final List<double> monthlyExpenses = List.filled(12, 0.0);

      for (var doc in querySnapshot.docs) {
        final expense = doc.data();
        final expenseAmount = expense['amount'] as double?;
        final expenseDate = expense['date'] as Timestamp?;

        if (expenseAmount != null && expenseDate != null) {
          final month = expenseDate.toDate().month - 1;
          monthlyExpenses[month] += expenseAmount;
        }
      }
      return monthlyExpenses;
    });
  }
}