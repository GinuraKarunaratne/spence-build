import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spence/buttons/intervalbutton.dart';
import 'package:spence/buttons/schedulebutton.dart';
import 'package:spence/widgets/budgetdisplay.dart';
import 'package:loading_indicator/loading_indicator.dart';
import '../forms/recurringform.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

bool isSameOrBeforeDay(DateTime a, DateTime b) {
  final dA = DateTime(a.year, a.month, a.day);
  final dB = DateTime(b.year, b.month, b.day);
  return dA.isBefore(dB) || dA.isAtSameMomentAs(dB);
}

DateTime calculateInitialNextDate(DateTime chosenDate, int intervalMonths) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  var nextDate = DateTime(chosenDate.year, chosenDate.month, chosenDate.day);
  while (nextDate.isBefore(todayDate)) {
    nextDate =
        DateTime(nextDate.year, nextDate.month + intervalMonths, nextDate.day);
  }
  return nextDate;
}

class AddRecurringScreen extends StatefulWidget {
  const AddRecurringScreen({super.key});

  @override
  _AddRecurringScreenState createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<AddRecurringScreen> {
  String recurringTitle = '';
  String recurringAmount = '';
  String recurringCategory = 'Food & Grocery';
  DateTime recurringDate = DateTime.now();
  int repeatIntervalMonths = 1;
  bool _isLoading = false;
  List<String> selectedCategories = [];

  void _updateFormData({
    String? title,
    String? amount,
    String? category,
    DateTime? date,
    String? repeatInterval,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          if (title != null) recurringTitle = title;
          if (amount != null) recurringAmount = amount;
          if (category != null) recurringCategory = category;
          if (date != null) recurringDate = date;
          if (repeatInterval != null) {
            repeatIntervalMonths = _parseInterval(repeatInterval);
          }
        });
      }
    });
  }

  int _parseInterval(String interval) {
    return int.parse(interval.split(' ').first);
  }

  Future<void> _submitRecurringExpense() async {
    if (recurringTitle.isEmpty || recurringAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      setState(() => _isLoading = false);
      return;
    }
    try {
      final recurringAmountValue = double.parse(recurringAmount);
      var nextDate =
          calculateInitialNextDate(recurringDate, repeatIntervalMonths);
      final now = DateTime.now();
      final todayOnly = DateTime(now.year, now.month, now.day);
      final nextDateOnly =
          DateTime(nextDate.year, nextDate.month, nextDate.day);
      if (todayOnly == nextDateOnly) {
        final expenseDoc =
            FirebaseFirestore.instance.collection('expenses').doc();
        await expenseDoc.set({
          'amount': recurringAmountValue,
          'category': recurringCategory,
          'date': nextDate,
          'title': recurringTitle,
          'userId': userId,
          'createdAt': Timestamp.now(),
        });
        final totExpensesDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('totExpenses')
            .doc('summary');
        final totExpensesSnapshot = await totExpensesDoc.get();
        if (totExpensesSnapshot.exists) {
          final currentCount = totExpensesSnapshot['count'] ?? 0;
          final currentTotalExpense =
              totExpensesSnapshot['total_expense'] ?? 0.0;
          await totExpensesDoc.update({
            'count': currentCount + 1,
            'total_expense': currentTotalExpense + recurringAmountValue,
          });
        } else {
          await totExpensesDoc.set({
            'count': 1,
            'total_expense': recurringAmountValue,
          });
        }
        final budgetDoc =
            FirebaseFirestore.instance.collection('budgets').doc(userId);
        final budgetSnapshot = await budgetDoc.get();
        if (budgetSnapshot.exists) {
          final usedBudget = budgetSnapshot['used_budget'] ?? 0.0;
          final remainingBudget = budgetSnapshot['remaining_budget'] ?? 0.0;
          await budgetDoc.update({
            'used_budget': usedBudget + recurringAmountValue,
            'remaining_budget': remainingBudget - recurringAmountValue,
          });
        } else {
          await budgetDoc.set({
            'used_budget': recurringAmountValue,
            'remaining_budget': 0.0,
          });
        }
        nextDate = DateTime(
            nextDate.year, nextDate.month + repeatIntervalMonths, nextDate.day);
      }
      final recurringDoc =
          FirebaseFirestore.instance.collection('recurringExpenses').doc();
      await recurringDoc.set({
        'userId': userId,
        'title': recurringTitle,
        'amount': recurringAmountValue,
        'category': recurringCategory,
        'nextDate': Timestamp.fromDate(nextDate),
        'repeatIntervalMonths': repeatIntervalMonths,
        'createdAt': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Recurring expense scheduled successfully!')),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            recurringTitle = '';
            recurringAmount = '';
            recurringCategory = 'Food & Grocery';
            recurringDate = DateTime.now();
            repeatIntervalMonths = 1;
          });
        }
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Failed to schedule recurring expense. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showIntervalDialog(BuildContext context) async {
    final themeMode =
        Provider.of<ThemeProvider>(context, listen: false).themeMode;
    final intervals = [
      '1 Month',
      '2 Months',
      '3 Months',
      '6 Months',
      '12 Months',
      '24 Months'
    ];
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => Dialog(
          backgroundColor: AppColors.whiteColor[themeMode],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5.h),
                Text(
                  '  Select Repeat Interval',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textColor[themeMode],
                  ),
                ),
                SizedBox(height: 15.h),
                ...intervals.map((interval) {
                  final isSelected =
                      repeatIntervalMonths == _parseInterval(interval);
                  return GestureDetector(
                    onTap: () {
                      dialogSetState(() =>
                          repeatIntervalMonths = _parseInterval(interval));
                      setState(() {});
                      Navigator.of(context).pop();
                      _updateFormData(repeatInterval: interval);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 10.h, horizontal: 16.w),
                      margin: EdgeInsets.only(bottom: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentColor[themeMode]
                            : AppColors.lightBackground[themeMode],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            interval,
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: isSelected
                                  ? AppColors.textColor[themeMode]
                                  : AppColors.secondaryTextColor[themeMode],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              size: 18,
                              color: AppColors.textColor[themeMode],
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;
    final h = MediaQuery.of(context).size.height;
    final layout = _adjustLayout(h);
    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(25.w, 12.h, 0.w, 0.h),
                          child: SvgPicture.asset(
                            themeMode == ThemeMode.light
                                ? 'assets/spence.svg'
                                : 'assets/spence_dark.svg',
                            height: 14.h,
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(40.w, 12.h, 20.w, 0.h),
                          child: Container(
                            width: 38.w,
                            height: 38.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.whiteColor[themeMode],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                size: 20.w,
                                color: AppColors.textColor[themeMode],
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: layout[0]),
                  const BudgetDisplay(),
                  SizedBox(height: layout[1]),
                  RecurringForm(onFormDataChange: _updateFormData),
                  SizedBox(height: layout[2]),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: layout[3]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IntervalButton(
                        onPressed: () => _showIntervalDialog(context)),
                    SizedBox(width: 11.w),
                    ScheduleButton(onPressed: _submitRecurringExpense),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: AppColors.overlayColor[themeMode],
                  child: Center(
                    child: LoadingIndicator(
                      indicatorType: Indicator.ballPulse,
                      colors: [AppColors.accentColor[themeMode] ?? Colors.grey],
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<double> _adjustLayout(double s) {
    if (s > 800) return [70.h, 80.h, 0.h, 30.h, 14.h, 38.h];
    if (s < 600) return [40.h, 50.h, 20.h, 20.h, 10.h, 30.h];
    return [20.h, 20.h, 10.h, 20.h, 12.h, 34.h];
  }
}
