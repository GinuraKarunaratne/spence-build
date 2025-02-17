import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spence/buttons/imagerecordbutton.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/forms/expenseform.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spence/widgets/budgetdisplay.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ExpenseScreenState createState() => ExpenseScreenState();
}

class ExpenseScreenState extends State<ExpenseScreen> {
  // Variables to hold form data
  String expenseTitle = '';
  String expenseAmount = '';
  String expenseCategory = 'Food & Grocery';
  DateTime expenseDate = DateTime.now();
  bool _isLoading = false; // Loading state

  // Method to handle form updates
  void _updateFormData({
    String? title,
    String? amount,
    String? category,
    DateTime? date,
  }) {
    // Use post-frame callback to schedule the state update after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        if (title != null) expenseTitle = title;
        if (amount != null) expenseAmount = amount;
        if (category != null) expenseCategory = category;
        if (date != null) expenseDate = date;
      });
    });
  }

  // Method to handle expense submission
  Future<void> _submitExpense() async {
    if (expenseTitle.isEmpty || expenseAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final userId = FirebaseAuth.instance.currentUser?.uid; // Get current user ID
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final double expenseAmountValue = double.parse(expenseAmount); // Parse the expense amount
    try {
      // 1. Add Expense to the `expenses` Collection
      final expenseDoc = FirebaseFirestore.instance.collection('expenses').doc();
      await expenseDoc.set({
        'amount': expenseAmountValue,
        'category': expenseCategory,
        'date': expenseDate,
        'title': expenseTitle,
        'userId': userId,
        'createdAt': Timestamp.now(),
      });
      // 2. Update the `totExpenses` Collection (increment count and total_expense)
      final totExpensesDoc = FirebaseFirestore.instance.collection('users').doc(userId).collection('totExpenses').doc('summary');
      final totExpensesSnapshot = await totExpensesDoc.get();
      if (totExpensesSnapshot.exists) {
        final currentCount = totExpensesSnapshot['count'] ?? 0;
        final currentTotalExpense = totExpensesSnapshot['total_expense'] ?? 0.0;
        await totExpensesDoc.update({
          'count': currentCount + 1,
          'total_expense': currentTotalExpense + expenseAmountValue,
        });
      } else {
        // If the document does not exist, create it
        await totExpensesDoc.set({
          'count': 1,
          'total_expense': expenseAmountValue,
        });
      }
      // 3. Update the `budgets` Collection (update used_budget and remaining_budget)
      final budgetDoc = FirebaseFirestore.instance.collection('budgets').doc(userId);  // Reference to the `budgets` collection
      final budgetSnapshot = await budgetDoc.get();
      if (budgetSnapshot.exists) {
        final usedBudget = budgetSnapshot['used_budget'] ?? 0.0;
        final remainingBudget = budgetSnapshot['remaining_budget'] ?? 0.0;
        // Update used_budget by adding the expense amount
        await budgetDoc.update({
          'used_budget': usedBudget + expenseAmountValue,
          'remaining_budget': remainingBudget - expenseAmountValue,
        });
      } else {
        // If the document does not exist, create it (you could also initialize it based on default values)
        await budgetDoc.set({
          'used_budget': expenseAmountValue,
          'remaining_budget': 0.0, // This assumes the initial remaining_budget is not set
        });
      }
      // Reset form fields after submission
      setState(() {
        expenseTitle = '';
        expenseAmount = '';
        expenseCategory = 'Food & Grocery';
        expenseDate = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense recorded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record expense. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
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
                            decoration: BoxDecoration(
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
                  ),
                  SizedBox(height: 70.h),
                  const BudgetDisplay(),
                  SizedBox(height: 80.h), 
                  ExpenseForm(
                    onFormDataChange: _updateFormData,
                  ),
                  SizedBox(height: 0.h), 
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 30.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ImageRecordButton(onPressed: () {
                      
                    }),
                    SizedBox(width: 11.w), 
                    RecordExpenseButton(onPressed: _submitExpense),
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