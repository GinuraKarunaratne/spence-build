import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class TotalExpense extends StatelessWidget {
  const TotalExpense({super.key});

  Future<Map<String, dynamic>> fetchTotalExpenseAndCount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return {'total': 0.0, 'count': 0};
    }
    try {
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();
      double total = 0.0;
      for (var doc in expensesSnapshot.docs) {
        final amount = doc['amount'] as double?;
        if (amount != null) {
          total += amount;
        }
      }
      int count = expensesSnapshot.docs.length;
      return {'total': total, 'count': count};
    } catch (e) {
      print('Error fetching total expense and count: $e');
      return {'total': 0.0, 'count': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchTotalExpenseAndCount(),
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
        final data = snapshot.data!;
        final total = data['total'];
        final count = data['count'];
        return _buildExpenseContainer(futureContext, total, count);
      },
    );
  }

  Widget _buildExpenseContainer(BuildContext context, double total, int count) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Container(
      width: 330,
      height: 130,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: AppColors.secondaryBackground[themeMode],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 21,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentColor[themeMode],
              ),
              child: Text(
                'Lifetime Expenses',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textColor[themeMode],
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 20,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.budgetLabelBackground[themeMode],
                  ),
                  child: Text(
                    'Expense Count',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.alttextColor[themeMode],
                    ),
                  ),
                ),
                Container(
                  width: 45,
                  padding: const EdgeInsets.fromLTRB(5, 6, 9, 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentColor[themeMode],
                  ),
                  child: Text(
                    count.toString(),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textColor[themeMode],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            top: 65,
            child: Text(
              total.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: GoogleFonts.urbanist(
                fontSize: 40,
                fontWeight: FontWeight.w400,
                color: AppColors.textColor[themeMode],
              ),
            ),
          ),
        ],
      ),
    );
  }
}