import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'predictionresults.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Predictive extends StatefulWidget {
  const Predictive({Key? key}) : super(key: key);

  @override
  State<Predictive> createState() => _PredictiveState();
}

class _PredictiveState extends State<Predictive> {
  bool _isLoading = false;

  Future<void> _runPrediction() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        setState(() => _isLoading = false);
        return;
      }
      // Call your backend prediction endpoint (update URL as needed)
      final url = Uri.parse('https://us-central1-spencev2-3b372.cloudfunctions.net/predict');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': user.uid}),
      );
      if (response.statusCode == 200) {
        // Option 1: Use response body
        final result = jsonDecode(response.body);
        // Option 2: Fetch from Firestore (if prediction is saved there)
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('predictions')
            .orderBy('predicted_at', descending: true)
            .limit(1)
            .get();
        Map<String, dynamic> predictionData = result;
        if (doc.docs.isNotEmpty) {
          predictionData = doc.docs.first.data();
        }
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PredictionResultsPage(predictionData: predictionData),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prediction failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    return Center(
      child: Container(
        width: 330.w,
        height: 395.h,
        padding: const EdgeInsets.symmetric(vertical: 0),
        decoration: BoxDecoration(
          color: AppColors.whiteColor[themeMode],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 27.h),
                  Text(
                    'Predictive Analysis',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColor[themeMode],
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Text(
                    'Note that this process will read your spending patterns and might take some time to generate your personalized spending analysis prediction.',
                    textAlign: TextAlign.justify,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w300,
                      color: AppColors.budgetNoteColor[themeMode],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _runPrediction,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: AppColors.budgetLabelBackground[themeMode],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: LoadingIndicator(
                                  indicatorType: Indicator.ballPulse,
                                  colors: [AppColors.alttextColor[themeMode] ?? Colors.blue],
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Start Analysis',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.alttextColor[themeMode],
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 180.h,
              left: 20.w,
              child: SvgPicture.asset(
                themeMode == ThemeMode.light
                    ? 'assets/predict.svg'
                    : 'assets/predict_dark.svg',
                width: 205.w,
              ),
            ),
          ],
        ),
      ),
    );
  }
}