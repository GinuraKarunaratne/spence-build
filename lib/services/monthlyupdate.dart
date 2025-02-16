import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> checkAndUpdateMonthlyBudget() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final budgetDoc = FirebaseFirestore.instance.collection('budgets').doc(user.uid);
    final docSnapshot = await budgetDoc.get();
    if (docSnapshot.exists) {
      // Check if 'last_update_month' and 'last_update_year' fields exist
      if (!docSnapshot.data()!.containsKey('last_update_month') ||
          !docSnapshot.data()!.containsKey('last_update_year')) {
        // If the fields do not exist, initialize them with the current month and year
        final currentDate = DateTime.now();
        await budgetDoc.update({
          'last_update_month': currentDate.month,
          'last_update_year': currentDate.year,
        });
        return;
      }
      final lastUpdateMonth = docSnapshot['last_update_month'];
      final lastUpdateYear = docSnapshot['last_update_year'];
      final currentDate = DateTime.now();
      if (lastUpdateMonth != currentDate.month || lastUpdateYear != currentDate.year) {
        // Archive the old month's expenses
        await archiveExpenses(user.uid, DateTime(lastUpdateYear, lastUpdateMonth));
        // Reset the budget for the new month
        await budgetDoc.update({
          'remaining_budget': docSnapshot['monthly_budget'],
          'used_budget': 0.0,
          'last_update_month': currentDate.month,
          'last_update_year': currentDate.year,
        });
        // Optionally, notify the user
        notifyUserOfMonthEndSummary();
      }
    }
  }
}

Future<void> archiveExpenses(String userId, DateTime lastUpdate) async {
  // Define the date range for the previous month
  final startOfMonth = DateTime(lastUpdate.year, lastUpdate.month, 1);
  final endOfMonth = DateTime(lastUpdate.year, lastUpdate.month + 1, 1).subtract(Duration(days: 1));
  // Fetch expenses for the previous month
  final expenses = await FirebaseFirestore.instance
      .collection('expenses')
      .where('user_id', isEqualTo: userId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
      .get();
  for (var expense in expenses.docs) {
    // Copy each expense to the archived_expenses collection
    await FirebaseFirestore.instance
        .collection('archived_expenses')
        .add(expense.data());
    // Delete the original expense from the expenses collection
    await expense.reference.delete();
  }
}

void notifyUserOfMonthEndSummary() {
  
}