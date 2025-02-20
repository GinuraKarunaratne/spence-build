import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyBarWidget extends StatelessWidget {
  const DailyBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w),
          child: Text(
            " Daily Analysis",
            style: GoogleFonts.poppins(
              fontSize: 17.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: StreamBuilder<List<double>>(
              stream: _getDailyExpensesByHour(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SpinKitThreeBounce(
                      color: Color.fromARGB(255, 204, 242, 13),
                      size: 40.0,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data available'));
                } else {
                  final List<double> hourlyExpenses = snapshot.data!;
                  return _buildBarChart(hourlyExpenses);
                }
              },
            ),
          ),
        ),
        SizedBox(height: 40.h),
      ],
    );
  }

  Widget _buildBarChart(List<double> hourlyExpenses) {
    double maxExpense = hourlyExpenses.reduce((a, b) => a > b ? a : b);
    maxExpense = maxExpense > 0 ? maxExpense : 1; // Avoid division by zero

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: hourlyExpenses.map((expense) {
            double barHeight =
                (expense / maxExpense) * 145.h; // Scale bar height
            return expense == 0
                ? Container(
                    width: 9.w,
                    height: 9.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E6E6),
                      shape: BoxShape.circle,
                    ),
                  )
                : Container(
                    width: 9.w,
                    height: barHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60.r),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFCCF20D),
                          Color(0xFFBBE000),
                        ],
                      ),
                    ),
                  );
          }).toList(),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "00",
              style: GoogleFonts.poppins(
                fontSize: 9.sp,
                color: Colors.grey[600],
              ),
            ),
            Text(
              "12",
              style: GoogleFonts.poppins(
                fontSize: 9.sp,
                color: Colors.grey[600],
              ),
            ),
            Text(
              "23",
              style: GoogleFonts.poppins(
                fontSize: 9.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Stream<List<double>> _getDailyExpensesByHour() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value(List.filled(24, 0.0));
    }

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay =
        DateTime(today.year, today.month, today.day, 23, 59, 59, 999);

    return FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((querySnapshot) {
      final List<double> hourlyExpenses = List.filled(24, 0.0);

      for (var doc in querySnapshot.docs) {
        final expense = doc.data();
        final expenseAmount = expense['amount'] as double?;
        final expenseDate = expense['date'] as Timestamp?;

        if (expenseAmount != null && expenseDate != null) {
          final hour = expenseDate.toDate().hour;
          hourlyExpenses[hour] += expenseAmount;
        }
      }

      return hourlyExpenses;
    });
  }
}