import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecordButton_alt extends StatelessWidget {
  final VoidCallback onPressed;

  const RecordButton_alt({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.categoryButtonBackground[themeMode],
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(700.r),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit_outlined,
            size: 18.w,
            color: AppColors.iconColor[themeMode],
          ),
          SizedBox(width: 7.w),
          Text(
            'Record Expense',
            style: GoogleFonts.poppins(
              color: AppColors.textColor[themeMode],
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}