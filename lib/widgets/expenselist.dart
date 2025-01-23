import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitThreeBounce(
              color: Color(0xFFCCF20D),
              size: 40.0,
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading currency symbol'));
        }

        final currencySymbol = snapshot.data ?? 'Rs';

        return StreamBuilder<QuerySnapshot>(
          stream: _fetchExpenses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SpinKitThreeBounce(
                  color: Color(0xFFCCF20D),
                  size: 40.0,
                ),
              );
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading expenses'));
            }

            final expenses = snapshot.data?.docs ?? [];
            if (expenses.isEmpty) {
              return _buildEmptyExpensesMessage();
            }

            // Filter expenses based on selected time period
            final filteredExpenses = _filterExpensesByTimePeriod(expenses);
            if (filteredExpenses.isEmpty) {
              return _buildEmptyExpensesMessage();
            }

            return _buildExpenseListView(filteredExpenses, context, currencySymbol);
          },
        );
      },
    );
  }

  Widget _buildEmptyExpensesMessage() {
    return Container(
      width: 288,
      height: 350,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_rounded,
              size: 50, color: const Color.fromARGB(80, 149, 149, 149)),
          const SizedBox(height: 10),
          Text(
            'No recorded expenses',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF272727),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start recording an expense to see it here',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: const Color.fromARGB(80, 0, 0, 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseListView(
      List<QueryDocumentSnapshot> expenses, BuildContext context, String currencySymbol) {
    double containerHeight = MediaQuery.of(context).size.height * 0.63;

    return SizedBox(
      width: 297,
      height: containerHeight,
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
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildExpenseItem(title, amount),
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

  Widget _buildExpenseItem(String title, String amount) {
    return Container(
      width: double.infinity,
      height: 37,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color.fromARGB(255, 0, 0, 0),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFCCF20D),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(amount, style: GoogleFonts.poppins(fontSize: 10)),
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