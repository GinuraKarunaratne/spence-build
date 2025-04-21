import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class WeeklyBarWidget extends StatelessWidget {
  const WeeklyBarWidget({super.key, required List<double> weeklyExpenses});

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w),
          child: Text(
            " Weekly Analysis",
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
              stream: _getWeeklyExpensesByWeek(),
              builder: (BuildContext streamContext, snapshot) {
                final themeMode =
                    Provider.of<ThemeProvider>(streamContext).themeMode;

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

                final List<double> weeklyExpenses = snapshot.data!;
                return _buildBarChart(streamContext, weeklyExpenses);
              },
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context, List<double> weeklyExpenses) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    double maxExpense = weeklyExpenses.isNotEmpty
        ? weeklyExpenses.reduce((a, b) => a > b ? a : b)
        : 1;

    int activeWeekIndex = _getCurrentWeekIndex();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weeklyExpenses.asMap().entries.map((entry) {
            int index = entry.key;
            double expense = entry.value;
            double barHeight = (expense / maxExpense) * 145.h;

            return _buildBar(
                expense, barHeight, index, activeWeekIndex, themeMode);
          }).toList(),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                "Week ${index + 1}",
                style: GoogleFonts.poppins(
                  fontSize: 8.sp,
                  color: AppColors.logoutDialogCancelColor[themeMode],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBar(
    double expense,
    double barHeight,
    int index,
    int activeWeekIndex,
    ThemeMode themeMode,
  ) {
    bool isCurrentWeek = index == activeWeekIndex;

    return expense == 0
        ? Container(
            width: 49.w,
            height: 21.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60.r),
              color: AppColors.categoryButtonBackground[themeMode],
            ),
          )
        : Container(
            width: 49.w,
            height: barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60.r),
              gradient: isCurrentWeek
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
                        AppColors.monthlyBarColor[themeMode]!,
                        AppColors.monthlyBarColor[themeMode]!,
                      ],
                    ),
            ),
          );
  }

  Stream<List<double>> _getWeeklyExpensesByWeek() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(List.filled(5, 0.0));

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    
    // Calculate first and last day of month with inclusive boundaries
    final firstDayOfMonth = DateTime.utc(currentYear, currentMonth, 1, 0, 0, 0);
    final lastDayOfMonth = DateTime.utc(currentYear, currentMonth + 1, 0, 23, 59, 59, 999);

    // Create week boundaries based on calendar weeks
    List<Map<String, DateTime>> weeks = [];
    DateTime weekStart = firstDayOfMonth;
    
    // Find the first Monday if the month doesn't start on Monday
    if (weekStart.weekday != DateTime.monday) {
      // If month starts mid-week, count that partial week as Week 1
      DateTime weekEnd = DateTime(weekStart.year, weekStart.month, 
                       weekStart.day + (7 - weekStart.weekday), 23, 59, 59, 999);
      weeks.add({
        'start': weekStart,
        'end': weekEnd,
      });
      // Move weekStart to next Monday
      weekStart = DateTime(weekStart.year, weekStart.month, 
                         weekStart.day + (8 - weekStart.weekday), 0, 0, 0);
    }
    
    // Add remaining weeks
    while (weekStart.month == currentMonth) {
      DateTime weekEnd = weekStart.add(const Duration(days: 6));
      // Adjust if week extends into next month
      if (weekEnd.month != currentMonth) {
        weekEnd = lastDayOfMonth;
      } else {
        weekEnd = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59, 999);
      }
      weeks.add({
        'start': weekStart,
        'end': weekEnd,
      });
      weekStart = weekEnd.add(const Duration(days: 1));
      weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day, 0, 0, 0);
    }

    // Ensure we have 5 weeks (pad with empty weeks if needed)
    while (weeks.length < 5) {
      weeks.add({
        'start': lastDayOfMonth,
        'end': lastDayOfMonth,
      });
    }

    return FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
        .snapshots()
        .map((querySnapshot) {
            List<double> weeklyExpenses = List.filled(5, 0.0);
            
            for (var doc in querySnapshot.docs) {
                final expense = doc.data();
                final expenseAmount = expense['amount'] as double?;
                final expenseDate = (expense['date'] as Timestamp?)?.toDate();
                
                if (expenseAmount != null && expenseDate != null) {
                    for (int i = 0; i < weeks.length; i++) {
                        if (expenseDate.isAtSameMomentAs(weeks[i]['start']!) || 
                            (expenseDate.isAfter(weeks[i]['start']!) && 
                             expenseDate.isBefore(weeks[i]['end']!)) ||
                            expenseDate.isAtSameMomentAs(weeks[i]['end']!)) {
                            weeklyExpenses[i] += expenseAmount;
                            break;
                        }
                    }
                }
            }
            return weeklyExpenses;
        });
  }

  int _getCurrentWeekIndex() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    // If month starts mid-week, that partial week is Week 1
    if (firstDayOfMonth.weekday != DateTime.monday) {
      // Calculate days since start of month, accounting for partial first week
      int daysSinceStart = now.day - 1;
      int daysInFirstWeek = 8 - firstDayOfMonth.weekday;
      
      if (daysSinceStart < daysInFirstWeek) {
        return 0; // Still in first (partial) week
      }
      
      // Adjust calculation for remaining weeks
      daysSinceStart -= daysInFirstWeek;
      return (daysSinceStart ~/ 7 + 1).clamp(0, 4);
    }
    
    // If month starts on Monday, simple calculation
    return ((now.day - 1) ~/ 7).clamp(0, 4);
  }
}