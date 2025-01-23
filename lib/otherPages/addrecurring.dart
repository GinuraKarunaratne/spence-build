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
  String repeatInterval = '1 Month';
  bool _isLoading = false;

  void _updateFormData({
    String? title,
    String? amount,
    String? category,
    DateTime? date,
    String? repeatInterval,
  }) {
    // Schedule the state update after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          if (title != null) recurringTitle = title;
          if (amount != null) recurringAmount = amount;
          if (category != null) recurringCategory = category;
          if (date != null) recurringDate = date;
          if (repeatInterval != null) this.repeatInterval = repeatInterval;
        });
      }
    });
  }

  Future<void> _submitRecurringExpense() async {
    if (recurringTitle.isEmpty || recurringAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final double recurringAmountValue = double.parse(recurringAmount);

    try {
      // Save the recurring expense to the `recurring` collection
      final recurringDoc = FirebaseFirestore.instance.collection('recurring').doc();
      await recurringDoc.set({
        'title': recurringTitle,
        'amount': recurringAmountValue,
        'category': recurringCategory,
        'date': recurringDate,
        'repeatInterval': repeatInterval,
        'userId': userId,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recurring expense scheduled successfully!')),
      );

      // Reset form fields after submission
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            recurringTitle = '';
            recurringAmount = '';
            recurringCategory = 'Food & Grocery';
            recurringDate = DateTime.now();
            repeatInterval = '1 Month';
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to schedule recurring expense. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showIntervalDialog(BuildContext context) async {
    final intervals = [
      '1 Month',
      '2 Months',
      '3 Months',
      '6 Months',
      '1 Year',
      '2 Years'
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      '  Select Repeat Interval',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...intervals.map((interval) {
                      final isSelected = repeatInterval == interval;
                      return GestureDetector(
                        onTap: () {
                          dialogSetState(() {
                            repeatInterval = interval;
                          });
                          setState(() {});
                          Navigator.of(context).pop();
                          _updateFormData(repeatInterval: interval);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFCCF20D)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                interval,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: isSelected
                                      ? Colors.black
                                      : const Color(0xFF374151),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.black,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    double budgetDisplayHeight;
    double budgetDisplaySpacing;
    double formSpacing;
    double bottomButtonSpacing;
    double logoHeight;
    double lightHeight;

    if (screenHeight > 800) {
      budgetDisplayHeight = 70;
      budgetDisplaySpacing = 80;
      formSpacing = 0;
      bottomButtonSpacing = 30.0;
      logoHeight = 14.0;
      lightHeight = 38.0;
    } else if (screenHeight < 600) {
      budgetDisplayHeight = 40;
      budgetDisplaySpacing = 50;
      formSpacing = 20;
      bottomButtonSpacing = 20.0;
      logoHeight = 10.0;
      lightHeight = 30.0;
    } else {
      budgetDisplayHeight = 20;
      budgetDisplaySpacing = 20;
      formSpacing = 10;
      bottomButtonSpacing = 20.0;
      logoHeight = 12.0;
      lightHeight = 34.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0.0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 12, 0, 0),
                          child: SvgPicture.asset(
                            'assets/spence.svg',
                            height: logoHeight,
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 23, 0),
                          child: SvgPicture.asset(
                            'assets/light.svg',
                            height: lightHeight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: budgetDisplayHeight),
                  const BudgetDisplay(),
                  SizedBox(height: budgetDisplaySpacing),
                  RecurringForm(
                    onFormDataChange: _updateFormData,
                  ),
                  SizedBox(height: formSpacing),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomButtonSpacing),
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
}