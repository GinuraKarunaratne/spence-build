import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Ensure this import is added
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class DailyExpenses extends StatelessWidget {
  const DailyExpenses({super.key});

  Future<String?> _fetchCurrencySymbol() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return null;
    }

    final budgetDoc = await FirebaseFirestore.instance
        .collection('budgets')
        .doc(userId)
        .get();

    if (budgetDoc.exists) {
      final currency = budgetDoc['currency'] as String?;
      return currency;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _fetchCurrencySymbol(),
      builder: (BuildContext futureContext, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitThreeBounce(
              color: AppColors.accentColor[Provider.of<ThemeProvider>(futureContext).themeMode],
              size: 40.h, // Scaled size
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading currency symbol',
              style: GoogleFonts.poppins(
                color: AppColors.errorColor[Provider.of<ThemeProvider>(futureContext).themeMode],
                fontSize: 14.sp, // Scaled font size
              ),
            ),
          );
        }

        final currencySymbol = snapshot.data ?? 'Rs';

        return Column(
          children: [
            _buildExpenseContainer(context, currencySymbol),
          ],
        );
      },
    );
  }

  Widget _buildExpenseContainer(BuildContext context, String currencySymbol) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    final screenHeight = ScreenUtil().screenHeight; // Use ScreenUtil for consistency

    double containerHeight;
    double viewAllExpensesTop;
    double expensesListTop;
    double expensesListHeight;

    // Adjust heights based on screen height, scaled with .h
    if (screenHeight > 800.h) {
      containerHeight = 370.h;
      viewAllExpensesTop = 317.h;
      expensesListTop = 58.h;
      expensesListHeight = 252.h;
    } else if (screenHeight < 600.h) {
      containerHeight = 300.h;
      viewAllExpensesTop = 250.h;
      expensesListTop = 50.h;
      expensesListHeight = 200.h;
    } else {
      containerHeight = 305.h;
      viewAllExpensesTop = 252.h;
      expensesListTop = 45.h;
      expensesListHeight = 225.h;
    }

    return Container(
      width: 320.w, // Scaled width
      height: containerHeight, // Already scaled above
      decoration: BoxDecoration(
        color: AppColors.whiteColor[themeMode],
        borderRadius: BorderRadius.circular(18.r), // Scaled radius
      ),
      child: Stack(
        children: [
          Positioned(
            top: 24.h, // Scaled position
            left: 24.w, // Scaled position
            child: _buildTitle(context),
          ),
          Positioned(
            left: 16.w, // Scaled position
            top: expensesListTop, // Already scaled above
            child: _buildExpensesList(context, currencySymbol, expensesListHeight),
          ),
          Positioned(
            left: 16.w, // Scaled position
            top: viewAllExpensesTop, // Already scaled above
            child: _buildViewAllExpenses(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Text(
      'Expenses Today',
      style: GoogleFonts.poppins(
        fontSize: 11.sp, // Scaled font size
        fontWeight: FontWeight.w500,
        color: AppColors.textColor[themeMode],
      ),
    );
  }

  Widget _buildViewAllExpenses(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/allexpenses');
      },
      child: Container(
        width: 289.w, // Scaled width
        height: 37.h, // Scaled height
        padding: EdgeInsets.symmetric(horizontal: 12.w), // Scaled padding
        decoration: BoxDecoration(
          color: AppColors.accentColor[themeMode],
          borderRadius: BorderRadius.circular(11.r), // Scaled radius
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'View All Expenses',
              style: GoogleFonts.poppins(
                fontSize: 11.sp, // Scaled font size
                color: AppColors.textColor[themeMode],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13.w, // Scaled icon size
              color: AppColors.secondaryTextColor[themeMode],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context, String currencySymbol, double height) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fetchExpenses(),
      builder: (BuildContext streamContext, snapshot) {
        final themeMode = Provider.of<ThemeProvider>(streamContext).themeMode;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitThreeBounce(
              color: AppColors.spinnerColor[themeMode],
              size: 40.h, // Scaled size
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading expenses',
              style: GoogleFonts.poppins(
                color: AppColors.errorColor[themeMode],
                fontSize: 14.sp, // Scaled font size
              ),
            ),
          );
        }

        final expenses = snapshot.data?.docs ?? [];
        if (expenses.isEmpty) {
          return Container(
            width: 288.w, // Scaled width
            height: height, // Already scaled
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pending_actions_rounded,
                  size: 50.w, // Scaled icon size
                  color: AppColors.disabledIconColor[themeMode],
                ),
                SizedBox(height: 10.h), // Scaled spacing
                Text(
                  'No expenses recorded today',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp, // Scaled font size
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor[themeMode],
                  ),
                ),
                SizedBox(height: 8.h), // Scaled spacing
                Text(
                  'Start recording your expenses to see them here',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp, // Scaled font size
                    fontWeight: FontWeight.w400,
                    color: AppColors.disabledTextColor[themeMode],
                  ),
                ),
              ],
            ),
          );
        }

        // List of Expenses
        return Container(
          width: 288.w, // Scaled width
          height: height, // Already scaled
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r), // Scaled radius
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final title = expense['title'] ?? 'Unknown';
              final amount = '$currencySymbol ${expense['amount']?.toInt() ?? 0}';

              return Padding(
                padding: EdgeInsets.only(bottom: 7.h), // Scaled padding
                child: _buildExpenseItem(context, title, amount),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExpenseItem(BuildContext context, String title, String amount) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Container(
      width: double.infinity,
      height: 37.h, // Scaled height
      padding: EdgeInsets.symmetric(horizontal: 10.w), // Scaled padding
      decoration: BoxDecoration(
        color: AppColors.primaryBackground[themeMode],
        borderRadius: BorderRadius.circular(12.r), // Scaled radius
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: AppColors.textColor[themeMode],
              fontSize: 12.sp, // Scaled font size
              fontWeight: FontWeight.w400,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h), // Scaled padding
            decoration: BoxDecoration(
              color: AppColors.accentColor[themeMode],
              borderRadius: BorderRadius.circular(6.r), // Scaled radius
            ),
            child: Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 10.sp, // Scaled font size
                color: AppColors.textColor[themeMode],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _fetchExpenses() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day, 0, 0, 0);
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(todayEnd))
        .snapshots();
  }
}