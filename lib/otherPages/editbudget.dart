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
import 'package:spence/widgets/suggested_budget_widget.dart';

class EditBudget extends StatefulWidget {
  const EditBudget({super.key});

  @override
  _EditBudgetState createState() => _EditBudgetState();
}

class _EditBudgetState extends State<EditBudget> {
  bool _isLoading = false;
  double _newBudget = 0.0;

  // Save the new budget to Firestore with validation
  Future<void> _saveNewBudget() async {
    // Validate budget amount before proceeding
    if (_newBudget <= 0) {
      _showDefaultSnackbar("Please enter a valid budget amount");
      return;
    }
    
    setState(() => _isLoading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId != null) {
      try {
        // Calculate the first day of next month
        final now = DateTime.now();
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        
        // Update budget with new amount and effective date
        await FirebaseFirestore.instance
            .collection('budgets')
            .doc(userId)
            .update({
              'new_budget': _newBudget,
              'budget_update_date': Timestamp.fromDate(nextMonth),
            });
            
        // Show success message with effective date
        _showDefaultSnackbar("Budget will be updated from ${nextMonth.day}/${nextMonth.month}/${nextMonth.year}");
      } catch (e) {
        debugPrint("Error updating budget: $e");
        _showDefaultSnackbar("Failed to update budget. Please try again.");
      }
    }
    
    setState(() => _isLoading = false);
  }

  // Default SnackBar using standard styling
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
                // Main scrollable content
                SingleChildScrollView(
                  physics: isOverflowing 
                      ? const BouncingScrollPhysics() 
                      : const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header section with logo and back button
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Row(
                            children: [
                              // App logo
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
                              // Back button
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
                        
                        // Adaptive spacing based on screen height
                        SizedBox(height: isOverflowing ? 50.h : 250.h),
                        
                        // Budget input widget - centered
                        Center(
                          child: ValueDisplay(
                            onBudgetChanged: (newBudget) {
                              setState(() {
                                _newBudget = newBudget;
                              });
                            },
                          ),
                        ),
                        
                        // Spacing for AI suggested budget at bottom
                        SizedBox(height: isOverflowing ? 20.h : 50.h),
                      ],
                    ),
                  ),
                ),
                
                // AI Suggested Budget widget - 20px above confirm button
                Positioned(
                  bottom: 88.h, // 68.h (button height) + 20.h (spacing)
                  left: (MediaQuery.of(context).size.width - 330.w) / 2,
                  child: const SuggestedBudgetWidget(),
                ),
                
                // Fixed confirm button at bottom
                Positioned(
                  bottom: 20.h,
                  left: 20.h,
                  right: 20.h,
                  child: ConfirmButton(
                    onPressed: _saveNewBudget,
                  ),
                ),
                
                // Loading overlay when processing
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