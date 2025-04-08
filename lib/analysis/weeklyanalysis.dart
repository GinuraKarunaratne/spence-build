import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:spence/analysis/anlalysiswidgets/weeklybar.dart';
import 'package:spence/analysis/anlalysiswidgets/weeklybar2.dart';
import 'package:spence/analysis/anlalysiswidgets/weeklypie.dart';
import 'package:spence/analysis/anlalysiswidgets/weeklymessage.dart';
import 'package:spence/analysis/anlalysiswidgets/weeklypiemessage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spence/analysis/anlalysiswidgets/summaryweekly.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class WeeklyAnalysis extends StatefulWidget {
  const WeeklyAnalysis({super.key});

  @override
  State<WeeklyAnalysis> createState() => _WeeklyAnalysisState();
}

class _WeeklyAnalysisState extends State<WeeklyAnalysis> {
  late final Stream<Map<String, dynamic>> _weeklyExpensesStream;

  @override
  void initState() {
    super.initState();
    _weeklyExpensesStream = Stream.fromFuture(_getWeeklyExpensesAndBudgetData());
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 30.h),
              Flexible(
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: _weeklyExpensesStream,
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
              ),
            ],
          ),
        ),
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

    // Weekly breakdown: Assuming 'weeklyExpenses' holds 7 values (one per day of week)
    final weeklyExpenses = List<double>.from(data['weeklyExpenses']);
    final weeklyAllowableExpenditure = data['weeklyAllowableExpenditure'];
    final totalWeeklyExpenditure = weeklyExpenses.reduce((a, b) => a + b);

    if (totalWeeklyExpenditure == 0) return _noExpensesMessage();

    final String currency = data['currency'] ?? '';
    final Map<String, Map<String, dynamic>> categoryDetails =
        Map<String, Map<String, dynamic>>.from(data['categoryDetails']);
    final int expenseCount = data['expenseCount'];
    final Map<String, dynamic> firstExpenseInfo =
        Map<String, dynamic>.from(data['firstExpenseInfo']);
    final Map<String, dynamic> latestExpense =
        Map<String, dynamic>.from(data['latestExpense'] ?? {});
    final Map<String, dynamic> topExpense =
        Map<String, dynamic>.from(data['topExpense'] ?? {});

    // Compute weekly comparison values
    final double lastWeekTotal = data['lastWeekTotal'] ?? 0.0;
    final double comparedToLastWeekPercent = (lastWeekTotal > 0)
        ? ((totalWeeklyExpenditure - lastWeekTotal) / lastWeekTotal) * 100
        : (totalWeeklyExpenditure > 0 ? 100 : 0);
    final bool isIncrease = totalWeeklyExpenditure >= lastWeekTotal;
    final String mostSpentWeek = data['mostSpentWeek'] ?? 'Week 1';

    // Generate weekly message (above the pie chart)
    final message = generateWeeklyMessage(
      weeklyAllowableExpenditure,
      totalWeeklyExpenditure,
      categoryDetails,
      currency,
      expenseCount,
      firstExpenseInfo,
      latestExpense,
      topExpense,
    );

    final pieMessage = generateWeeklyPieMessage(
      weeklyAllowableExpenditure,
      totalWeeklyExpenditure,
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
        WeeklyBarWidget(weeklyExpenses: weeklyExpenses),
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
        const WeeklyPie(),
        SizedBox(height: 5.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w),
          child: Text(
            pieMessage,
            textAlign: TextAlign.justify,
            style: GoogleFonts.poppins(
              fontSize: 9.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.notificationTextColor[themeMode],
            ),
          ),
        ),
        SizedBox(height: 35.h),
        WeeklyBar2Widget(weeklyExpenses: weeklyExpenses),
        SizedBox(height: 15.h),
        SummaryWeekly(
          totalExpense: totalWeeklyExpenditure,
          mostSpentCategory: _findMostSpentCategory(categoryDetails),
          mostSpentWeek: mostSpentWeek,
          comparedToLastWeekPercent: comparedToLastWeekPercent,
          isIncrease: isIncrease,
          currency: currency,
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

  Future<Map<String, dynamic>> _getWeeklyExpensesAndBudgetData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {};

    final today = DateTime.now();
    // Current week: Monday to Sunday
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));

    // Query current week's expenses
    final currentWeekSnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfWeek)
        .where('date', isLessThanOrEqualTo: endOfWeek)
        .get();

    // Aggregate weekly expenses and category details
    final List<double> weeklyExpenses = List.filled(7, 0.0); // One for each day
    final Map<String, Map<String, dynamic>> categoryDetails = {};
    Map<String, dynamic> firstExpenseInfo = {};
    Map<String, dynamic> latestExpense = {};
    Map<String, dynamic> topExpense = {};
    int expenseCount = 0;

    for (var doc in currentWeekSnapshot.docs) {
      final expense = doc.data();
      final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
      final timestamp = expense['date'] as Timestamp?;
      final category = expense['category']?.toString() ?? "Other";
      final title = expense['title']?.toString() ?? "Expense";

      expenseCount++;
      if (expenseCount == 1) {
        int dayIndex = 0;
        if (timestamp != null) {
          dayIndex = timestamp.toDate().difference(startOfWeek).inDays;
        }
        firstExpenseInfo = {
          'day': dayIndex,
          'category': category,
          'title': title,
          'amount': amount,
        };
      }
      if (timestamp != null) {
        latestExpense = {'title': title, 'amount': amount};
        final dayIndex = timestamp.toDate().difference(startOfWeek).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          weeklyExpenses[dayIndex] += amount;
        }
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

    final double totalWeeklyExpenditure =
        weeklyExpenses.fold(0.0, (sum, amount) => sum + amount);

    // Query last week's expenses
    final lastWeekStart = startOfWeek.subtract(const Duration(days: 7));
    final lastWeekEnd = startOfWeek.subtract(const Duration(seconds: 1));
    final lastWeekSnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: lastWeekStart)
        .where('date', isLessThanOrEqualTo: lastWeekEnd)
        .get();
    final List<double> lastWeekExpenses = lastWeekSnapshot.docs
        .map((doc) => (doc['amount'] as num).toDouble())
        .toList();
    final double lastWeekTotal =
        lastWeekExpenses.fold(0.0, (sum, amount) => sum + amount);

    // Compute week numbers within the month
    final currentWeekNumber = ((today.day - 1) ~/ 7) + 1;
    final lastWeekNumber = currentWeekNumber > 1 ? currentWeekNumber - 1 : 1;
    final mostSpentWeek = totalWeeklyExpenditure >= lastWeekTotal
        ? "Week $currentWeekNumber"
        : "Week $lastWeekNumber";

    // Retrieve budget info
    final budgetDoc = await FirebaseFirestore.instance
        .collection('budgets')
        .doc(userId)
        .get();
    final budgetData = budgetDoc.data() ?? {};
    final remainingBudget = (budgetData['remaining_budget'] as double?) ?? 0.0;
    final String currency = budgetData['currency'] ?? '';
    final weeklyAllowable = remainingBudget / 7;

    return {
      'weeklyExpenses': weeklyExpenses,
      'weeklyAllowableExpenditure': weeklyAllowable,
      'categoryDetails': categoryDetails,
      'expenseCount': expenseCount,
      'firstExpenseInfo': firstExpenseInfo,
      'latestExpense': latestExpense,
      'topExpense': topExpense,
      'currency': currency,
      'lastWeekTotal': lastWeekTotal,
      'mostSpentWeek': mostSpentWeek,
    };
  }
}