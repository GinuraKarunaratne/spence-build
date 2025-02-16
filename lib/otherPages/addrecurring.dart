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
    nextDate = DateTime(nextDate.year, nextDate.month + intervalMonths, nextDate.day);
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
          if (repeatInterval != null) repeatIntervalMonths = _parseInterval(repeatInterval);
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
      var nextDate = calculateInitialNextDate(recurringDate, repeatIntervalMonths);
      final now = DateTime.now();
      final todayOnly = DateTime(now.year, now.month, now.day);
      final nextDateOnly = DateTime(nextDate.year, nextDate.month, nextDate.day);
      if (todayOnly == nextDateOnly) {
        final expenseDoc = FirebaseFirestore.instance.collection('expenses').doc();
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
          final currentTotalExpense = totExpensesSnapshot['total_expense'] ?? 0.0;
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
        final budgetDoc = FirebaseFirestore.instance.collection('budgets').doc(userId);
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
        nextDate = DateTime(nextDate.year, nextDate.month + repeatIntervalMonths, nextDate.day);
      }
      final recurringDoc = FirebaseFirestore.instance.collection('recurringExpenses').doc();
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
        const SnackBar(content: Text('Recurring expense scheduled successfully!')),
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
        const SnackBar(content: Text('Failed to schedule recurring expense. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showIntervalDialog(BuildContext context) async {
    final intervals = ['1 Month','2 Months','3 Months','6 Months','12 Months','24 Months'];
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  '  Select Repeat Interval',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black),
                ),
                const SizedBox(height: 15),
                ...intervals.map((interval) {
                  final isSelected = repeatIntervalMonths == _parseInterval(interval);
                  return GestureDetector(
                    onTap: () {
                      dialogSetState(() => repeatIntervalMonths = _parseInterval(interval));
                      setState(() {});
                      Navigator.of(context).pop();
                      _updateFormData(repeatInterval: interval);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFCCF20D) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            interval,
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: isSelected ? Colors.black : const Color(0xFF374151)),
                          ),
                          if (isSelected) const Icon(Icons.check, size: 18, color: Colors.black),
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
    final h = MediaQuery.of(context).size.height;
    final (bHeight, bSpace, fSpace, bottomSpace, logoH, lightH) = _adjustLayout(h);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 12, 0, 0),
                          child: SvgPicture.asset('assets/spence.svg', height: logoH),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 23, 0),
                          child: SvgPicture.asset('assets/light.svg', height: lightH),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: bHeight),
                  const BudgetDisplay(),
                  SizedBox(height: bSpace),
                  RecurringForm(onFormDataChange: _updateFormData),
                  SizedBox(height: fSpace),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomSpace),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IntervalButton(onPressed: () => _showIntervalDialog(context)),
                    const SizedBox(width: 11),
                    ScheduleButton(onPressed: _submitRecurringExpense),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: LoadingIndicator(
                      indicatorType: Indicator.ballPulse,
                      colors: [Color(0xFFCCF20D)],
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

  (double, double, double, double, double, double) _adjustLayout(double s) {
    if (s > 800) return (70, 80, 0, 30.0, 14.0, 38.0);
    if (s < 600) return (40, 50, 20, 20.0, 10.0, 30.0);
    return (20, 20, 10, 20.0, 12.0, 34.0);
  }
}