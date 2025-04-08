import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IntervalButton extends StatelessWidget {
  final VoidCallback onPressed;

  const IntervalButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.categoryButtonBackground[themeMode],
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15), // Removed ScreenUtil for height
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(700.r),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 18.sp, // Responsive icon size
            color: AppColors.iconColor[themeMode],
          ),
          SizedBox(width: 7.w), // Responsive spacing
          Text(
            'Repeat Intervals',
            style: GoogleFonts.poppins(
              color: AppColors.textColor[themeMode],
              fontSize: 11.sp, // Responsive font size
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}