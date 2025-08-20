import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';
import 'package:spence/services/ml_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class AnomalyDetectionWidget extends StatefulWidget {
  const AnomalyDetectionWidget({super.key});

  @override
  _AnomalyDetectionWidgetState createState() => _AnomalyDetectionWidgetState();
}

class _AnomalyDetectionWidgetState extends State<AnomalyDetectionWidget> {
  List<Map<String, dynamic>>? _anomalies;
  bool _isLoading = true;
  bool _isExpanded = false;
  Map<int, bool> _showDateMap = {}; // Track which items show date vs amount

  @override
  void initState() {
    super.initState();
    _loadAnomalies();
  }

  Future<void> _loadAnomalies() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final anomalies = await MLServices.detectSpendingAnomalies(user.uid);
        
        if (mounted) {
          setState(() {
            _anomalies = anomalies;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading anomalies: $e');
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
        width: MediaQuery.of(context).size.width * 0.9,
        height: 100.h,
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground[themeMode],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: SpinKitThreeBounce(
            color: AppColors.accentColor[themeMode],
            size: 20.0,
          ),
        ),
      );
    }

    if (_anomalies == null || _anomalies!.isEmpty) {
      return Container(
        width: 320.w,
        height: 200.h,
        decoration: BoxDecoration(
          color: AppColors.whiteColor[themeMode],
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 24.h,
              left: 24.w,
              child: Text(
                'Unusual Spending',
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColor[themeMode],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 50.w,
                    color: AppColors.disabledIconColor[themeMode],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'No unusual spending detected',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor[themeMode],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'All your expenses look normal',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.disabledTextColor[themeMode],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Calculate container height based on visible anomalies count (hug content)
    int visibleCount = _isExpanded ? _anomalies!.length : (_anomalies!.length > 3 ? 3 : _anomalies!.length);
    double baseHeight = 58.h; // Header space
    double itemHeight = 37.h + 7.h; // Item height + spacing
    double buttonHeight = _anomalies!.length > 3 ? 37.h + 15.h : 0; // View more button + spacing
    double containerHeight = baseHeight + (visibleCount * itemHeight) + buttonHeight + 20.h; // Extra padding
    
    double anomaliesListHeight = visibleCount * itemHeight;
    double viewMoreTop = baseHeight + anomaliesListHeight + 20.h;

    return Container(
      width: 320.w,
      height: containerHeight,
      decoration: BoxDecoration(
        color: AppColors.whiteColor[themeMode],
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Stack(
        children: [
          // Header title with exclamation mark
          Positioned(
            top: 24.h,
            left: 24.w,
            child: Row(
              children: [
                
                Icon(
                  Icons.warning_amber_rounded,
                  size: 13.sp,
                  color: AppColors.healthScoreCritical[themeMode],
                ),
                SizedBox(width: 4.w),
                Text(
                  'Unusual Spending',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textColor[themeMode],
                  ),
                ),
              ],
            ),
          ),
          
          // Anomalies list
          Positioned(
            left: 16.w,
            top: 58.h,
            child: Container(
              width: 288.w,
              height: anomaliesListHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _isExpanded ? _anomalies!.length : (_anomalies!.length > 3 ? 3 : _anomalies!.length),
                itemBuilder: (context, index) {
                  final anomaly = _anomalies![index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 7.h),
                    child: _buildAnomalyItem(anomaly, themeMode, index),
                  );
                },
              ),
            ),
          ),
          
          // View more button (if needed)
          if (_anomalies!.length > 3)
            Positioned(
              left: 16.w,
              top: viewMoreTop,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  width: 289.w,
                  height: 37.h,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: AppColors.accentColor[themeMode],
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isExpanded 
                            ? 'Show Less'
                            : '${_anomalies!.length - 3} More Anomalies',
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: AppColors.textColor[themeMode],
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 13.w,
                        color: AppColors.secondaryTextColor[themeMode],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnomalyItem(Map<String, dynamic> anomaly, ThemeMode themeMode, int index) {
    final DateTime date = anomaly['date'];
    final String title = anomaly['title'] ?? 'Unknown';
    final double amount = anomaly['amount'] ?? 0.0;
    final String anomalyType = anomaly['anomalyType'] ?? 'Unknown';
    final bool showDate = _showDateMap[index] ?? false;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showDateMap[index] = !showDate;
        });
      },
      child: Container(
        width: double.infinity,
        height: 37.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground[themeMode],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - Title 
            Expanded(
              flex: 3,
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: AppColors.textColor[themeMode],
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Middle - Anomaly type (same size as amount)
            Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: _getAnomalyColor(anomalyType),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                anomalyType == 'High Amount' ? 'High' : 
                anomalyType == 'Unusual Frequency' ? 'Frequent' : 'Other',
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Right side - Amount or Date (tap to toggle)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppColors.accentColor[themeMode],
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                showDate 
                    ? DateFormat('MMM dd').format(date)
                    : 'Rs ${amount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  color: AppColors.textColor[themeMode],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAnomalyColor(String anomalyType) {
    final themeMode = Provider.of<ThemeProvider>(context, listen: false).themeMode;
    
    switch (anomalyType) {
      case 'High Amount':
        return AppColors.healthScorePoor[themeMode]!; // Red-orange
      case 'Unusual Frequency':
        return AppColors.healthScoreFair[themeMode]!; // Orange
      default:
        return AppColors.healthScoreCritical[themeMode]!; // Red
    }
  }
}