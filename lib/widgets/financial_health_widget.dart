import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';
import 'package:spence/services/financial_health_score.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class FinancialHealthWidget extends StatefulWidget {
  const FinancialHealthWidget({super.key});

  @override
  _FinancialHealthWidgetState createState() => _FinancialHealthWidgetState();
}

class _FinancialHealthWidgetState extends State<FinancialHealthWidget> {
  Map<String, dynamic>? _healthScore;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthScore();
  }

  Future<void> _loadHealthScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final scoreData = await FinancialHealthScore.calculateScore(user.uid);
        await FinancialHealthScore.saveScore(user.uid, scoreData);
        
        if (mounted) {
          setState(() {
            _healthScore = scoreData;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading health score: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    if (_isLoading) {
      return Container(
        width: 330.w,
        height: 135.h,
        decoration: ShapeDecoration(
          color: AppColors.secondaryBackground[themeMode],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Center(
          child: SpinKitThreeBounce(
            color: AppColors.accentColor[themeMode],
            size: 30.0,
          ),
        ),
      );
    }

    if (_healthScore == null) {
      return Container(
        width: 330.w,
        height: 135.h,
        decoration: ShapeDecoration(
          color: AppColors.secondaryBackground[themeMode],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Center(
          child: Text(
            'Unable to calculate score',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: AppColors.secondaryTextColor[themeMode],
            ),
          ),
        ),
      );
    }

    final int score = _healthScore!['totalScore'] ?? 0;
    final String grade = _healthScore!['grade'] ?? 'Unknown';

    return Container(
      width: 330.w,
      height: 135.h,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: AppColors.secondaryBackground[themeMode],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Stack(
        children: [
          // Label container (same style as used budget design)
          Positioned(
            left: 20.w,
            top: 21.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.accentColor[themeMode],
              ),
              child: Text(
                'Financial Health Score',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textColor[themeMode],
                ),
              ),
            ),
          ),
          
          // Grade indicator (top right, similar to Customize Budget)
          Positioned(
            right: 20.w,
            top: 20.h,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.customLightGray[themeMode],
                  ),
                  child: Text(
                    grade,
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textColor[themeMode],
                    ),
                  ),
                ),
                Container(
                  width: 27.w,
                  height: 27.w,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: _getScoreColor(score, themeMode),
                  ),
                  child: Icon(
                    _getScoreIcon(score),
                    size: 14.w,
                    color: AppColors.textColor[themeMode],
                  ),
                ),
              ],
            ),
          ),
          
          // Score display (same position and style as budget amount)
          Positioned(
            right: 55.w,
            top: 65.h,
            child: Text(
              score.toString(),
              textAlign: TextAlign.right,
              style: GoogleFonts.urbanist(
                fontSize: 40.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textColor[themeMode],
              ),
            ),
          ),
          
          // Score suffix "/100" (smaller text next to the score)
          Positioned(
            right: 20.w,
            top: 90.h,
            child: Text(
              '/100',
              textAlign: TextAlign.right,
              style: GoogleFonts.urbanist(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor[themeMode],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score, ThemeMode themeMode) {
    if (score >= 85) {
      return AppColors.healthScoreExcellent[themeMode]!; // Excellent - your accent green
    } else if (score >= 70) {
      return AppColors.healthScoreGood[themeMode]!; // Good - blue
    } else if (score >= 55) {
      return AppColors.healthScoreFair[themeMode]!; // Fair - orange
    } else if (score >= 40) {
      return AppColors.healthScorePoor[themeMode]!; // Poor - red-orange
    } else {
      return AppColors.healthScoreCritical[themeMode]!; // Critical - your error red
    }
  }

  IconData _getScoreIcon(int score) {
    if (score >= 85) {
      return Icons.trending_up; // Excellent
    } else if (score >= 70) {
      return Icons.thumb_up; // Good
    } else if (score >= 55) {
      return Icons.warning_amber; // Fair
    } else if (score >= 40) {
      return Icons.trending_down; // Poor
    } else {
      return Icons.error_outline; // Critical
    }
  }
}