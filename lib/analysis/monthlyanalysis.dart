import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:spence/analysis/anlalysiswidgets/monthlybar.dart';
import 'package:spence/analysis/anlalysiswidgets/monthlybar2.dart';
import 'package:spence/analysis/anlalysiswidgets/monthlymessage.dart';
import 'package:spence/analysis/anlalysiswidgets/monthlypie.dart';
import 'package:spence/analysis/anlalysiswidgets/monthlypiemessage.dart';
import 'package:spence/analysis/anlalysiswidgets/summarymonthly.dart';

class MonthlyAnalysis extends StatefulWidget {
  const MonthlyAnalysis({super.key});

  @override
  State<MonthlyAnalysis> createState() => _MonthlyAnalysisState();
}

class _MonthlyAnalysisState extends State<MonthlyAnalysis> {
  late final Stream<Map<String, dynamic>> _monthlyExpensesStream;

  @override
  void initState() {
    super.initState();
    _monthlyExpensesStream = Stream.fromFuture(_getMonthlyExpensesAndBudgetData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 30.h),
              StreamBuilder<Map<String, dynamic>>(
                stream: _monthlyExpensesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoading();
                  } else if (snapshot.hasError) {
                    return _buildErrorPage("Error: ${snapshot.error}");
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _noExpensesMessage();
                  } else {
                    return _buildGraphWithMessages(snapshot.data!);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(25.w, 12.h, 0, 0),
            child: SvgPicture.asset('assets/spence.svg', height: 14.h),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(40.w, 12.h, 20.w, 0),
            child: CircleAvatar(
              radius: 19.w,
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, size: 20.w, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: SpinKitThreeBounce(
        color: Color(0xFFCCF20D),
        size: 40.0,
      ),
    );
  }

  Widget _buildErrorPage(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60.w, color: Colors.red),
            SizedBox(height: 20.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noExpensesMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.summarize_rounded,
              size: 50.w, color: const Color.fromARGB(80, 149, 149, 149)),
          SizedBox(height: 10.h),
          Text(
            'No expense record available',
            style: GoogleFonts.poppins(
                fontSize: 14.sp, fontWeight: FontWeight.w500, color: const Color(0xFF272727)),
          ),
          SizedBox(height: 8.h),
          Text(
            'Record at least one expense to access the Analysis.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 9.sp,
                fontWeight: FontWeight.w400,
                color: const Color.fromARGB(80, 0, 0, 0)),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphWithMessages(Map<String, dynamic> data) {
    final List<double> monthlyExpenses = List<double>.from(data['monthlyExpenses']);
    final double monthlyAllowableExpenditure = data['monthlyAllowableExpenditure'];
    final double totalMonthlyExpenditure = monthlyExpenses.reduce((a, b) => a + b);

    if (totalMonthlyExpenditure == 0) return _noExpensesMessage();

    final String currency = data['currency'] ?? '';
    final Map<String, Map<String, dynamic>> categoryDetails =
        Map<String, Map<String, dynamic>>.from(data['categoryDetails']);
    final int expenseCount = data['expenseCount'];
    final Map<String, dynamic> firstExpenseInfo =
        Map<String, dynamic>.from(data['firstExpenseInfo']);
    final Map<String, dynamic>? latestExpense = data['latestExpense'] != null
        ? Map<String, dynamic>.from(data['latestExpense'])
        : null;
    final Map<String, dynamic> topExpense =
        Map<String, dynamic>.from(data['topExpense'] ?? {});
    final double lastMonthTotal = data['lastMonthTotal'] ?? 0.0;
    final double comparedToLastMonthPercent = (lastMonthTotal > 0)
        ? ((totalMonthlyExpenditure - lastMonthTotal) / lastMonthTotal) * 100
        : (totalMonthlyExpenditure > 0 ? 100 : 0);
    final bool isIncrease = totalMonthlyExpenditure >= lastMonthTotal;
    final double averageSpendPerDay = data['averageSpendPerDay'] ?? 0.0;
    final String mostSpentDayOfWeek = data['mostSpentDayOfWeek'] ?? 'Unknown';

    String message = generateMonthlyMessage(
      monthlyAllowableExpenditure,
      totalMonthlyExpenditure,
      categoryDetails,
      currency,
      expenseCount,
      firstExpenseInfo,
      latestExpense!,
      topExpense,
    );

    final pieMessage = generateMonthlyPieMessage(
      monthlyAllowableExpenditure,
      totalMonthlyExpenditure,
      categoryDetails,
      currency,
      expenseCount,
      firstExpenseInfo,
      latestExpense,
      topExpense,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonthlyBarWidget(expenses: monthlyExpenses),
        Padding(
          padding: EdgeInsets.fromLTRB(25.w, 0.h, 25.w, 0.h),
          child: Text(
            message,
            textAlign: TextAlign.justify,
            style: GoogleFonts.poppins(
                fontSize: 9.sp, fontWeight: FontWeight.w400, color: const Color(0xFF7F7F7F)),
          ),
        ),
        SizedBox(height: 27.h),
        const MonthlyPie(),
        SizedBox(height: 5.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w),
          child: Text(
            pieMessage,
            textAlign: TextAlign.justify,
            style: GoogleFonts.poppins(
                fontSize: 9.sp, fontWeight: FontWeight.w400, color: const Color(0xFF7F7F7F)),
          ),
        ),
        SizedBox(height: 35.h),
        MonthlyBar2Widget(expenses: monthlyExpenses), // Assuming it accepts expenses
        SizedBox(height: 15.h),
        SummaryMonthly(
          totalExpense: totalMonthlyExpenditure,
          highestExpense: topExpense['amount']?.toDouble() ?? 0.0,
          comparedToLastMonthPercent: comparedToLastMonthPercent,
          isIncrease: isIncrease,
          currency: currency,
          averageSpendPerDay: averageSpendPerDay,
          mostSpentDayOfWeek: mostSpentDayOfWeek,
        ),
        SizedBox(height: 50.h),
        Align(
          alignment: Alignment.bottomCenter,
          child: Lottie.asset(
            'assets/happy.json',
            height: 100.h,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getMonthlyExpensesAndBudgetData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {};

    final today = DateTime.now();
    final firstDayOfMonth = DateTime(today.year, today.month, 1);
    final lastDayOfMonth = DateTime(today.year, today.month + 1, 0, 23, 59, 59, 999);

    final budgetDoc = await FirebaseFirestore.instance
        .collection('budgets')
        .doc(userId)
        .get();
    final budgetData = budgetDoc.data() ?? {};
    final remainingBudget = (budgetData['remaining_budget'] as double?) ?? 0.0;
    final String currency = budgetData['currency'] ?? '';
    final monthlyAllowable = remainingBudget; // Full budget for the month

    // Fetch this month's expenses
    final monthlyExpensesSnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: firstDayOfMonth)
        .where('date', isLessThanOrEqualTo: lastDayOfMonth)
        .get();

    // Fetch last month's expenses
    final firstDayOfLastMonth = DateTime(today.year, today.month - 1, 1);
    final lastDayOfLastMonth =
        DateTime(today.year, today.month, 0, 23, 59, 59, 999);
    final lastMonthSnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: firstDayOfLastMonth)
        .where('date', isLessThanOrEqualTo: lastDayOfLastMonth)
        .get();

    final List<double> monthlyExpenses = List.filled(lastDayOfMonth.day, 0.0);
    final Map<String, Map<String, dynamic>> categoryDetails = {};
    final Map<int, double> dayOfWeekTotals = {0: 0.0, 1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0, 6: 0.0};
    int expenseCount = 0;
    Map<String, dynamic> firstExpenseInfo = {};
    Map<String, dynamic>? latestExpense;
    Map<String, dynamic> topExpense = {};

    for (var doc in monthlyExpensesSnapshot.docs) {
      final expense = doc.data();
      final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
      final timestamp = expense['date'] as Timestamp?;
      final category = expense['category']?.toString() ?? "Other";
      final title = expense['title']?.toString() ?? "Expense";

      expenseCount++;

      if (expenseCount == 1) {
        int day = 0;
        if (timestamp != null) {
          final date = timestamp.toDate();
          day = date.day;
        }
        firstExpenseInfo = {
          'day': day,
          'category': category,
          'title': title,
          'amount': amount,
        };
      }

      if (timestamp != null) {
        final date = timestamp.toDate();
        latestExpense = {'title': title, 'amount': amount};
        final dayIndex = date.day - 1;
        if (dayIndex >= 0 && dayIndex < monthlyExpenses.length) {
          monthlyExpenses[dayIndex] += amount;
        }
        final weekdayIndex = date.weekday - 1; // 0 = Monday, 6 = Sunday
        dayOfWeekTotals[weekdayIndex] = (dayOfWeekTotals[weekdayIndex] ?? 0.0) + amount;
      }

      if (amount > (topExpense['amount'] as double? ?? 0.0)) {
        topExpense = {'title': title, 'amount': amount};
      }

      categoryDetails.update(
        category,
        (existing) => {
          'total': (existing['total'] as double) + amount,
          'count': (existing['count'] as int) + 1,
        },
        ifAbsent: () => {'total': amount, 'count': 1},
      );
    }

    final double totalMonthlyExpenditure =
        monthlyExpenses.fold(0.0, (sum, amount) => sum + amount);
    final double lastMonthTotal = lastMonthSnapshot.docs.fold<double>(
        0.0, (sum, doc) => sum + ((doc['amount'] as num?)?.toDouble() ?? 0.0));
    final daysInMonth = lastDayOfMonth.day;
    final double averageSpendPerDay = totalMonthlyExpenditure / daysInMonth;
    final String mostSpentDayOfWeek = _findMostSpentDayOfWeek(dayOfWeekTotals);

    return {
      'monthlyExpenses': monthlyExpenses,
      'monthlyAllowableExpenditure': monthlyAllowable,
      'categoryDetails': categoryDetails,
      'expenseCount': expenseCount,
      'firstExpenseInfo': firstExpenseInfo,
      'latestExpense': latestExpense,
      'topExpense': topExpense,
      'currency': currency,
      'lastMonthTotal': lastMonthTotal,
      'averageSpendPerDay': averageSpendPerDay,
      'mostSpentDayOfWeek': mostSpentDayOfWeek,
    };
  }

  String _findMostSpentDayOfWeek(Map<int, double> dayTotals) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    int maxDay = 0;
    double maxAmount = 0.0;
    dayTotals.forEach((day, total) {
      if (total > maxAmount) {
        maxAmount = total;
        maxDay = day;
      }
    });
    return days[maxDay];
  }
}