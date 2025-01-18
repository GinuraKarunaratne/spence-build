import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spence/buttons/imagerecordbutton.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/forms/expenseform.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spence/widgets/budgetdisplay.dart';

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

    final userId = FirebaseAuth.instance.currentUser?.uid; // Get current user ID
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
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
      print("Error adding expense: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record expense. Please try again.')),
      );
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
                    padding: const EdgeInsets.only(top: 0.0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 12, 0, 0),
                          child: SvgPicture.asset(
                            'assets/spence.svg',
                            height: 14,
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 23, 0),
                          child: SvgPicture.asset(
                            'assets/light.svg',
                            height: 38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 70),
                  const BudgetDisplay(),
                  const SizedBox(height: 80),
                  ExpenseForm(
                    onFormDataChange: _updateFormData, // Pass callback to ExpenseForm
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ImageRecordButton(onPressed: () {
                      // Action for Image Record Button
                    }),
                    const SizedBox(width: 11),
                    RecordExpenseButton(onPressed: _submitExpense), // Submit button logic
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
