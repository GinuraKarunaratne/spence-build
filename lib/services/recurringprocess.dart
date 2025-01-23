import 'package:cloud_firestore/cloud_firestore.dart';

bool isSameOrBeforeDay(DateTime dateA, DateTime dateB) {
  final a = DateTime(dateA.year, dateA.month, dateA.day);
  final b = DateTime(dateB.year, dateB.month, dateB.day);
  return a.isBefore(b) || a.isAtSameMomentAs(b);
}

Future<void> processRecurringExpenses(String userId) async {
  final now = DateTime.now();
  final db = FirebaseFirestore.instance;
  final snapshot = await db
      .collection('recurringExpenses')
      .where('userId', isEqualTo: userId)
      .get();

  for (var doc in snapshot.docs) {
    final data = doc.data();
    final interval = (data['repeatIntervalMonths'] as num?)?.toInt() ?? 1;
    DateTime nextDate = (data['nextDate'] as Timestamp).toDate();
    DateTime todayDate = DateTime(now.year, now.month, now.day);

    while (isSameOrBeforeDay(nextDate, todayDate)) {
      await db.collection('expenses').add({
        'userId': userId,
        'title': data['title'],
        'amount': data['amount'],
        'category': data['category'],
        'date': Timestamp.fromDate(nextDate),
      });
      nextDate = DateTime(nextDate.year, nextDate.month + interval, nextDate.day);
    }

    await db.collection('recurringExpenses').doc(doc.id).update({
      'nextDate': Timestamp.fromDate(nextDate),
    });
  }
}