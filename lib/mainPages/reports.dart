import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spence/buttons/imagerecordbutton.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/widgets/header.dart';
import 'package:spence/widgets/piechart.dart';
import 'package:spence/widgets/totalexpense.dart';
import 'package:spence/widgets/topexpense.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Stream<QuerySnapshot> _fetchExpenses() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Widget _buildExpensesList(String currencySymbol, double height) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fetchExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitThreeBounce(
              color: Color.fromARGB(255, 255, 255, 255),
              size: 40.0,
            ),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading expenses'));
        }
        final expenses = snapshot.data?.docs ?? [];
        if (expenses.isEmpty) {
          return Container(
            width: 288.w,
            height: height,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.summarize_rounded,
                  size: 50.w,
                  color: const Color.fromARGB(80, 149, 149, 149),
                ),
                const SizedBox(height: 10),
                Text(
                  'No expense record available',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF272727),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Record at least one expense to access the reports',
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
        // Wrap the list in a SingleChildScrollView so that it can scroll if needed
        return SingleChildScrollView(
          child: Column(
            children: [
              const PieChartExpenses(),
              SizedBox(height: 15.h),
              const TotalExpense(),
              SizedBox(height: 15.h),
              const TopExpense(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Stack(
        children: [
          Column(
            children: [
              const Header(),
              SizedBox(height: 20.h),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildExpensesList('', 700.h),
                ),
              ),
              SizedBox(height: 87.h),
            ],
          ),
          Positioned(
            bottom: 20.h,
            left: 20.w,
            right: 20.w,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 0.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ImageRecordButton(onPressed: () {}),
                  SizedBox(width: 11.w),
                  RecordExpenseButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/addexpense');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
