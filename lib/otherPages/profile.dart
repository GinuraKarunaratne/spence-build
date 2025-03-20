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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Model to hold user profile data
class UserProfile {
  final String fullName;
  final String email;
  final String country;

  UserProfile({
    required this.fullName,
    required this.email,
    required this.country,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      fullName: map['fullName'] ?? 'Unknown',
      email: map['email'] ?? 'Unknown',
      country: map['country'] ?? 'Unknown',
    );
  }
}

/// Model to hold budget data
class Budget {
  final double monthlyBudget;
  final String currency;

  Budget({required this.monthlyBudget, required this.currency});

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      monthlyBudget: (map['monthly_budget'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'Unknown',
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Fetches the user's profile data from the 'users' collection
  Future<UserProfile> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) {
      throw Exception('User document not found');
    }
    return UserProfile.fromMap(doc.data()!);
  }

  /// Fetches the current budget using the user's UID
  Future<Budget> _fetchCurrentBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final doc = await FirebaseFirestore.instance
        .collection('budgets')
        .doc(user.uid)
        .get();
    if (!doc.exists) {
      // You can also set defaults or throw an error if desired.
      return Budget(monthlyBudget: 0.0, currency: 'LKR');
    }
    return Budget.fromMap(doc.data()!);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.lightGrayBackground[themeMode],
        statusBarIconBrightness:
            themeMode == ThemeMode.light ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground[themeMode],
        body: SafeArea(
          child: FutureBuilder(
            future: Future.wait([_fetchUserProfile(), _fetchCurrentBudget()]),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: SpinKitThreeBounce(
                    color: AppColors.accentColor[themeMode],
                    size: 40.0,
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final userProfile = snapshot.data![0] as UserProfile;
              final budget = snapshot.data![1] as Budget;

              return Stack(
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
                      themeMode == ThemeMode.light
                          ? 'assets/light.svg'
                          : 'assets/dark.svg',
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
                          userProfile.fullName,
                          style: GoogleFonts.urbanist(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textColor[themeMode],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor[themeMode],
                          ),
                          child: Text(
                            userProfile.email,
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
                  // Budget container
                  Positioned(
                    top: 180.h + 14.h + 20.h + 21.h,
                    left: (ScreenUtil().screenWidth - 330.w) / 2,
                    child: _buildExpenseContainer(
                        context, themeMode, budget.monthlyBudget),
                  ),
                  // Active Currency and Country rows
                  Positioned(
                    top: 180.h + 14.h + 20.h + 21.h + 135.h + 21.h,
                    left: 26.w,
                    right: 26.w,
                    child: _buildSummaryRow(
                      label: 'Active Currency',
                      value: budget.currency,
                      themeMode: themeMode,
                    ),
                  ),
                  Positioned(
                    top: 180.h + 14.h + 20.h + 21.h + 135.h + 21.h + 40.h,
                    left: 26.w,
                    right: 26.w,
                    child: _buildSummaryRow(
                      label: 'Residing Country',
                      value: userProfile.country,
                      themeMode: themeMode,
                    ),
                  ),
                  // Back button at top-right
                  Positioned(
                    top: 12.h,
                    right: 20.w,
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.whiteColor[themeMode],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: 20.w,
                          color: AppColors.textColor[themeMode],
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  // Bottom buttons
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
                  // Theme toggle button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(top: 9.h, right: 65.w),
                      child: IconButton(
                        icon: Icon(
                          themeMode == ThemeMode.light
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: AppColors.textColor[themeMode],
                        ),
                        onPressed: () {
                          final newTheme = themeMode == ThemeMode.light
                              ? ThemeMode.dark
                              : ThemeMode.light;
                          Provider.of<ThemeProvider>(context, listen: false)
                              .setTheme(newTheme);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseContainer(
      BuildContext context, ThemeMode themeMode, double budgetAmount) {
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
              decoration:
                  BoxDecoration(color: AppColors.accentColor[themeMode]),
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
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
              budgetAmount.toStringAsFixed(2),
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
      decoration:
          BoxDecoration(color: AppColors.secondaryBackground[themeMode]),
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
                  textAlign: TextAlign.left,
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
