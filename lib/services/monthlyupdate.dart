import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> checkAndUpdateMonthlyBudget() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final budgetDoc = FirebaseFirestore.instance.collection('budgets').doc(user.uid);
    final docSnapshot = await budgetDoc.get();

    if (docSnapshot.exists) {
      // Check if 'last_update' field exists
      if (!docSnapshot.data()!.containsKey('last_update')) {
        // If the field does not exist, initialize it
        await budgetDoc.update({
          'last_update': Timestamp.fromDate(DateTime.now()),
        });
        return;
      }

      final lastUpdate = (docSnapshot['last_update'] as Timestamp).toDate();
      final currentDate = DateTime.now();

      if (lastUpdate.month != currentDate.month || lastUpdate.year != currentDate.year) {
        // Archive the old month's expenses
        await archiveExpenses(user.uid, lastUpdate);

        // Reset the budget for the new month
        await budgetDoc.update({
          'remaining_budget': docSnapshot['monthly_budget'],
          'used_budget': 0.0,
          'last_update': Timestamp.fromDate(currentDate),
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
  // Implement notification or in-app summary display
  print("Month-end summary notification");
}