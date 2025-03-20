import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class DailyBarWidget extends StatelessWidget {
  const DailyBarWidget({super.key});

  static const _padding = EdgeInsets.symmetric(horizontal: 25);
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _padding,
          child: Text(
            " Daily Analysis",
            style: GoogleFonts.poppins(
              fontSize: 17.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textColor[themeMode],
            ),
          ),
        ),
        SizedBox(height: 27.h),
        Padding(
          padding: _padding,
          child: Container(
            width: double.infinity,
            height: 240.h,
            padding: EdgeInsets.fromLTRB(16.w, 60.h, 16.w, 0),
            decoration: BoxDecoration(
              color: AppColors.whiteColor[themeMode],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: StreamBuilder<List<double>>(
              stream: _getDailyExpensesByHour(),
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
                }
                return _buildBarChart(streamContext, snapshot.data!);
              },
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context, List<double> hourlyExpenses) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    final maxExpense = hourlyExpenses.isNotEmpty ? hourlyExpenses.reduce((a, b) => a > b ? a : b) : 1;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: hourlyExpenses.map((expense) {
            final barHeight = (expense / (maxExpense == 0 ? 1 : maxExpense)) * 145.h;
            return Container(
              width: 9.w,
              height: expense == 0 ? 9.w : barHeight,
              decoration: BoxDecoration(
                color: expense == 0 ? AppColors.categoryButtonBackground[themeMode] : null,
                shape: expense == 0 ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: expense == 0 ? null : BorderRadius.circular(60.r),
                gradient: expense == 0
                    ? null
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.barColor[themeMode]!,
                          AppColors.barGradientEnd[themeMode]!,
                        ],
                      ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ["00", "12", "23"].map((label) {
            return Text(
              label,
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

  Stream<List<double>> _getDailyExpensesByHour() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(List.filled(24, 0.0));
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) {
      final expenses = List<double>.filled(24, 0.0);
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = data['amount'] as double?;
        final timestamp = data['date'] as Timestamp?;
        if (amount != null && timestamp != null) {
          expenses[timestamp.toDate().hour] += amount;
        }
      }
      return expenses;
    });
  }
}