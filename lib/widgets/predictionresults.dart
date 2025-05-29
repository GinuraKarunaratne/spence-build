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
  PredictionResultsPage({super.key, required this.predictionData});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    String predictedStartDate = '2025 / 06 / 01'; // fallback
    try {
      final startDateTimestamp =
          predictionData['monthly_prediction']?['start_date'];
      if (startDateTimestamp != null) {
        final DateTime startDate =
            startDateTimestamp.toDate(); // Firestore Timestamp
        final DateFormat formatter = DateFormat('yyyy / MM / dd');
        predictedStartDate = formatter.format(startDate);
      }
    } catch (e) {
      // fallback already set
    }

    final dailyPredictions =
        (predictionData['daily_predictions'] as List?) ?? [];
    final predictedAmounts = dailyPredictions.map((e) {
      if (e is Map && e['predicted_amount'] != null) {
        final val = e['predicted_amount'];
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
      }
      return 0.0;
    }).toList();

    final rawTotal = predictionData['monthly_prediction']?['total'] ??
        predictionData['predicted_total'] ??
        0;

    final double predictedTotal = (rawTotal is String)
        ? double.tryParse(rawTotal) ?? 0.0
        : (rawTotal is num)
            ? rawTotal.toDouble()
            : 0.0;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 25.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 45.h),
            _buildHeader(context, themeMode),
            SizedBox(height: 30.h),
            _buildPredictionSummary(themeMode, predictedAmounts, predictedTotal,
                predictedStartDate),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeMode themeMode) {
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
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.textColor[themeMode],
            ),
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
  ) {
    return Container(
      width: 330.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section - Title and Start Date
          Container(
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
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 4.h),
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
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
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

          // Big Prediction Number with star
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
              SvgPicture.asset(
                'assets/star.svg',
                width: 24.w,
                height: 24.h,
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Prediction Bar Chart
          if (predictedAmounts.isNotEmpty)
            PredictionBarWidget(predictedAmounts: predictedAmounts),

          SizedBox(height: 185.h),

          SizedBox(
            width: 330.w,
            child: Text(
              '* Please note that the projected expenses for next month are estimates and may vary based on your actual spending habits. We’ll continue to protect your personal information and use it solely for account management.',
              textAlign: TextAlign.justify,
              style: GoogleFonts.poppins(
                color: Colors.black.withAlpha(128),
                fontSize: 9,
                fontWeight: FontWeight.w300,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class PredictionBarWidget extends StatelessWidget {
  final List<double> predictedAmounts;
  const PredictionBarWidget({Key? key, required this.predictedAmounts})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    double maxExpense = predictedAmounts.isNotEmpty
        ? predictedAmounts.reduce((a, b) => a > b ? a : b)
        : 1;

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
        SizedBox(height: 20.h),
      ],
    );
  }
}
