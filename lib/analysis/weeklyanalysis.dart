import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spence/analysis/anlalysiswidgets/weeklybar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class WeeklyAnalysis extends StatefulWidget {
  const WeeklyAnalysis({super.key});

  @override
  State<WeeklyAnalysis> createState() => _WeeklyAnalysisState();
}

class _WeeklyAnalysisState extends State<WeeklyAnalysis> {
  late final Stream<List<double>> _weeklyExpensesStream;

  @override
  void initState() {
    super.initState();
    _weeklyExpensesStream = _getWeeklyExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 30.h),
            Expanded(
              child: StreamBuilder<List<double>>(
                stream: _weeklyExpensesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoading();
                  } else if (snapshot.hasError) {
                    return _buildErrorPage("Error: ${snapshot.error}");
                  } else if (!snapshot.hasData || snapshot.data!.every((value) => value == 0.0)) {
                    return _noExpensesMessage();
                  } else {
                    return WeeklyBarWidget(weeklyExpenses: snapshot.data!);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(25.w, 12.h, 0.w, 0.h),
            child: SvgPicture.asset(
              'assets/spence.svg',
              height: 14.h,
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(40.w, 12.h, 20.w, 0.h),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, size: 20.w, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: SpinKitThreeBounce(
        color: Color(0xFFCCF20D),
        size: 40.0,
      ),
    );
  }

  Widget _buildErrorPage(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60.w, color: Colors.red),
            SizedBox(height: 20.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noExpensesMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.summarize_rounded,
            size: 50.w,
            color: const Color.fromARGB(80, 149, 149, 149),
          ),
          SizedBox(height: 10.h),
          Text(
            'No expense record available',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF272727),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Record at least one expense to access the Analysis.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 9.sp,
              fontWeight: FontWeight.w400,
              color: const Color.fromARGB(80, 0, 0, 0),
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<double>> _getWeeklyExpenses() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value(List.filled(5, 0.0));
    }

    DateTime now = DateTime.now();
    DateTime startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
    startOfWeek.add(const Duration(days: 6));

    List<DateTime> weekStartDates = [];
    for (int i = 0; i < 5; i++) {
      weekStartDates.add(startOfWeek.subtract(Duration(days: i * 7)));
    }

    return FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((querySnapshot) {
      List<double> weeklyExpenses = List.filled(5, 0.0);

      for (var doc in querySnapshot.docs) {
        final expense = doc.data();
        final expenseAmount = expense['amount'] as double?;
        final expenseDate = expense['date'] as Timestamp?;

        if (expenseAmount != null && expenseDate != null) {
          DateTime date = expenseDate.toDate();
          for (int i = 0; i < 5; i++) {
            if (date.isAfter(weekStartDates[i]) && date.isBefore(weekStartDates[i].add(const Duration(days: 7)))) {
              weeklyExpenses[i] += expenseAmount;
              break;
            }
          }
        }
      }

      return weeklyExpenses;
    });
  }
}