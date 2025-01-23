import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

Future<void> processRecurringExpenses(String userId) async {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Query recurring expenses due today or earlier
  final querySnapshot = await FirebaseFirestore.instance
      .collection('recurringExpenses')
      .where('userId', isEqualTo: userId)
      .where('nextDate', isLessThanOrEqualTo: today)
      .get();

  for (var doc in querySnapshot.docs) {
    final data = doc.data();

    // Record the expense in the user's history
    await FirebaseFirestore.instance.collection('expenses').add({
      'userId': userId,
      'title': data['title'],
      'amount': data['amount'],
      'category': data['category'],
      'date': today, // Log today's date
    });

    // Calculate the next occurrence
    final DateTime nextDate = DateTime.parse(data['nextDate']);
    final DateTime newNextDate = DateTime(
      nextDate.year,
      nextDate.month + (data['repeatIntervalMonths'] as num).toInt(),
      nextDate.day,
    );

    // Update the next occurrence in Firebase
    await FirebaseFirestore.instance
        .collection('recurringExpenses')
        .doc(doc.id)
        .update({'nextDate': DateFormat('yyyy-MM-dd').format(newNextDate)});
  }
}