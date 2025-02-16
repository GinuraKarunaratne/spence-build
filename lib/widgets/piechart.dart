import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import the SpinKit package

class PieChartExpenses extends StatelessWidget {
  const PieChartExpenses({super.key});

  /// Fetches the total expense amount per category for the current user.
  Future<Map<String, double>> fetchPieChartExpenses() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {};
    try {
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
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
      print('Error fetching expenses: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: fetchPieChartExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Use the three dot loading animation here.
          return const Center(
            child: SpinKitThreeBounce(
              color: Color.fromARGB(0, 204, 242, 13),
              size: 40.0,
            ),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        }
        final data = snapshot.data ?? {};
        return _buildExpenseContainer(context, data);
      },
    );
  }

  Widget _buildExpenseContainer(BuildContext context, Map<String, double> data) {
    final List<PieChartSectionData> pieSections = data.entries.map((entry) {
      return PieChartSectionData(
        color: _getColorForCategory(entry.key),
        value: entry.value,
        radius: 17,
        title: '',
      );
    }).toList();

    return Container(
      width: 330,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Positioned Pie Chart.
          Positioned(
            top: 45,
            left: 25,
            child: SizedBox(
              width: 140,
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
            right: 10,
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
                          color: _getColorForCategory(category),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.black,
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
  
  Color _getColorForCategory(String category) {
    final Map<String, Color> categoryColors = {
      'Food & Grocery': const Color(0xFF2AE123),
      'Transportation': const Color(0xFF2A00FF),
      'Entertainment': const Color(0xFFFFD400),
      'Recurring Payments': const Color(0xFF9747FF),
      'Shopping': const Color(0xFFFF5900),
      'Other Expenses': const Color(0xFFFF00AA),
    };

    // Return the corresponding color or a default if not found.
    return categoryColors[category] ?? const Color(0xFF2AE123);
  }
}
