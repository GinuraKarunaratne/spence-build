import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Custom ScrollPhysics to reduce bounce effect
class LessBounceScrollPhysics extends BouncingScrollPhysics {
  const LessBounceScrollPhysics({super.parent});

  @override
  double frictionFactor(double overscrollFraction) {
    return 0;
  }

  @override
  LessBounceScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return LessBounceScrollPhysics(parent: buildParent(ancestor));
  }
}

class MonthlyBar2Widget extends StatefulWidget {
  const MonthlyBar2Widget({super.key, required List<double> expenses});

  @override
  State<MonthlyBar2Widget> createState() => _MonthlyBar2WidgetState();
}

class _MonthlyBar2WidgetState extends State<MonthlyBar2Widget> {
  final ScrollController _scrollController = ScrollController();
  bool _hasAnimatedScroll = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w),
          child: Container(
            width: double.infinity,
            height: 240.h,
            padding: EdgeInsets.fromLTRB(16.w, 60.h, 16.w, 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: StreamBuilder<List<double>>(
              stream: _getMonthlyExpenses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SpinKitThreeBounce(
                      color: Color.fromARGB(255, 204, 242, 13),
                      size: 40.0,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data available'));
                }

                final List<double> dailyExpenses = snapshot.data!;
                return _buildBarChart(dailyExpenses);
              },
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildBarChart(List<double> dailyExpenses) {
    // Determine the max expense for scaling the bar heights
    double maxExpense = dailyExpenses.isNotEmpty
        ? dailyExpenses.reduce((a, b) => a > b ? a : b)
        : 1;

    // Build the bar chart as a horizontally scrollable view
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        return false;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const LessBounceScrollPhysics(), // less bounce effect
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: dailyExpenses.asMap().entries.map((entry) {
            int index = entry.key; // zero-based index
            double expense = entry.value;
            double barHeight = (expense / maxExpense) * 145.h;
            int dayNumber = index + 1; // Actual day of the month (1-based)

            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bar itself
                  Container(
                    width: 10.w,
                    height: expense > 0 ? barHeight : 10.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60.r),
                      // Gradient for non-zero expense, gray for zero
                      gradient: expense > 0
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFCCF20D),
                                Color(0xFFBBE000),
                              ],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFE0E0E0), Color(0xFFE0E0E0)],
                            ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Day label
                  Text(
                    '$dayNumber',
                    style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Fetch monthly expenses for each day of the current month
  Stream<List<double>> _getMonthlyExpenses() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    final now = DateTime.now();
    // Get first and last day of current month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));

    // Calculate how many days in the current month
    int daysInMonth = lastDayOfMonth.day;

    // Prepare a list with zero for each day
    List<double> dailyExpenses = List.filled(daysInMonth, 0.0);

    return FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: firstDayOfMonth)
        .where('date', isLessThanOrEqualTo: lastDayOfMonth)
        .snapshots()
        .map((querySnapshot) {
      // Reset each time to avoid accumulation across snapshot updates
      dailyExpenses = List.filled(daysInMonth, 0.0);

      for (var doc in querySnapshot.docs) {
        final expenseData = doc.data();
        final expenseAmount = expenseData['amount'] as double?;
        final expenseDate = (expenseData['date'] as Timestamp?)?.toDate();

        if (expenseAmount != null && expenseDate != null) {
          int dayIndex = expenseDate.day - 1; // zero-based
          dailyExpenses[dayIndex] += expenseAmount;
        }
      }

      // Once data is set, schedule the scroll to current day (only once)
      if (!_hasAnimatedScroll) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrentDay(dailyExpenses.length);
        });
      }

      return dailyExpenses;
    });
  }

  /// Scroll so that today's bar is centered
  void _scrollToCurrentDay(int daysInMonth) {
    _hasAnimatedScroll = true;
    final now = DateTime.now();
    // dayIndex is zero-based
    int currentDayIndex = now.day - 1;
    double barWidth = 18.w;
    double spacing = 8.w;
    double barBlockWidth = barWidth + spacing;
    double offset = currentDayIndex * barBlockWidth;
    double approximateContainerWidth = 240.w - 32.w; 
    double centerOffset = offset - (approximateContainerWidth / 2) + (barWidth / 2);
    double totalWidth = daysInMonth * barBlockWidth;
    double finalOffset = centerOffset.clamp(0, totalWidth);

    _scrollController.animateTo(
      finalOffset,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
    );
  }
}
