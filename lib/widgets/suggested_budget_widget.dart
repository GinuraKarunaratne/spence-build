import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';
import 'package:spence/services/ml_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuggestedBudgetWidget extends StatefulWidget {
  const SuggestedBudgetWidget({super.key});

  @override
  _SuggestedBudgetWidgetState createState() => _SuggestedBudgetWidgetState();
}

class _SuggestedBudgetWidgetState extends State<SuggestedBudgetWidget> {
  Map<String, dynamic>? _budgetRecommendation;
  String _currency = 'Rs';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgetRecommendation();
  }

  Future<void> _loadBudgetRecommendation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Get current currency first
        final budgetDoc = await FirebaseFirestore.instance
            .collection('budgets')
            .doc(user.uid)
            .get();
        
        if (budgetDoc.exists) {
          final budgetData = budgetDoc.data() as Map<String, dynamic>;
          _currency = budgetData['currency'] ?? 'Rs';
        }

        final recommendation = await MLServices.getAdaptiveBudgetRecommendations(user.uid);
        
        if (mounted) {
          setState(() {
            _budgetRecommendation = recommendation;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading budget recommendation: $e');
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

    if (_budgetRecommendation == null || 
        (_budgetRecommendation!['suggestedBudget'] as double) <= 0) {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 30.w,
                color: AppColors.secondaryTextColor[themeMode],
              ),
              SizedBox(height: 8.h),
              Text(
                'Insufficient data for recommendations',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: AppColors.secondaryTextColor[themeMode],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final double suggestedBudget = _budgetRecommendation!['suggestedBudget'] as double;
    final double confidence = _budgetRecommendation!['confidence'] as double;
    final List<String> insights = List<String>.from(_budgetRecommendation!['insights'] ?? []);

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
                'AI Suggested Budget',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textColor[themeMode],
                ),
              ),
            ),
          ),
          
          // Confidence indicator (top right, similar to Customize Budget)
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
                    '${(confidence * 100).toStringAsFixed(0)}% Confidence',
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
                    color: _getConfidenceColor(confidence),
                  ),
                  child: Icon(
                    _getConfidenceIcon(confidence),
                    size: 14.w,
                    color: AppColors.textColor[themeMode],
                  ),
                ),
              ],
            ),
          ),
          
          // Suggested budget amount (same position and style as budget amount)
          Positioned(
            right: 20.w,
            top: 65.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Currency symbol
                Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: Text(
                    _currency,
                    style: GoogleFonts.urbanist(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.budgettextColor[themeMode],
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                // Amount
                Text(
                  suggestedBudget.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.urbanist(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textColor[themeMode],
                  ),
                ),
              ],
            ),
          ),
          // Quick insight (bottom left, small text)
          if (insights.isNotEmpty)
            Positioned(
              left: 20.w,
              bottom: 15.h,
              right: 20.w,
              child: Text(
                insights.first,
                style: GoogleFonts.poppins(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w300,
                  color: AppColors.secondaryTextColor[themeMode],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    final themeMode = Provider.of<ThemeProvider>(context, listen: false).themeMode;
    
    if (confidence >= 0.8) {
      return AppColors.healthScoreExcellent[themeMode]!; // High confidence - your accent green
    } else if (confidence >= 0.6) {
      return AppColors.healthScoreGood[themeMode]!; // Medium confidence - blue
    } else if (confidence >= 0.4) {
      return AppColors.healthScoreFair[themeMode]!; // Low confidence - orange
    } else {
      return AppColors.healthScorePoor[themeMode]!; // Very low confidence - red-orange
    }
  }

  IconData _getConfidenceIcon(double confidence) {
    if (confidence >= 0.8) {
      return Icons.verified_outlined; // High confidence
    } else if (confidence >= 0.6) {
      return Icons.analytics_outlined; // Medium confidence
    } else if (confidence >= 0.4) {
      return Icons.warning_amber_outlined; // Low confidence
    } else {
      return Icons.help_outline; // Very low confidence
    }
  }
}