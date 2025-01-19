import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class DailyExpenses extends StatelessWidget {
  const DailyExpenses({super.key});

  Future<String?> _fetchCurrencySymbol() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('User ID is null');
      return null;
    }

    final budgetDoc = await FirebaseFirestore.instance
        .collection('budgets')
        .doc(userId)
        .get();

    if (budgetDoc.exists) {
      final currency = budgetDoc['currency'] as String?;
      print('Fetched currency: $currency');
      return currency;
    } else {
      print('Budget document does not exist for user: $userId');
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
          print('Error fetching currency symbol: ${snapshot.error}');
          return const Center(child: Text('Error loading currency symbol'));
        }

        final currencySymbol = snapshot.data ?? 'Rs';
        print('Using currency symbol: $currencySymbol');

        return Column(children: [_buildExpenseContainer(context, currencySymbol)]);
      },
    );
  }

  Widget _buildExpenseContainer(BuildContext context, String currencySymbol) {
    return Container(
      width: 320,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(top: 24, left: 24, child: _buildTitle()),
          Positioned(left: 16, top: 58, child: _buildExpensesList(currencySymbol)),
          Positioned(left: 16, top: 317, child: _buildViewAllExpenses(context)),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Expenses Today',
      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildViewAllExpenses(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/allexpenses');
      },
      child: Container(
        width: 289,
        height: 37,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFCCF20D),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('View All Expenses', style: GoogleFonts.poppins(fontSize: 11)),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: const Color(0xFF272727)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(String currencySymbol) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fetchExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitThreeBounce(
              color: Color.fromARGB(255, 255, 255, 255),
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
            width: 288,
            height: 252,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_actions_rounded,
                    size: 50, color: const Color.fromARGB(80, 149, 149, 149)),
                const SizedBox(height: 10),
                Text(
                  'No expenses recorded today',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF272727),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start recording your expenses to see them here',
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

        // List of Expenses
        return Container(
          width: 288,
          height: 252,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final title = expense['title'] ?? 'Unknown';
              final amount = '$currencySymbol ${expense['amount']?.toInt() ?? 0}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildExpenseItem(title, amount),
              );
            },
          ),
        );
      },
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