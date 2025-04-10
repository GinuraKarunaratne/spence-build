import 'dart:async';
import 'dart:typed_data';
import 'dart:math'; // Add this for random selection
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final Random _random = Random(); // For picking random messages
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(settings);
  }

  static Future<void> addAndShowNotification(
    String userId,
    String title,
    String message, {
    String? expenseId,
  }) async {
    final ref = _firestore.collection('notifications');
    final query = ref.where('userId', isEqualTo: userId).where(
        expenseId != null ? 'expenseId' : 'message',
        isEqualTo: expenseId ?? message);
    if ((await query.get()).docs.isNotEmpty) return;

    await ref.add({
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      if (expenseId != null) 'expenseId': expenseId,
    });

    String type;
    if (title == 'Expense Added') {
      type = 'expense';
    } else if (title.contains('Budget') || title.contains('Overspending')) {
      type = 'budget_alert';
    } else if (title.contains('Recurring')) {
      type = 'recurring';
    } else {
      type = 'default';
    }
    await showNotification(title, message, type: type);
  }

  static Future<void> showNotification(String title, String body,
      {required String type}) async {
    AndroidNotificationDetails androidDetails;
    switch (type) {
      case 'reminder':
        androidDetails = AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
          vibrationPattern: Int64List.fromList([0, 100, 100, 100, 100, 100]),
        );
        break;
      case 'expense':
        androidDetails = AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
          vibrationPattern: Int64List.fromList([0, 200, 200, 300, 600, 200]),
        );
        break;
      case 'budget_alert':
        androidDetails = AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
          vibrationPattern: Int64List.fromList([0, 100, 100, 100, 100, 100]),
        );
        break;
      case 'recurring':
        androidDetails = AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
          vibrationPattern: Int64List.fromList([0, 100, 100, 100, 100, 100]),
        );
        break;
      default:
        androidDetails = AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
          vibrationPattern: null,
        );
    }

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _notifications.show(0, title, body, details);
  }

  static Future<void> scheduleDailyReminder(
      int id, String title, List<String> messages, TimeOfDay time) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel_id',
      'Daily Reminders',
      importance: Importance.max,
      priority: Priority.high,
      vibrationPattern: Int64List.fromList([0, 200, 200, 300, 600, 200]),
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final scheduledDate = _nextInstanceOfTime(time);
      debugPrint("Scheduling notification for $title at $scheduledDate");

      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final canScheduleExact =
          await androidPlugin?.canScheduleExactNotifications() ?? true;

      if (canScheduleExact) {
        // Pick a random message from the list
        String body = messages[_random.nextInt(messages.length)];
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
        );
      } else {
        debugPrint("Exact alarm permission not granted. Please enable it.");
      }
    } catch (e) {
      debugPrint("Error scheduling daily reminder: $e");
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay timeOfDay) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> checkPendingNotifications() async {
    final List<PendingNotificationRequest> pending =
        await _notifications.pendingNotificationRequests();
    for (var notification in pending) {
      debugPrint(
          "Pending: ID ${notification.id}, Title: ${notification.title}, Payload: ${notification.payload}");
    }
  }
}

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  NotificationsState createState() => NotificationsState();
}

