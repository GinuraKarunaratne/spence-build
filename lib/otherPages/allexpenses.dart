import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spence/buttons/categorybutton.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/widgets/expenselist.dart';
import 'package:spence/widgets/header.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  AllExpensesScreenState createState() => AllExpensesScreenState();
}

class AllExpensesScreenState extends State<AllExpensesScreen> {
  List<String> selectedCategories = [];
  String selectedTimePeriod = '';
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

    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: Stack(
        children: [
          Column(
            children: [
              const Header(),
              SizedBox(height: 40.h),
              _buildExpenseContainer(context, themeMode),
            ],
          ),
          Positioned(
            bottom: 20.h,
            left: 20.w,
            right: 20.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CategoryButton(
                  onPressed: () {
                    _showCategoryFilterDialog(context);
                  },
                ),
                SizedBox(width: 11.w),
                RecordExpenseButton(onPressed: () {
                  Navigator.of(context).pushNamed('/addexpense');
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseContainer(BuildContext context, ThemeMode themeMode) {
    return Container(
      width: 320.w,
      height: 610.h,
      padding: EdgeInsets.all(24.w),
      decoration: ShapeDecoration(
        color: AppColors.whiteColor[themeMode],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.w),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Expenses',
            style: GoogleFonts.poppins(
              color: AppColors.textColor[themeMode],
              fontSize: 17.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 21.h),
          _buildTimePeriodSelector(themeMode),
          SizedBox(height: 24.h),
          Expanded(child: _buildExpensesList(context)),
        ],
      ),
    );
  }

  Widget _buildTimePeriodSelector(ThemeMode themeMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: ['Daily', 'Weekly', 'Monthly'].map((label) {
        return _buildTimePeriodButton(label, AppColors.accentColor[themeMode]!.withOpacity(0.15), themeMode);
      }).toList(),
    );
  }

  Widget _buildTimePeriodButton(String label, Color color, ThemeMode themeMode) {
    bool isSelected = selectedTimePeriod == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTimePeriod = isSelected ? '' : label;
        });
      },
      child: Container(
        width: 90.w,
        height: 25.h,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentColor[themeMode] : color,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textColor[themeMode],
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context) {
    return ExpenseList(
      selectedCategories: selectedCategories,
      selectedTimePeriod: selectedTimePeriod,
    );
  }

  Future<void> _showCategoryFilterDialog(BuildContext context) async {
    final themeMode = Provider.of<ThemeProvider>(context, listen: false).themeMode;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              backgroundColor: AppColors.whiteColor[themeMode],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.w),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5.h),
                    Text(
                      '  Filter by Category',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textColor[themeMode],
                      ),
                    ),
                    SizedBox(height: 15.h),
                    ...categories.map((category) {
                      final isSelected = selectedCategories.contains(category);
                      return GestureDetector(
                        onTap: () {
                          dialogSetState(() {
                            if (isSelected) {
                              selectedCategories.remove(category);
                            } else {
                              selectedCategories.add(category);
                            }
                          });
                          setState(() {});
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 10.h, horizontal: 16.w),
                          margin: EdgeInsets.only(bottom: 8.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentColor[themeMode]
                                : AppColors.lightBackground[themeMode],
                            borderRadius: BorderRadius.circular(12.w),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                category,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.textColor[themeMode]
                                      : AppColors.secondaryTextColor[themeMode],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: AppColors.textColor[themeMode],
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}