import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TopExpense extends StatelessWidget {
  const TopExpense({super.key});

  Future<Map<String, dynamic>?> _fetchTopExpense() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return null;
    }
    try {
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .orderBy('amount', descending: true)
          .limit(1)
          .get();
      if (expensesSnapshot.docs.isNotEmpty) {
        final topExpenseDoc = expensesSnapshot.docs.first;
        final topExpenseData = topExpenseDoc.data();
        final timestamp = topExpenseData['date'] as Timestamp;
        final date = timestamp.toDate();
        return {
          'title': topExpenseData['title'] ?? 'Unknown',
          'amount': topExpenseData['amount'] ?? 0.0,
          'category': topExpenseData['category'] ?? 'Unknown',
          'month': '${date.year}-${date.month.toString().padLeft(2, '0')}',
        };
      }
    } catch (e) {
      print('Error fetching top expense: $e');
    }
    return null;
  }

  Future<String?> _fetchCurrencySymbol() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return null;
    }
    final budgetDoc = await FirebaseFirestore.instance.collection('budgets').doc(userId).get();
    if (budgetDoc.exists) {
      final currency = budgetDoc['currency'] as String?;
      return currency ?? 'Rs';
    }
    return 'Rs';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([_fetchCurrencySymbol(), _fetchTopExpense()]),
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
          return const Center(child: Text('Error loading data'));
        }
        final currencySymbol = snapshot.data?[0] as String? ?? 'Rs';
        final topExpense = snapshot.data?[1] as Map<String, dynamic>?;
        if (topExpense == null) {
          return const Center(child: Text('No expenses recorded'));
        }
        return _buildExpenseContainer(context, currencySymbol, topExpense);
      },
    );
  }

  Widget _buildExpenseContainer(BuildContext context, String currencySymbol, Map<String, dynamic> topExpense) {
    return Container(
      width: 330,
      height: 163,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 82,
            child: SvgPicture.asset(
              'assets/bubo.svg',
              width: 80,
            ),
          ),
          Positioned(
            left: 24,
            top: 25,
            child: Text(
              'Top Expense',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w500),
            ),
          ),
          Positioned(
            left: 24,
            top: 76,
            child: Text(
              topExpense['title'],
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w400),
            ),
          ),
          Positioned(
            left: 24,
            top: 107,
            child: Container(
              padding: const EdgeInsets.only(top: 5, left: 12, right: 10, bottom: 5),
              decoration: ShapeDecoration(
                color: const Color(0xFFCCF20D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                '$currencySymbol ${topExpense['amount']}',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400),
              ),
            ),
          ),
          Positioned(
            left: 120,
            top: 107,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: ShapeDecoration(
                color: const Color(0x26CCF20D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                topExpense['category'],
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400),
              ),
            ),
          ),
          Positioned(
            left: 237,
            top: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFCCF20D)),
              child: Text(
                topExpense['month'],
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}