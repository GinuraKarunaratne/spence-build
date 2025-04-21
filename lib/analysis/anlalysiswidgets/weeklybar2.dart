import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class WeeklyBar2Widget extends StatelessWidget {
  const WeeklyBar2Widget({super.key, required List<double> weeklyExpenses});

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              stream: _getDailyExpenses(),
              builder: (BuildContext streamContext, snapshot) {
                final themeMode = Provider.of<ThemeProvider>(streamContext).themeMode;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SpinKitThreeBounce(
                      color: AppColors.accentColor[themeMode],
                      size: 40.0,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(
                        color: AppColors.errorColor[themeMode],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No data available',
                      style: GoogleFonts.poppins(
                        color: AppColors.secondaryTextColor[themeMode],
                      ),
                    ),
                  );
                }

                final List<double> dailyExpenses = snapshot.data!;
                return _buildBarChart(streamContext, dailyExpenses);
              },
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context, List<double> dailyExpenses) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    double maxExpense = dailyExpenses.isNotEmpty
        ? dailyExpenses.reduce((a, b) => a > b ? a : b)
        : 1;

    List<String> days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: dailyExpenses.asMap().entries.map((entry) {
            int index = entry.key;
            double expense = entry.value;
            double barHeight = (expense / maxExpense) * 145.h;

            return Column(
              children: [
                Container(
                  width: 34.w,
                  height: expense > 0 ? barHeight : 10.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60.r),
                    gradient: expense > 0
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.barColor[themeMode]!,
                              AppColors.barGradientEnd[themeMode]!,
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.customLightGray[themeMode]!,
                              AppColors.customLightGray[themeMode]!,
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  days[index],
                  style: GoogleFonts.poppins(
                    fontSize: 8.sp,
                    color: AppColors.logoutDialogCancelColor[themeMode],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Stream<List<double>> _getDailyExpenses() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(List.filled(7, 0.0));

    final now = DateTime.now();
    // Calculate Monday of current week with precise time boundaries
    final weekStart = DateTime.utc(
        now.year,
        now.month,
        now.day - (now.weekday - 1),
        0, 0, 0
    );
    final weekEnd = DateTime.utc(
        weekStart.year,
        weekStart.month,
        weekStart.day + 6,
        23, 59, 59, 999
    );

    return FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
        .snapshots()
        .map((querySnapshot) {
            List<double> dailyExpenses = List.filled(7, 0.0);
            
            for (var doc in querySnapshot.docs) {
                final expense = doc.data();
                final expenseAmount = expense['amount'] as double?;
                final expenseDate = (expense['date'] as Timestamp?)?.toDate();

                if (expenseAmount != null && expenseDate != null) {
                    int dayIndex = expenseDate.weekday - 1; // Monday = 0, Sunday = 6
                    if (dayIndex >= 0 && dayIndex < 7) {
                        dailyExpenses[dayIndex] += expenseAmount;
                    }
                }
            }
            return dailyExpenses;
        });
  }
}