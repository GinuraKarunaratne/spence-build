import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spence/analysis/anlalysiswidgets/monthlybar.dart';

class MonthlyAnalysis extends StatefulWidget {
  const MonthlyAnalysis({super.key});

  @override
  State<MonthlyAnalysis> createState() => _MonthlyAnalysisState();
}

class _MonthlyAnalysisState extends State<MonthlyAnalysis> {
  Stream<List<double>>? _monthlyExpensesStream;

  @override
  void initState() {
    super.initState();
    _monthlyExpensesStream = _getMonthlyExpenses();
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
                stream: _monthlyExpensesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoading();
                  } else if (snapshot.hasError) {
                    return _buildErrorPage("Error: ${snapshot.error}");
                  } else if (!snapshot.hasData || snapshot.data!.every((value) => value == 0.0)) {
                    return _noExpensesMessage();
                  } else {
                    return _buildGraph(snapshot.data!);
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
            padding: EdgeInsets.fromLTRB(25.w, 12.h, 0, 0),
            child: SvgPicture.asset(
              'assets/spence.svg',
              height: 14.h,
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(40.w, 12.h, 20.w, 0),
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

  Widget _buildGraph(List<double> monthlyExpenses) {
    return MonthlyBarWidget(expenses: monthlyExpenses);
  }

  Stream<List<double>> _getMonthlyExpenses() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value(List.filled(12, 0.0));
    }

    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59, 999);

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