import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class RecurringList extends StatelessWidget {
  final List<String> selectedCategories;

  const RecurringList({
    super.key,
    required this.selectedCategories,
  });

  Future<String> _fetchCurrencySymbol() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 'Rs';

    final budgetDoc = await FirebaseFirestore.instance
        .collection('budgets')
        .doc(userId)
        .get();

    return budgetDoc.exists && budgetDoc['currency'] != null
        ? budgetDoc['currency'] as String
        : 'Rs';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _fetchCurrencySymbol(),
      builder: (BuildContext futureContext, currencySnapshot) {
        final themeMode = Provider.of<ThemeProvider>(futureContext).themeMode;

        if (currencySnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator(themeMode);
        }

        if (currencySnapshot.hasError || !currencySnapshot.hasData) {
          return _buildErrorMessage(
              futureContext, 'Error loading currency symbol');
        }

        final currencySymbol = currencySnapshot.data!;
        return StreamBuilder<QuerySnapshot>(
          stream: _fetchRecurringExpenses(),
          builder: (BuildContext streamContext, expenseSnapshot) {
            final themeMode =
                Provider.of<ThemeProvider>(streamContext).themeMode;

            if (expenseSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator(themeMode);
            }

            if (expenseSnapshot.hasError || !expenseSnapshot.hasData) {
              return _buildErrorMessage(
                  streamContext, 'Error loading recurring expenses');
            }

            final recurringDocs = expenseSnapshot.data!.docs;
            final filteredDocs = _filterRecurringDocs(recurringDocs);

            if (filteredDocs.isEmpty) {
              return _buildEmptyMessage(streamContext);
            }

            return _buildRecurringListView(
                filteredDocs, streamContext, currencySymbol);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _fetchRecurringExpenses() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('recurringExpenses')
        .where('userId', isEqualTo: userId)
        .orderBy('nextDate', descending: false)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filterRecurringDocs(
      List<QueryDocumentSnapshot> docs) {
    if (selectedCategories.isEmpty) return docs;

    return docs.where((doc) {
      final category = doc['category'] as String? ?? 'Unknown';
      return selectedCategories.contains(category);
    }).toList();
  }

  Widget _buildRecurringListView(
    List<QueryDocumentSnapshot> recurringDocs,
    BuildContext context,
    String currencySymbol,
  ) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: recurringDocs.length,
      itemBuilder: (context, index) {
        final recurring = recurringDocs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onLongPress: () => _showDeleteConfirmation(context, recurring.id),
            child: _buildRecurringItem(
              context: context,
              title: recurring['title'] as String? ?? 'Unknown',
              amount: '$currencySymbol ${recurring['amount']?.toInt() ?? 0}',
              category: recurring['category'] as String? ?? 'Unknown',
              nextDate: _parseNextDate(recurring['nextDate']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecurringItem({
    required BuildContext context,
    required String title,
    required String amount,
    required String category,
    DateTime? nextDate,
  }) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    final nextDateText = _calculateDaysDifference(nextDate);

    return Container(
      width: double.infinity,
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground[themeMode],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppColors.textColor[themeMode],
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentColor[themeMode],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  amount,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textColor[themeMode],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: GoogleFonts.poppins(
                  color: AppColors.notificationTextColor[themeMode],
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                nextDateText,
                style: GoogleFonts.poppins(
                  color: AppColors.logoutDialogContentColor[themeMode],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String docId) {
    final themeMode =
        Provider.of<ThemeProvider>(context, listen: false).themeMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightBackground[themeMode],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Expense',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor[themeMode],
          ),
        ),
        content: Text(
          'Are you sure you want to delete this item? This action can\'t be undone.',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: AppColors.notificationTextColor[themeMode],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.logoutDialogCancelColor[themeMode],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _deleteRecurringExpense(docId);
              Navigator.of(context).pop();
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.errorColor[themeMode],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecurringExpense(String docId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('recurringExpenses')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting recurring expense: $e');
    }
  }

  Widget _buildLoadingIndicator(ThemeMode themeMode) {
    return Center(
      child: SpinKitThreeBounce(
        color: AppColors.accentColor[themeMode],
        size: 40.0,
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, String message) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Center(
      child: Text(
        message,
        style: GoogleFonts.poppins(
          color: AppColors.errorColor[themeMode],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEmptyMessage(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_rounded,
            size: 50,
            color: AppColors.disabledIconColor[themeMode],
          ),
          const SizedBox(height: 10),
          Text(
            'No recurring expenses found',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor[themeMode],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a recurring expense to see it here',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppColors.disabledTextColor[themeMode],
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseNextDate(dynamic nextDateValue) {
    if (nextDateValue is Timestamp) {
      return nextDateValue.toDate();
    } else if (nextDateValue is String) {
      try {
        return DateTime.parse(nextDateValue);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _calculateDaysDifference(DateTime? nextDate) {
    if (nextDate == null) return 'N/A';

    final today = DateTime.now();
    final difference = nextDate
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;

    if (difference < 0) return 'Overdue by ${difference.abs()} day(s)';
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    return 'In $difference days';
  }
}
