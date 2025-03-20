import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class MonthlyPie extends StatelessWidget {
  const MonthlyPie({super.key});

  /// Fetches total monthly expense amounts per category for the current user.
  Future<Map<String, double>> fetchMonthlyExpenses() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {};

    // Get the start and end of the current month
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    try {
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .where('date', isLessThanOrEqualTo: endOfMonth)
          .get();

      final Map<String, double> categoryTotals = {};
      for (var doc in expensesSnapshot.docs) {
        final data = doc.data();
        final amount = data['amount'] as double?;
        final category = data['category'] as String?;
        if (amount != null && category != null) {
          categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
        }
      }
      return categoryTotals;
    } catch (e) {
      print('Error fetching monthly expenses: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: fetchMonthlyExpenses(),
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
        final data = snapshot.data ?? {};
        if (data.isEmpty) {
          return Center(
            child: Text(
              'No expenses recorded',
              style: GoogleFonts.poppins(
                color: AppColors.secondaryTextColor[themeMode],
              ),
            ),
          );
        }
        return _buildExpenseContainer(futureContext, data);
      },
    );
  }

  Widget _buildExpenseContainer(BuildContext context, Map<String, double> data) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    final List<PieChartSectionData> pieSections = data.entries.map((entry) {
      return PieChartSectionData(
        color: AppColors.categoryPieColors[entry.key] ?? AppColors.categoryPieColors['Food & Grocery']!,
        value: entry.value,
        radius: 17,
        title: '',
      );
    }).toList();

    return Container(
      width: 330,
      height: 250,
      decoration: BoxDecoration(
        color: AppColors.transparentColor[themeMode],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Positioned Pie Chart.
          Positioned(
            top: 45,
            left: 57,
            child: SizedBox(
              width: 130,
              height: 140,
              child: PieChart(
                PieChartData(
                  sections: pieSections,
                  sectionsSpace: 0,
                  centerSpaceRadius: 72,
                ),
              ),
            ),
          ),
          // Positioned category labels.
          Positioned(
            left: 235,
            bottom: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.keys.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.2),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.categoryPieColors[category] ?? AppColors.categoryPieColors['Food & Grocery']!,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: AppColors.textColor[themeMode],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}