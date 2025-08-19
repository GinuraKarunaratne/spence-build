import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class ValueDisplay extends StatefulWidget {
  final Function(double) onBudgetChanged;

  const ValueDisplay({super.key, required this.onBudgetChanged});

  @override
  ValueDisplayState createState() => ValueDisplayState();
}

class ValueDisplayState extends State<ValueDisplay> {
  String userId = '';
  bool isEditing = false;
  final TextEditingController _budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  // Retrieve current user data
  Future<void> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    // Show loading if user data isn't ready
    if (userId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('budgets')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        // Handle no data or non-existent document
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(
              'No Budget Data Available',
              style: GoogleFonts.poppins(
                color: AppColors.secondaryTextColor[themeMode],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final double monthlyBudget = (data['monthly_budget'] ?? 0.0).toDouble();
        final String currency = data['currency'] ?? 'Rs';

        return GestureDetector(
          onTap: () {
            setState(() {
              isEditing = true;
              _budgetController.text = monthlyBudget.toStringAsFixed(2);
            });
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isEditing
                    ? _buildEditableBudget(context, monthlyBudget, currency)
                    : _buildMonthlyBudgetDisplay(context, monthlyBudget, currency),
              ],
            ),
          ),
        );
      },
    );
  }

  // Editable budget input widget
  Widget _buildEditableBudget(BuildContext context, double monthlyBudget, String currency) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Currency symbol
        Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Text(
            currency,
            style: GoogleFonts.urbanist(
              color: AppColors.budgettextColor[themeMode],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 3),
        
        // Budget input field
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.urbanist(
              fontSize: MediaQuery.of(context).size.width * 0.15,
              color: AppColors.textColor[themeMode],
              fontWeight: FontWeight.w400,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
            textAlign: TextAlign.center,
            // Real-time budget change notification
            onChanged: (value) {
              final newBudget = double.tryParse(value) ?? monthlyBudget;
              widget.onBudgetChanged(newBudget);
            },
            // Exit edit mode on submit
            onSubmitted: (value) {
              setState(() {
                isEditing = false;
              });
            },
          ),
        ),
      ],
    );
  }

  // Display current budget with future budget info
  Widget _buildMonthlyBudgetDisplay(BuildContext context, double monthlyBudget, String currency) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    final textColor = AppColors.textColor[themeMode];
    final secondaryTextColor = AppColors.secondaryTextColor[themeMode];

    // Handle negative values
    final bool isNegative = monthlyBudget < 0;
    final double absoluteValue = isNegative ? -monthlyBudget : monthlyBudget;
    final String absString = absoluteValue.toStringAsFixed(2);

    // Responsive font sizing
    double fontSize = MediaQuery.of(context).size.width * 0.15;
    if (absString.length > 9) {
      fontSize = MediaQuery.of(context).size.width * 0.12;
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('budgets')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        Widget? futureBudgetWidget;
        
        // Check for pending budget updates
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final newBudget = (data['new_budget'] as num?)?.toDouble();
          final updateTimestamp = data['budget_update_date'] as Timestamp?;
          
          // Build future budget display if scheduled update exists
          if (newBudget != null && updateTimestamp != null) {
            final updateDate = updateTimestamp.toDate();
            futureBudgetWidget = Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  // Future budget label with effective date
                  Text(
                    'Future Budget (from ${updateDate.day}/${updateDate.month}/${updateDate.year}):',
                    style: GoogleFonts.poppins(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  
                  // Future budget amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currency,
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        newBudget.toStringAsFixed(2),
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        }
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current budget label
            Text(
              'Current Budget',
              style: GoogleFonts.poppins(
                color: secondaryTextColor,
                fontSize: 14,
              ),
            ),
            
            // Current budget amount display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Currency symbol
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    currency,
                    style: GoogleFonts.urbanist(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                
                // Negative sign for negative values
                if (isNegative)
                  Text(
                    '-',
                    style: GoogleFonts.urbanist(
                      color: textColor,
                      fontSize: fontSize * 0.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                
                // Budget amount
                Text(
                  absString,
                  style: GoogleFonts.urbanist(
                    fontSize: fontSize,
                    color: textColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            
            // Future budget widget if available
            if (futureBudgetWidget != null) futureBudgetWidget,
          ],
        );
      },
    );
  }
}