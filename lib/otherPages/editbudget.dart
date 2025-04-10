import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spence/buttons/confirmbutton.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';
import 'package:spence/widgets/valuedisplay.dart';

class EditBudget extends StatefulWidget {
  const EditBudget({super.key});

  @override
  _EditBudgetState createState() => _EditBudgetState();
}

class _EditBudgetState extends State<EditBudget> {
  bool _isLoading = false;
  double _newBudget = 0.0;

  // Save the new budget to Firestore.
  Future<void> _saveNewBudget() async {
    setState(() => _isLoading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('budgets')
            .doc(userId)
            .update({'new_budget': _newBudget});
        _showDefaultSnackbar("Budget updated successfully!");
      } catch (e) {
        debugPrint("Error updating budget: $e");
        _showDefaultSnackbar("Failed to update budget. Please try again.");
      }
    }
    setState(() => _isLoading = false);
  }

  // Default SnackBar using standard styling.
  void _showDefaultSnackbar(String message) {
    final themeMode = Provider.of<ThemeProvider>(context, listen: false).themeMode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: AppColors.whiteColor[themeMode],
            fontSize: 12,
          ),
        ),
        backgroundColor: AppColors.errorColor[themeMode],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isOverflowing = constraints.maxHeight < 600.h;

            return Stack(
              children: [
                // Main content
                SingleChildScrollView(
                  physics: isOverflowing ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        SizedBox(height: isOverflowing ? 50.h : 250.h),
                        // Centered ValueDisplay widget
                        Center(
                          child: ValueDisplay(
                            onBudgetChanged: (newBudget) {
                              setState(() {
                                _newBudget = newBudget;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: isOverflowing ? 20.h : 230.h),
                        // Note text
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 27.w),
                          child: Text(
                            '* Your budget changes will take effect at the beginning of next month. We’ll ensure that all your personal details are securely stored and used only for managing your account.',
                            textAlign: TextAlign.justify,
                            style: GoogleFonts.poppins(
                              color: AppColors.budgetNoteColor[themeMode],
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        SizedBox(height: isOverflowing ? 20.h : 50.h),
                      ],
                    ),
                  ),
                ),
                // Confirm button at the bottom
                Positioned(
                  bottom: 20.h,
                  left: 20.h,
                  right: 20.h,
                  child: ConfirmButton(
                    onPressed: _saveNewBudget,
                  ),
                ),
                // Loading overlay
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
            );
          },
        ),
      ),
    );
  }
}