import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class Predictive extends StatelessWidget {
  const Predictive({super.key});

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
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: AppColors.budgetLabelBackground[themeMode],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Start Analysis',
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.alttextColor[themeMode],
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