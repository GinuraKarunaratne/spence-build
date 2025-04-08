import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spence/analysis/anlalysiswidgets/dailybar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spence/analysis/anlalysiswidgets/dailymessage.dart';
import 'package:spence/analysis/anlalysiswidgets/summarydaily.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class DailyAnalysis extends StatefulWidget {
  const DailyAnalysis({super.key});

  @override
  State<DailyAnalysis> createState() => _DailyAnalysisState();
}

class _DailyAnalysisState extends State<DailyAnalysis> {
  late final Stream<Map<String, dynamic>> _dailyExpensesStream;

  @override
  void initState() {
    super.initState();
    _dailyExpensesStream = Stream.fromFuture(_getDailyExpensesAndBudgetData());
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 25.h),
                _buildHeader(),
                SizedBox(height: 30.h),
                StreamBuilder<Map<String, dynamic>>(
                  stream: _dailyExpensesStream,
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
                SizedBox(height: 130.h), // Padding to avoid overlap with footer
              ],
            ),
          ),
          // Fixed footer at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Lottie.asset(
              'assets/happy.json',
              height: 100.h,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(25.w, 15.h, 0, 0),
            child: SvgPicture.asset(
              themeMode == ThemeMode.light
                  ? 'assets/spence.svg'
                  : 'assets/spence_dark.svg',
              height: 14,
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(40.w, 15.h, 20.w, 0),
            child: CircleAvatar(
              radius: 19.w,
              backgroundColor: AppColors.whiteColor[themeMode],
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: AppColors.textColor[themeMode],
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Center(
      child: SpinKitThreeBounce(
        color: AppColors.accentColor[themeMode],
        size: 40.0,
      ),
    );
  }

  Widget _buildErrorPage(String message) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60.w,
              color: AppColors.errorColor[themeMode],
            ),
            SizedBox(height: 20.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.errorColor[themeMode],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noExpensesMessage() {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 230.h),
          Icon(
            Icons.summarize_rounded,
            size: 50.w,
            color: AppColors.disabledIconColor[themeMode],
          ),
          SizedBox(height: 10.h),
          Text(
            'No expense record available',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor[themeMode],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Record at least one expense to access the Analysis.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 9.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.disabledTextColor[themeMode],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphWithMessages(Map<String, dynamic> data) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    final List<double> hourlyExpenses =
        List<double>.from(data['hourlyExpenses'] ?? List.filled(24, 0.0));
    final double dailyAllowableExpenditure =
        data['dailyAllowableExpenditure'] ?? 0.0;
    final double totalDailyExpenditure = hourlyExpenses.reduce((a, b) => a + b);

    if (totalDailyExpenditure == 0) return _noExpensesMessage();

    final String currency = data['currency'] ?? '';
    final Map<String, Map<String, dynamic>> categoryDetails =
        Map<String, Map<String, dynamic>>.from(data['categoryDetails'] ?? {});
    final int expenseCount = data['expenseCount'] ?? 0;
    final Map<String, dynamic> firstExpenseInfo =
        Map<String, dynamic>.from(data['firstExpenseInfo'] ?? {});
    final Map<String, dynamic> latestExpense =
        Map<String, dynamic>.from(data['latestExpense'] ?? {});
    final Map<String, dynamic> topExpense =
        Map<String, dynamic>.from(data['topExpense'] ?? {});
    final double yesterdayTotal = data['yesterdayTotal'] ?? 0.0;

    final double comparedToYesterdayPercent = (yesterdayTotal > 0)
        ? ((totalDailyExpenditure - yesterdayTotal) / yesterdayTotal) * 100
        : (totalDailyExpenditure > 0 ? 100 : 0);
    final bool isIncrease = totalDailyExpenditure >= yesterdayTotal;

    final message = generateDailyMessage(
      dailyAllowableExpenditure,
      totalDailyExpenditure,
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
        const DailyBarWidget(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w),
          child: Text(
            message,
            textAlign: TextAlign.justify,
            style: GoogleFonts.poppins(
              fontSize: 9.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.notificationTextColor[themeMode],
            ),
          ),
        ),
        SizedBox(height: 27.h),
        SummaryDaily(
          totalExpense: totalDailyExpenditure,
          mostSpentCategory: _findMostSpentCategory(categoryDetails),
          comparedToYesterdayPercent: comparedToYesterdayPercent,
          isIncrease: isIncrease,
          currency: currency,
        ),
      ],
    );
  }

  String _findMostSpentCategory(
      Map<String, Map<String, dynamic>> categoryDetails) {
    String topCategory = 'Other';
    double topTotal = 0.0;
    categoryDetails.forEach((category, details) {
      final total = (details['total'] as double?) ?? 0.0;
      if (total > topTotal) {
        topTotal = total;
        topCategory = category;
      }
    });
    return topCategory;
  }

  Future<Map<String, dynamic>> _getDailyExpensesAndBudgetData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {};

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;

    final budgetDoc = await FirebaseFirestore.instance
        .collection('budgets')
        .doc(userId)
        .get();
    final budgetData = budgetDoc.data() ?? {};
    final remainingBudget = (budgetData['remaining_budget'] as double?) ?? 0.0;
    final currency = budgetData['currency'] ?? '';
    final daysRemaining = daysInMonth - today.day + 1;
    final dailyAllowable =
        daysRemaining > 0 ? (remainingBudget / daysRemaining) : 0.0;

    final expensesSnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .get();

    final yesterday = today.subtract(const Duration(days: 1));
    final startOfYesterday =
        DateTime(yesterday.year, yesterday.month, yesterday.day);
    final endOfYesterday =
        DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);
    final yesterdaySnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfYesterday)
        .where('date', isLessThanOrEqualTo: endOfYesterday)
        .get();

    final List<double> hourlyExpenses = List.filled(24, 0.0);
    final Map<String, Map<String, dynamic>> categoryDetails = {};
    int expenseCount = 0;
    Map<String, dynamic> firstExpenseInfo = {};
    Map<String, dynamic>? latestExpense = {};
    Map<String, dynamic> topExpense = {};

    for (var doc in expensesSnapshot.docs) {
      final expense = doc.data();
      final amount = expense['amount'] ?? 0.0;
      final timestamp = expense['date'] as Timestamp?;
      final category = expense['category']?.toString() ?? "Other";
      final title = expense['title']?.toString() ?? "Expense";

      expenseCount++;
      if (expenseCount == 1) {
        int hour = 0;
        if (timestamp != null) hour = timestamp.toDate().hour;
        firstExpenseInfo = {
          'hour': hour,
          'category': category,
          'title': title,
          'amount': amount,
        };
      }
      if (timestamp != null) {
        latestExpense = {'title': title, 'amount': amount};
        hourlyExpenses[timestamp.toDate().hour] += amount;
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

    double yesterdayTotal = 0.0;
    for (var doc in yesterdaySnapshot.docs) {
      final expense = doc.data();
      final amount = expense['amount'] ?? 0.0;
      yesterdayTotal += (amount is num) ? (amount).toDouble() : 0.0;
    }

    return {
      'hourlyExpenses': hourlyExpenses,
      'dailyAllowableExpenditure': dailyAllowable,
      'categoryDetails': categoryDetails,
      'expenseCount': expenseCount,
      'firstExpenseInfo': firstExpenseInfo,
      'latestExpense': latestExpense,
      'topExpense': topExpense,
      'currency': currency,
      'yesterdayTotal': yesterdayTotal,
    };
  }
}