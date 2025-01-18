import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpenseList extends StatelessWidget {
  final List<String> selectedCategories;

  const ExpenseList({super.key, required this.selectedCategories});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fetchExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading expenses'));
        }

        final expenses = snapshot.data?.docs ?? [];
        if (expenses.isEmpty) {
          return _buildEmptyExpensesMessage();
        }

        return _buildExpenseListView(expenses, context);
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
      List<QueryDocumentSnapshot> expenses, BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double containerHeight = screenHeight * 0.63;

    return SizedBox(
      width: 297,
      height: containerHeight,
      child: Container(
        color: const Color.fromARGB(0, 0, 0, 0),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final title = expense['title'] ?? 'Unknown';
            final amount = 'Rs ${expense['amount']?.toInt() ?? 0}';
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
      ),
    );
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
        .orderBy('date', descending: true) // Order by date (oldest first)
        .snapshots();
  }
}
