import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class ExpenseList extends StatelessWidget {
  final List<String> selectedCategories;
  final String selectedTimePeriod;
  const ExpenseList({
    super.key,
    required this.selectedCategories,
    required this.selectedTimePeriod,
  });

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
        final themeMode = Provider.of<ThemeProvider>(futureContext).themeMode;

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
              'Error loading currency symbol',
              style: GoogleFonts.poppins(
                color: AppColors.errorColor[themeMode],
              ),
            ),
          );
        }
        final currencySymbol = snapshot.data ?? 'Rs';
        return StreamBuilder<QuerySnapshot>(
          stream: _fetchExpenses(),
          builder: (BuildContext streamContext, snapshot) {
            final themeMode = Provider.of<ThemeProvider>(streamContext).themeMode;

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
                  'Error loading expenses',
                  style: GoogleFonts.poppins(
                    color: AppColors.errorColor[themeMode],
                  ),
                ),
              );
            }
            final expenses = snapshot.data?.docs ?? [];
            if (expenses.isEmpty) {
              return _buildEmptyExpensesMessage(streamContext);
            }
            // Filter expenses based on selected time period
            final filteredExpenses = _filterExpensesByTimePeriod(expenses);
            if (filteredExpenses.isEmpty) {
              return _buildEmptyExpensesMessage(streamContext);
            }
            return _buildExpenseListView(streamContext, filteredExpenses, currencySymbol);
          },
        );
      },
    );
  }

  Widget _buildEmptyExpensesMessage(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Container(
      width: 288.w,
      height: 350.h,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_rounded,
            size: 50.w,
            color: AppColors.disabledIconColor[themeMode],
          ),
          SizedBox(height: 10.h),
          Text(
            'No recorded expenses',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor[themeMode],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start recording an expense to see it here',
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

  Widget _buildExpenseListView(
      BuildContext context, List<QueryDocumentSnapshot> expenses, String currencySymbol) {
    double containerHeight = MediaQuery.of(context).size.height * 0.63;
    return SizedBox(
      width: 297.w,
      height: containerHeight.h,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          final title = expense['title'] ?? 'Unknown';
          final amount = '$currencySymbol ${expense['amount']?.toInt() ?? 0}';
          final category = expense['category'] ?? 'Unknown';
          if (selectedCategories.isEmpty ||
              selectedCategories.contains(category)) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _buildExpenseItem(context, title, amount),
            );
          }
          return Container();
        },
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterExpensesByTimePeriod(
      List<QueryDocumentSnapshot> expenses) {
    DateTime now = DateTime.now();
    if (selectedTimePeriod == 'Daily') {
      return expenses.where((expense) {
        DateTime expenseDate = (expense['date'] as Timestamp).toDate();
        return expenseDate.day == now.day &&
            expenseDate.month == now.month &&
            expenseDate.year == now.year;
      }).toList();
    } else if (selectedTimePeriod == 'Weekly') {
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return expenses.where((expense) {
        DateTime expenseDate = (expense['date'] as Timestamp).toDate();
        return expenseDate.isAfter(startOfWeek) && expenseDate.isBefore(now);
      }).toList();
    } else if (selectedTimePeriod == 'Monthly') {
      return expenses.where((expense) {
        DateTime expenseDate = (expense['date'] as Timestamp).toDate();
        return expenseDate.month == now.month && expenseDate.year == now.year;
      }).toList();
    }
    return expenses;
  }

  Widget _buildExpenseItem(BuildContext context, String title, String amount) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Container(
      width: double.infinity,
      height: 37.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground[themeMode],
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: AppColors.textColor[themeMode],
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: AppColors.accentColor[themeMode],
              borderRadius: BorderRadius.circular(6.w),
            ),
            child: Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
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
    return FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots();
  }
}