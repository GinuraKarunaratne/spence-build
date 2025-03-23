import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spence/buttons/confirmbutton.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spence/forms/profileform.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  bool _isLoading = false;
  final _formKey = GlobalKey<ProfileFormState>();
  String _initialFullName = '';
  String _initialCountry = '';
  String _initialCurrency = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final budgetDoc = await FirebaseFirestore.instance.collection('budgets').doc(userId).get();
      if (userDoc.exists && budgetDoc.exists) {
        setState(() {
          _initialFullName = userDoc['fullName'] ?? '';
          _initialCountry = userDoc['country'] ?? '';
          _initialCurrency = budgetDoc['currency'] ?? '';
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _submitProfile(String fullName, String country, String currency) async {
    if (fullName.isEmpty || country.isEmpty || currency.isEmpty) {
      _showPillNotification(context, 'Please fill in all required fields');
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showPillNotification(context, 'User not logged in');
      return;
    }

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      final budgetDoc = FirebaseFirestore.instance.collection('budgets').doc(userId);
      await userDoc.update({
        'fullName': fullName,
        'country': country,
      });
      await budgetDoc.update({
        'currency': currency,
      });

      _showPillNotification(context, 'Profile updated successfully!');
    } catch (e) {
      debugPrint("Submit Profile Error: $e");
      _showPillNotification(context, 'Failed to update profile. Please try again.');
    }
  }

  void _showPillNotification(BuildContext context, String message) {
    final themeMode = Provider.of<ThemeProvider>(context, listen: false).themeMode;

    final snackBar = SnackBar(
      content: Text(
        message,
        style: GoogleFonts.poppins(
          color: AppColors.whiteColor[themeMode],
          fontSize: 12,
        ),
      ),
      backgroundColor: AppColors.primaryBackground[themeMode],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // Header row with logo and back button
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(25.w, 12.h, 0, 0),
                          child: SvgPicture.asset(
                            themeMode == ThemeMode.light
                                ? 'assets/spence.svg'
                                : 'assets/spence_dark.svg',
                            height: 14.h,
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(40.w, 12.h, 20.w, 0),
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
                      ],
                    ),
                  ),
                  SizedBox(height: 200.h),
                  Padding(
                    padding: EdgeInsets.only(left: 30.w),
                    child: SvgPicture.asset(
                      'assets/happy.svg',
                      width: 220.w,
                    ),
                  ),
                  ProfileForm(
                    key: _formKey,
                    initialFullName: _initialFullName,
                    initialCountry: _initialCountry,
                    initialCurrency: _initialCurrency,
                    onSubmit: (fullName, country, currency) async {
                      setState(() => _isLoading = true);
                      try {
                        await _submitProfile(fullName, country, currency);
                        _formKey.currentState?.resetForm();
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
                  ),
                ],
              ),
            ),
            // Confirm button positioned 20px above the bottom of the screen
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: ConfirmButton(
                  onPressed: () {
                    _formKey.currentState?.submit();
                  },
                ),
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: AppColors.overlayColor[themeMode],
                  child: Center(
                    child: LoadingIndicator(
                      indicatorType: Indicator.ballPulse,
                      colors: [AppColors.accentColor[themeMode] ?? Colors.grey],
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}