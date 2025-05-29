import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';
import 'package:spence/widgets/header.dart';

class PredictionResultsPage extends StatelessWidget {
  final Map<String, dynamic> predictionData;
  const PredictionResultsPage({Key? key, required this.predictionData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    final dailyPredictions = (predictionData['daily_predictions'] as List?) ?? [];
    final predictedAmounts = dailyPredictions.map((e) {
      if (e is Map && e['predicted_amount'] != null) {
        final val = e['predicted_amount'];
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
      }
      return 0.0;
    }).toList();
    final predictedTotal = predictionData['monthly_prediction']?['total'] ?? predictionData['predicted_total'] ?? 0;
    final predictedMonth = predictionData['monthly_prediction']?['month'] ?? '';
    final zeroSpendingDays = predictionData['monthly_prediction']?['zero_spending_days'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(),
              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      predictedMonth != '' ? '$predictedMonth Prediction' : 'Monthly Prediction',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor[themeMode],
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Text(
                          'Total: Rs $predictedTotal',
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColor[themeMode],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        if (zeroSpendingDays != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.budgetLabelBackground[themeMode],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$zeroSpendingDays zero-spending days',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: AppColors.textColor[themeMode],
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    if (predictedAmounts.isNotEmpty)
                      PredictionBarWidget(predictedAmounts: predictedAmounts),
                    if (predictedAmounts.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.h),
                        child: Center(
                          child: Text(
                            'No daily prediction data available.',
                            style: GoogleFonts.poppins(fontSize: 14.sp, color: AppColors.secondaryTextColor[themeMode]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PredictionBarWidget extends StatelessWidget {
  final List<double> predictedAmounts;
  const PredictionBarWidget({Key? key, required this.predictedAmounts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    double maxExpense = predictedAmounts.isNotEmpty
        ? predictedAmounts.reduce((a, b) => a > b ? a : b)
        : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w),
          child: Container(
            width: double.infinity,
            height: 240.h,
            padding: EdgeInsets.fromLTRB(16.w, 60.h, 16.w, 8.h),
            decoration: BoxDecoration(
              color: AppColors.whiteColor[themeMode],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const LessBounceScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: predictedAmounts.asMap().entries.map((entry) {
                  int index = entry.key;
                  double amount = entry.value;
                  double barHeight = (amount / maxExpense) * 145.h;
                  int dayNumber = index + 1;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 10.w,
                          height: amount > 0 ? barHeight : 10.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60.r),
                            gradient: amount > 0
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.barColor[themeMode]!,
                                      AppColors.barGradientEnd[themeMode]!,
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      AppColors.customLightGray[themeMode]!,
                                      AppColors.customLightGray[themeMode]!,
                                    ],
                                  ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '$dayNumber',
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
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}

class LessBounceScrollPhysics extends BouncingScrollPhysics {
  const LessBounceScrollPhysics({super.parent});
  @override
  double frictionFactor(double overscrollFraction) => 0;
  @override
  LessBounceScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return LessBounceScrollPhysics(parent: buildParent(ancestor));
  }
}