class NotificationsState extends State<Notifications> {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  Timestamp? _lastClearTimestamp;
  Timer? _dailyCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadLastClearTimestamp()
        .then((_) => _setupListeners(_auth.currentUser?.uid));
    _setupDailyCheckTimer();
    NotificationService.checkPendingNotifications();
    // Removed tz.initializeTimeZones(), NotificationService.init(), and _scheduleDailyReminders()
  }

  @override
  void dispose() {
    _dailyCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLastClearTimestamp() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    final doc =
        await _firestore.collection('notification_settings').doc(userId).get();
    if (mounted) {
      setState(() {
        _lastClearTimestamp =
            doc.exists ? doc['lastCleared'] as Timestamp? : null;
      });
    }
  }

  void _setupListeners(String? userId) {
    if (userId == null) return;

    _firestore
        .collection('recurring_expenses')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified &&
            change.doc.data()!['lastProcessed'] != null &&
            (_lastClearTimestamp == null ||
                _isAfterLastClear(change.doc.data()!['lastProcessed']))) {
          _addNotification(
            userId,
            'Recurring Payment',
            _recurringMessage(change.doc.data()!),
            timestamp: change.doc.data()!['lastProcessed'],
          );
        }
      }
    });

    _firestore.collection('budgets').doc(userId).snapshots().listen((doc) {
      if (doc.exists) {
        _checkBudget(userId, doc.data()!);
      }
    });
  }

  void _setupDailyCheckTimer() {
    _dailyCheckTimer = Timer.periodic(const Duration(hours: 2), (timer) {
      final userId = _auth.currentUser?.uid;
      if (userId != null) _checkDailyBudget(userId);
    });
  }

  // Removed _scheduleDailyReminders() since it's now in main.dart

  bool _isAfterLastClear(dynamic timestamp) {
    if (_lastClearTimestamp == null) return true;
    final eventTime =
        timestamp is Timestamp ? timestamp : _parseDate(timestamp);
    return eventTime.toDate().isAfter(_lastClearTimestamp!.toDate());
  }

  Future<void> _addNotification(
      String userId, String title, Future<String> messageFuture,
      {String? expenseId, dynamic timestamp}) async {
    final message = await messageFuture;
    final ref = _firestore.collection('notifications');
    final query = ref.where('userId', isEqualTo: userId).where(
        expenseId != null ? 'expenseId' : 'message',
        isEqualTo: expenseId ?? message);
    if ((await query.get()).docs.isNotEmpty) return;
    await ref.add({
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': timestamp is Timestamp
          ? timestamp
          : timestamp != null
              ? _parseDate(timestamp)
              : FieldValue.serverTimestamp(),
      if (expenseId != null) 'expenseId': expenseId,
    });

    String type;
    if (title == 'Expense Added') {
      type = 'expense';
    } else if (title.contains('Budget') || title.contains('Overspending')) {
      type = 'budget_alert';
    } else if (title.contains('Recurring')) {
      type = 'recurring';
    } else {
      type = 'default';
    }
    await NotificationService.showNotification(title, message, type: type);
  }

  Future<void> _checkBudget(String userId, Map<String, dynamic> budget) async {
    final total = (budget['total_budget'] as num?)?.toDouble() ?? 0.0;
    final remaining = (budget['remaining_budget'] as num?)?.toDouble() ?? 0.0;
    final spent = total - remaining;
    final percent = total > 0 ? spent / total * 100 : 0.0;
    final currency = await _fetchCurrency();
    final now = DateTime.now();
    final remainingWeeks = _remainingWeeksInMonth(now);
    final weeklyBudget = remaining / remainingWeeks;

    if (percent >= 100) {
      _addNotification(
          userId,
          'Budget Exceeded',
          Future.value(
              'You’ve exceeded your monthly budget by $currency ${(spent - total).toStringAsFixed(2)}.'));
    } else if (percent >= 80) {
      _addNotification(userId, 'Budget Alert',
          Future.value('You’ve spent 80% of your monthly budget.'));
    }

    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final weekDocs = await _queryExpenses(
        userId, weekStart, weekStart.add(const Duration(days: 7)));
    final weekSpent = weekDocs.fold(
        0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
    if (_isThirdDayOfWeek(now) && weekSpent > weeklyBudget) {
      _addNotification(
          userId,
          'Weekly Overspending',
          Future.value(
              'You’ve spent more than your weekly budget of $currency ${weeklyBudget.toStringAsFixed(2)} this week.'));
    }
  }

  Future<void> _checkDailyBudget(String userId) async {
    final now = DateTime.now();
    final budgetDoc = await _firestore.collection('budgets').doc(userId).get();
    if (!budgetDoc.exists) return;
    final total = (budgetDoc['total_budget'] as num?)?.toDouble() ?? 0.0;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyBudget = total / daysInMonth;
    final todayStart = DateTime(now.year, now.month, now.day);
    final todaySpent = (await _queryExpenses(
            userId, todayStart, todayStart.add(const Duration(days: 1))))
        .fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
    if (todaySpent > dailyBudget) {
      final currency = await _fetchCurrency();
      _addNotification(
          userId,
          'Daily Overspending',
          Future.value(
              'You’ve spent $currency ${todaySpent.toStringAsFixed(2)} today, exceeding your daily budget of $currency ${dailyBudget.toStringAsFixed(2)}.'));
    }
  }

  Future<String> _recurringMessage(Map<String, dynamic> data) async {
    final currency = await _fetchCurrency();
    return '${data['title'] ?? 'Recurring expense'} renewed for $currency ${(data['amount'] as num?)?.toInt() ?? 0}';
  }

  Future<List<QueryDocumentSnapshot>> _queryExpenses(
          String userId, DateTime start, DateTime end) =>
      _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .get()
          .then((s) => s.docs);

  Timestamp _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw;
    if (raw is String) {
      return Timestamp.fromDate(DateFormat("dd MMMM yyyy 'at' HH:mm:ss")
          .parse(raw.split(' UTC')[0], true));
    }
    return Timestamp.now();
  }

  Future<String> _fetchCurrency() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'Rs';
    final doc = await _firestore.collection('budgets').doc(uid).get();
    return doc.exists ? doc['currency'] ?? 'Rs' : 'Rs';
  }

  String _formatTime(Timestamp t) {
    final diff = DateTime.now().difference(t.toDate().toLocal());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(t.toDate());
  }

  Future<void> _clearNotifications(String userId) async {
    final snapshots = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
    final clearTimestamp = Timestamp.now();
    await _firestore
        .collection('notification_settings')
        .doc(userId)
        .set({'lastCleared': clearTimestamp}, SetOptions(merge: true));
    if (mounted) {
      setState(() {
        _lastClearTimestamp = clearTimestamp;
      });
    }
  }

  int _remainingWeeksInMonth(DateTime now) {
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    return (daysLeft / 7).ceil();
  }

  bool _isThirdDayOfWeek(DateTime now) => now.weekday == 3;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(25.w, 14.h, 20.w, 0),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      themeMode == ThemeMode.light
                          ? 'assets/spence.svg'
                          : 'assets/spence_dark.svg',
                      height: 14.h,
                    ),
                    const Spacer(),
                    CircleAvatar(
                      radius: 19.w,
                      backgroundColor: AppColors.whiteColor[themeMode],
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: 20.w,
                          color: AppColors.textColor[themeMode],
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.only(bottom: 30.h),
                child: _buildNotifications(_auth.currentUser?.uid, themeMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifications(String? userId, ThemeMode themeMode) {
    if (userId == null) return _emptyState(themeMode);
    final currentUserId = _auth.currentUser!.uid;
    return Container(
      height: 690.h,
      width: 330.w,
      padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 15.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor[themeMode],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('notifications')
                .where('userId', isEqualTo: currentUserId)
                .where('timestamp',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()
                        .toUtc()
                        .subtract(const Duration(days: 7))))
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: SpinKitThreeBounce(
                      color: AppColors.spinnerColor[themeMode], size: 40.0),
                );
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading notifications'));
              }
              if (snapshot.data!.docs.isEmpty) {
                return _emptyState(themeMode);
              }
              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, i) {
                  final n =
                      snapshot.data!.docs[i].data() as Map<String, dynamic>;
                  return Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: AppColors.lightBackground[themeMode],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n['title'] ?? 'Notification',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textColor[themeMode],
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  n['message'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.sp,
                                    color: AppColors
                                        .notificationTextColor[themeMode],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            n['timestamp'] != null
                                ? _formatTime(n['timestamp'])
                                : 'Unknown',
                            style: GoogleFonts.poppins(
                              fontSize: 9.sp,
                              color: AppColors.notificationTextColor[themeMode],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _clearNotifications(currentUserId),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground[themeMode],
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 193, 193, 193), // Shadow color with opacity
                      blurRadius: 0.1.r, // Blur radius for the shadow
                      offset: Offset(0, 0), // Offset for the shadow (x, y)
                    ),
                  ],
                ),
                child: Text(
                  'Clear Notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textColor[themeMode],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeMode themeMode) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 50.w,
              color: AppColors.disabledIconColor[themeMode],
            ),
            SizedBox(height: 10.h),
            Text(
              'No Notifications',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor[themeMode],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You’ll see updates here when there’s activity.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 9.sp,
                color: AppColors.disabledTextColor[themeMode],
              ),
            ),
          ],
        ),
      );
}
