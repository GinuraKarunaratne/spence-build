import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WeeklyBar2Widget extends StatelessWidget {
  const WeeklyBar2Widget({super.key, required List<double> weeklyExpenses});

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
            padding: EdgeInsets.fromLTRB(16.w, 60.h, 16.w, 0.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: StreamBuilder<List<double>>(
              stream: _getDailyExpenses(),
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
                  return Center(child: Text('Error: \${snapshot.error}'));
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
                  height: barHeight > 0
                      ? barHeight
                      : 10.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60.r),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFCCF20D),
                        Color(0xFFBBE000),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  days[index],
                  style: GoogleFonts.poppins(
                    fontSize: 8.sp, // Reduced font size for day names
                    color: Colors.grey[600],
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
    final weekStart =
        now.subtract(Duration(days: now.weekday - 1)); // Monday start

    List<double> dailyExpenses = List.filled(7, 0.0);

    return FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: weekStart)
        .snapshots()
        .map((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        final expense = doc.data();
        final expenseAmount = expense['amount'] as double?;
        final expenseDate = (expense['date'] as Timestamp?)?.toDate();

        if (expenseAmount != null && expenseDate != null) {
          int dayIndex = expenseDate.weekday - 1; // Monday is index 0
          dailyExpenses[dayIndex] += expenseAmount;
        }
      }
      return dailyExpenses;
    });
  }
}
