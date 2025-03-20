import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

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
          'amount': topExpenseData['amount']?.toInt() ?? 0,
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
              'Error loading data',
              style: GoogleFonts.poppins(
                color: AppColors.errorColor[themeMode],
              ),
            ),
          );
        }
        final currencySymbol = snapshot.data?[0] as String? ?? 'Rs';
        final topExpense = snapshot.data?[1] as Map<String, dynamic>?;
        if (topExpense == null) {
          return Center(
            child: Text(
              'No expenses recorded',
              style: GoogleFonts.poppins(
                color: AppColors.secondaryTextColor[themeMode],
              ),
            ),
          );
        }
        return _buildExpenseContainer(futureContext, currencySymbol, topExpense);
      },
    );
  }

  Widget _buildExpenseContainer(BuildContext context, String currencySymbol, Map<String, dynamic> topExpense) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Container(
      width: 330,
      height: 163,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: AppColors.whiteColor[themeMode],
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
                            themeMode == ThemeMode.light
                                ? 'assets/bubo.svg'
                                : 'assets/bubo_dark.svg',
                            width: 80.w,
                          ),
          ),
          Positioned(
            left: 24,
            top: 25,
            child: Text(
              'Top Expense',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.textColor[themeMode],
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 76,
            child: Text(
              topExpense['title'],
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: AppColors.textColor[themeMode],
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 107,
            child: Container(
              padding: const EdgeInsets.only(top: 5, left: 12, right: 10, bottom: 5),
              decoration: ShapeDecoration(
                color: AppColors.accentColor[themeMode],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                '$currencySymbol ${topExpense['amount']}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textColor[themeMode],
                ),
              ),
            ),
          ),
          Positioned(
            left: 120,
            top: 107,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: ShapeDecoration(
                color: AppColors.budgetLabelBackground[themeMode],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                topExpense['category'],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.alttextColor[themeMode],
                ),
              ),
            ),
          ),
          Positioned(
            left: 237,
            top: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentColor[themeMode],
              ),
              child: Text(
                topExpense['month'],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textColor[themeMode],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}