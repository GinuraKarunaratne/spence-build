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
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

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

  Widget _buildExpensesList(String currencySymbol, double height, ThemeMode themeMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fetchExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitThreeBounce(
              color: AppColors.spinnerColor[themeMode],
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
            height: 570.h,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.summarize_rounded,
                  size: 50.w,
                  color: AppColors.disabledIconColor[themeMode],
                ),
                const SizedBox(height: 10),
                Text(
                  'No expense record available',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor[themeMode],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Record at least one expense to access the reports',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.disabledTextColor[themeMode],
                  ),
                ),
              ],
            ),
          );
        }
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: Stack(
        children: [
          Column(
            children: [
              const Header(),
              SizedBox(height: 20.h),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildExpensesList('', 700.h, themeMode),
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