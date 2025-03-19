import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spence/buttons/logout.dart';
import 'package:spence/buttons/editbutton.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.lightGrayBackground[themeMode],
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground[themeMode],
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 140.h,
                color: AppColors.lightGrayBackground[themeMode],
              ),
              Positioned(
                top: 90.h,
                left: 27.w,
                child: SvgPicture.asset(
                  'assets/light.svg',
                  width: 100.w,
                  height: 100.h,
                ),
              ),
              Positioned(
                top: 140.h + 14.h,
                left: 145.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ginura Karunaratne',
                      style: GoogleFonts.urbanist(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textColor[themeMode],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 174.w,
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentColor[themeMode],
                      ),
                      child: Text(
                        'iamginurakarunarate@gmail.com',
                        style: GoogleFonts.poppins(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textColor[themeMode],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 180.h + 14.h + 20.h + 21.h,
                left: (ScreenUtil().screenWidth - 330.w) / 2,
                child: _buildExpenseContainer(context, themeMode),
              ),
              Positioned(
                top: 180.h + 14.h + 20.h + 21.h + 135.h + 21.h,
                left: 26.w,
                right: 26.w,
                child: _buildSummaryRow(
                  label: 'Active Currency',
                  value: 'LKR',
                  themeMode: themeMode,
                ),
              ),
              Positioned(
                top: 180.h + 14.h + 20.h + 21.h + 135.h + 21.h + 40.h,
                left: 26.w,
                right: 26.w,
                child: _buildSummaryRow(
                  label: 'Residing Country',
                  value: 'Sri Lanka',
                  themeMode: themeMode,
                ),
              ),
              Positioned(
                top: 12.h,
                right: 20.w,
                child: Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_rounded, size: 20.w, color: AppColors.textColor[themeMode]),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 30.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const LogoutButton(),
                      SizedBox(width: 11.w),
                      EditButton(onPressed: () {}),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 9.h, right: 65.w),
                  child: IconButton(
                    icon: Icon(
                      themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
                      color: AppColors.textColor[themeMode],
                    ),
                    onPressed: () {
                      final newTheme = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                      themeProvider.setTheme(newTheme);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseContainer(BuildContext context, ThemeMode themeMode) {
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
          Positioned(
            left: 20.w,
            top: 21.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(color: AppColors.accentColor[themeMode]),
              child: Text(
                'Current Set Budget',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textColor[themeMode],
                ),
              ),
            ),
          ),
          Positioned(
            right: 20.w,
            top: 20.h,
            child: GestureDetector(
              onTap: () {
                print('Customize Budget tapped');
              },
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.customLightGray[themeMode],
                    ),
                    child: Text(
                      'Customize Budget',
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
                      color: AppColors.accentColor[themeMode],
                    ),
                    child: Icon(
                      Icons.price_change_outlined,
                      size: 14.w,
                      color: AppColors.textColor[themeMode],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 20.w,
            top: 65.h,
            child: Text(
              '30,000.00',
              textAlign: TextAlign.right,
              style: GoogleFonts.urbanist(
                fontSize: 40.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textColor[themeMode],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required ThemeMode themeMode,
  }) {
    return Container(
      width: double.infinity,
      height: 48.h,
      padding: EdgeInsets.all(10.h),
      decoration: BoxDecoration(color: AppColors.secondaryBackground[themeMode]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            color: AppColors.accentColor[themeMode],
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textColor[themeMode],
              ),
            ),
          ),
          Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            color: AppColors.customLightGray[themeMode],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textColor[themeMode],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}