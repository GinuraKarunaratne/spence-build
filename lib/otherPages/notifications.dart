import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  NotificationsState createState() => NotificationsState();
}

class NotificationsState extends State<Notifications> {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  Timestamp? _lastClearTimestamp;

  @override
  void initState() {
    super.initState();
    _loadLastClearTimestamp().then((_) => _setupListeners(_auth.currentUser?.uid));
  }

  Future<void> _loadLastClearTimestamp() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    final doc = await _firestore.collection('notification_settings').doc(userId).get();
    setState(() {
      _lastClearTimestamp = doc.exists ? doc['lastCleared'] as Timestamp? : null;
    });
  }

  void _setupListeners(String? userId) {
    if (userId == null) return;

    _firestore.collection('expenses').where('userId', isEqualTo: userId).snapshots().listen((s) => s.docChanges
        .where((c) => c.type == DocumentChangeType.added && (_lastClearTimestamp == null || _isAfterLastClear(c.doc.data()!['date'])))
        .forEach((c) => _addNotification(userId, 'Expense Added', _expenseMessage(c.doc.data()!), expenseId: c.doc.id)));

    _firestore.collection('recurring_expenses').where('userId', isEqualTo: userId).snapshots().listen((s) => s.docChanges
        .where((c) =>
            c.type == DocumentChangeType.modified &&
            c.doc.data()!['lastProcessed'] != null &&
            (_lastClearTimestamp == null || _isAfterLastClear(c.doc.data()!['lastProcessed'])))
        .forEach((c) => _addNotification(userId, 'Recurring Payment', _recurringMessage(c.doc.data()!), timestamp: c.doc.data()!['lastProcessed'])));

    _firestore.collection('budgets').doc(userId).snapshots().listen((s) {
      if (s.exists) {
        _checkBudget(userId, s.data()!);
      }
    });
  }

  bool _isAfterLastClear(dynamic timestamp) {
    if (_lastClearTimestamp == null) return true;
    final eventTime = timestamp is Timestamp ? timestamp : _parseDate(timestamp);
    return eventTime.toDate().isAfter(_lastClearTimestamp!.toDate());
  }

  Future<void> _addNotification(String userId, String title, String message, {String? expenseId, dynamic timestamp}) async {
    final ref = _firestore.collection('notifications');
    final query = ref.where('userId', isEqualTo: userId).where(expenseId != null ? 'expenseId' : 'message', isEqualTo: expenseId ?? message);
    if ((await query.get()).docs.isNotEmpty) return;
    await ref.add({
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': timestamp is Timestamp ? timestamp : timestamp != null ? _parseDate(timestamp) : FieldValue.serverTimestamp(),
      if (expenseId != null) 'expenseId': expenseId,
    });
  }

  Future<void> _checkBudget(String userId, Map<String, dynamic> budget) async {
    final total = (budget['total_budget'] as num?)?.toDouble() ?? 0.0;
    final remaining = (budget['remaining_budget'] as num?)?.toDouble() ?? 0.0;
    final spent = total - remaining;
    final percent = total > 0 ? spent / total * 100 : 0.0;
    final currency = await _fetchCurrency();
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyBudget = total / daysInMonth;

    if (percent >= 100) {
      _addNotification(userId, 'Budget Exceeded', 'You’ve exceeded your monthly budget by $currency ${(spent - total).toStringAsFixed(2)}.');
    } else if (percent >= 80) {
      _addNotification(userId, 'Budget Alert', 'You’ve spent 80% of your monthly budget.');
    }

    if ((remaining / (daysInMonth - now.day + 1)) > dailyBudget * 1.5) {
      _addNotification(userId, 'Extra Budget', 'You can afford to spend more today.');
    }

    final todaySpent = (await _queryExpenses(userId, now, now.add(Duration(days: 1)))).fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
    if (todaySpent > dailyBudget) _addNotification(userId, 'Daily Overspending', 'You’ve spent more than your daily average today.');

    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final weekSpent = (await _queryExpenses(userId, weekStart, weekStart.add(Duration(days: 7)))).fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
    if (weekSpent > total * (7 / daysInMonth)) _addNotification(userId, 'Weekly Overspending', 'You’ve spent more than your weekly average this week.');
  }

  String _expenseMessage(Map<String, dynamic> data) => 'Added ${(_fetchCurrency())} ${(data['amount'] as num?)?.toInt() ?? 0} to ${data['category'] ?? 'Unknown'} for ${data['title'] ?? 'No Title'}';
  String _recurringMessage(Map<String, dynamic> data) => '${data['title'] ?? 'Recurring expense'} renewed for ${(_fetchCurrency())} ${(data['amount'] as num?)?.toInt() ?? 0}.';

  Future<List<QueryDocumentSnapshot>> _queryExpenses(String userId, DateTime start, DateTime end) => _firestore
      .collection('expenses')
      .where('userId', isEqualTo: userId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('date', isLessThan: Timestamp.fromDate(end))
      .get()
      .then((s) => s.docs);

  Timestamp _parseDate(dynamic raw) => raw is Timestamp ? raw : raw is String ? Timestamp.fromDate(DateFormat('dd MMMM yyyy \'at\' HH:mm:ss').parse(raw.split(' UTC')[0], true)) : Timestamp.now();

  Future<String> _fetchCurrency() async => (_auth.currentUser?.uid) == null ? 'Rs' : (_firestore.collection('budgets').doc(_auth.currentUser!.uid).get().then((d) => d.exists ? d['currency'] ?? 'Rs' : 'Rs'));

  String _formatTime(Timestamp t) {
    final diff = DateTime.now().difference(t.toDate().toLocal());
    return diff.inMinutes < 60 ? '${diff.inMinutes}m ago' : diff.inHours < 24 ? '${diff.inHours}h ago' : diff.inDays == 1 ? 'Yesterday' : diff.inDays < 7 ? '${diff.inDays}d ago' : DateFormat('MMM d, yyyy').format(t.toDate());
  }

  Future<void> _clearNotifications(String userId) async {
    // Delete all notifications for the user
    await _firestore.collection('notifications').where('userId', isEqualTo: userId).get().then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

    // Update the last cleared timestamp
    final clearTimestamp = Timestamp.now();
    await _firestore.collection('notification_settings').doc(userId).set({
      'lastCleared': clearTimestamp,
    }, SetOptions(merge: true));

    // Update the local state
    setState(() {
      _lastClearTimestamp = clearTimestamp;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(25.w, 14.h, 20.w, 0),
                child: Row(
                  children: [
                    SvgPicture.asset('assets/spence.svg', height: 14.h),
                    const Spacer(),
                    CircleAvatar(
                      radius: 19.w,
                      backgroundColor: Colors.white,
                      child: IconButton(icon: Icon(Icons.arrow_back_rounded, size: 20.w), onPressed: () => Navigator.pop(context)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 30.h),
                  child: _buildNotifications(_auth.currentUser?.uid),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildNotifications(String? userId) => userId == null
      ? _emptyState()
      : Builder(
          builder: (context) {
            final currentUserId = _auth.currentUser!.uid;
            return Container(
              width: 320.w,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
              child: Stack(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('notifications')
                        .where('userId', isEqualTo: currentUserId)
                        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().toUtc().subtract(Duration(days: 7))))
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, s) => s.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : s.hasError
                            ? const Center(child: Text('Error loading notifications'))
                            : s.data!.docs.isEmpty
                                ? _emptyState()
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: s.data!.docs.length,
                                    itemBuilder: (context, i) {
                                      final n = s.data!.docs[i].data() as Map<String, dynamic>;
                                      return Padding(
                                        padding: EdgeInsets.only(top: 10.h),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12.r)),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(n['title'] ?? 'Notification', style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w500)),
                                                    SizedBox(height: 4.h),
                                                    Text(n['message'] ?? '', style: GoogleFonts.poppins(fontSize: 10.sp, color: const Color(0xFF7F7F7F))),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 10.w),
                                              Text(n['timestamp'] != null ? _formatTime(n['timestamp']) : 'Unknown', style: GoogleFonts.poppins(fontSize: 9.sp, color: const Color(0xFF7F7F7F))),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _clearNotifications(currentUserId),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          'Clear Notifications',
                          style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.w400, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 50.w, color: const Color.fromARGB(80, 149, 149, 149)),
            SizedBox(height: 10.h),
            Text('No Notifications', style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w500, color: const Color(0xFF272727))),
            SizedBox(height: 8.h),
            Text('You’ll see updates here when there’s activity.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 9.sp, color: const Color.fromARGB(80, 0, 0, 0))),
          ],
        ),
      );
}