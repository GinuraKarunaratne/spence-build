import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PredictionResultsPage extends StatelessWidget {
  final Map<String, dynamic> predictionData;
  const PredictionResultsPage({super.key, required this.predictionData});

  double _toDouble(dynamic raw) {
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    if (raw is num)    return raw.toDouble();
    return 0.0;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } catch (_) {}
    }
    if (raw is Timestamp) {
      return raw.toDate();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    // 1. Predicted start date
    String predictedStartDate = '—';
    final rawStart = predictionData['monthly_prediction']?['start_date'];
    final dt = _parseDate(rawStart);
    if (dt != null) {
      predictedStartDate = DateFormat('yyyy / MM / dd').format(dt);
    }

    // 2. Daily predictions → amounts
    final dailyList = (predictionData['daily_predictions'] as List?) ?? [];
    final predictedAmounts = dailyList.map((e) {
      if (e is Map && e['predicted_amount'] != null) {
        return _toDouble(e['predicted_amount']);
      }
      return 0.0;
    }).toList();

    // 3. Predicted total
    final rawTotal = predictionData['monthly_prediction']?['total']
                   ?? predictionData['predicted_total']
                   ?? 0;
    final predictedTotal = _toDouble(rawTotal);

    // 4. Last month’s stats
    final stats = (predictionData['spending_patterns']?['monthly_stats']
                  as Map<String, dynamic>?) ?? {};

    // 4a. Last month's total expense
    final lastMonthTotal = _toDouble(stats['total_expense']);

    // 5. Percent change vs. last month
    final isIncrease = lastMonthTotal > 0 && predictedTotal >= lastMonthTotal;
    final comparedToLastMonthPercent = lastMonthTotal > 0
        ? ((predictedTotal - lastMonthTotal) / lastMonthTotal) * 100
        : 0.0;

    // 6. Average spend per day
    final averageSpendPerDay = stats.containsKey('average_daily_spend')
        ? _toDouble(stats['average_daily_spend'])
        : (predictedAmounts.isNotEmpty
            ? predictedAmounts.reduce((a, b) => a + b) / predictedAmounts.length
            : 0.0);

    // 7. Most spent day
    String mostSpentDay = '—';
    if (predictedAmounts.isNotEmpty) {
      final maxVal = predictedAmounts.reduce((a, b) => a > b ? a : b);
      final idx = predictedAmounts.indexOf(maxVal);
      mostSpentDay = 'Day ${idx + 1}';
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 15.h),
                _buildHeader(themeMode, context),
                SizedBox(height: 30.h),
                _buildPredictionSummary(
                  themeMode,
                  predictedAmounts,
                  predictedTotal,
                  predictedStartDate,
                  comparedToLastMonthPercent,
                  isIncrease,
                  averageSpendPerDay,
                  mostSpentDay,
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeMode themeMode, BuildContext context) {
    return Row(
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
            icon: Icon(Icons.arrow_back_rounded,
                size: 20, color: AppColors.textColor[themeMode]),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionSummary(
    ThemeMode themeMode,
    List<double> predictedAmounts,
    double predictedTotal,
    String predictedStartDate,
    double comparedPercent,
    bool isIncrease,
    double averageSpendPerDay,
    String mostSpentDay,
  ) {
    return SizedBox(
      width: 330.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Date
          SizedBox(
            width: 303.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Prediction',
                  style: GoogleFonts.poppins(
                    color: AppColors.textColor[themeMode],
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                        color: AppColors.budgetLabelBackground[themeMode],
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Projected Start Date',
                            style: GoogleFonts.poppins(
                              color: AppColors.alttextColor[themeMode],
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        color: AppColors.accentColor[themeMode],
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            predictedStartDate,
                            style: GoogleFonts.poppins(
                              color: AppColors.textColor[themeMode],
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 15.h),

          // Total + Star
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                predictedTotal.toStringAsFixed(2),
                style: GoogleFonts.urbanist(
                  color: AppColors.budgettextColor[themeMode],
                  fontSize: 60.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SvgPicture.asset('assets/star.svg', width: 24.w, height: 24.h),
            ],
          ),

          SizedBox(height: 20.h),

          // Bar Chart
          if (predictedAmounts.isNotEmpty)
            PredictionBarWidget(predictedAmounts: predictedAmounts),

          // Summary Box
          SummarySection(
            comparedToLastMonth: comparedPercent,
            averageSpendPerDay: averageSpendPerDay,
            mostSpentDay: mostSpentDay,
            isIncrease: isIncrease,
          ),

          SizedBox(height: 25.h),

          // Footnote
          SizedBox(
            width: 330.w,
            child: Text(
              '* Please note that projected expenses for next month are estimates and may vary based on actual spending habits. We’ll continue to protect your personal information and use it solely for account management.',
              textAlign: TextAlign.justify,
              style: GoogleFonts.poppins(
                color: Colors.black.withAlpha(128),
                fontSize: 9,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PredictionBarWidget extends StatelessWidget {
  final List<double> predictedAmounts;
  const PredictionBarWidget({super.key, required this.predictedAmounts});

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    final maxExpense = predictedAmounts.isNotEmpty
        ? predictedAmounts.reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 240.h,
          padding: EdgeInsets.fromLTRB(16.w, 60.h, 16.w, 8.h),
          decoration: BoxDecoration(
            color: AppColors.whiteColor[themeMode],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: predictedAmounts.asMap().entries.map((e) {
                final day = e.key + 1;
                final val = e.value;
                final barH = (val / maxExpense) * 145.h;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 10.w,
                        height: val > 0 ? barH : 10.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60.r),
                          gradient: val > 0
                              ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.barColor[themeMode]!,
                                    AppColors.barGradientEnd[themeMode]!,
                                  ],
                                )
                              : LinearGradient(colors: [
                                  AppColors.customLightGray[themeMode]!,
                                  AppColors.customLightGray[themeMode]!,
                                ]),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '$day',
                        style: GoogleFonts.poppins(
                          fontSize: 8.sp,
                          color: AppColors.logoutDialogCancelColor[themeMode],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}

class SummarySection extends StatelessWidget {
  final double comparedToLastMonth;
  final double averageSpendPerDay;
  final String mostSpentDay;
  final bool isIncrease;

  const SummarySection({
    super.key,
    required this.comparedToLastMonth,
    required this.averageSpendPerDay,
    required this.mostSpentDay,
    required this.isIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    const currency = 'Rs';

    Widget summaryRow(String label, String value, {bool showArrow = false}) {
      return Container(
        padding: EdgeInsets.all(10.h),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground[themeMode],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              color: AppColors.accentColor[themeMode],
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textColor[themeMode],
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.alttextColor[themeMode],
                  ),
                ),
                if (showArrow)
                  Padding(
                    padding: EdgeInsets.only(left: 5.w),
                    child: Icon(
                      isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12.w,
                      color: isIncrease
                          ? AppColors.logoutButtonBackground[themeMode]
                          : AppColors.accentColor[themeMode],
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        summaryRow(
          'Compared to Last Month',
          '${comparedToLastMonth.toStringAsFixed(0)}%',
          showArrow: true,
        ),
        summaryRow(
          'Average Per Day',
          '$currency ${averageSpendPerDay.toStringAsFixed(2)}',
        ),
        summaryRow('Most Spent Day', mostSpentDay),
      ],
    );
  }
}
