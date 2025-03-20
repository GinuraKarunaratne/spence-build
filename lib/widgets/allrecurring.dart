import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'recurringlist.dart';

class AllRecurringWidget extends StatefulWidget {
  const AllRecurringWidget({super.key});

  @override
  State<AllRecurringWidget> createState() => _AllRecurringWidgetState();
}

class _AllRecurringWidgetState extends State<AllRecurringWidget> {
  List<String> selectedCategories = [];

  final List<String> categories = [
    'Food & Grocery',
    'Transportation',
    'Entertainment',
    'Recurring Payments',
    'Shopping',
    'Other Expenses'
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    final screenHeight = ScreenUtil().screenHeight;

    double containerHeight;
    double containerWidth;

    if (screenHeight > 800.h) {
      containerHeight = screenHeight * 0.745;
      containerWidth = 320.w;
    } else if (screenHeight < 600.h) {
      containerHeight = screenHeight * 0.73;
      containerWidth = 280.w;
    } else {
      containerHeight = screenHeight * 0.72;
      containerWidth = 320.w;
    }

    return Container(
      width: containerWidth,
      height: containerHeight,
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
      decoration: ShapeDecoration(
        color: AppColors.whiteColor[themeMode],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ' Recurring Expenses',
            style: GoogleFonts.poppins(
              color: AppColors.textColor[themeMode],
              fontSize: 17.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 28.h),
          // Recurring expenses list
          Expanded(
            child: RecurringList(
              selectedCategories: selectedCategories,
            ),
          ),
        ],
      ),
    );
  }
}