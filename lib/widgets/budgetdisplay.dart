import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class BudgetDisplay extends StatefulWidget {
  const BudgetDisplay({super.key});

  @override
  BudgetDisplayState createState() => BudgetDisplayState();
}

class BudgetDisplayState extends State<BudgetDisplay> {
  double remainingBudget = 0.0;
  double usedBudget = 0.0;
  String userId = '';
  String currency = 'Rs';

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      _fetchBudgetData(userId);
    }
  }

  Future<void> _fetchBudgetData(String userId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('budgets')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          remainingBudget = (docSnapshot['remaining_budget'] ?? 0.0).toDouble();
          usedBudget = (docSnapshot['used_budget'] ?? 0.0).toDouble();
          currency = docSnapshot['currency'] ?? 'Rs';
        });
      } else {
        setState(() {
          remainingBudget = 0.0;
          usedBudget = 0.0;
        });
      }
    } catch (e) {
      // Optionally handle/log error
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    // StreamBuilder to allow real-time updates if desired:
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('budgets')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
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
        remainingBudget = (data['remaining_budget'] ?? 0.0).toDouble();
        usedBudget = (data['used_budget'] ?? 0.0).toDouble();
        currency = data['currency'] ?? 'Rs';

        return Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRemainingBudgetDisplay(context),
              const SizedBox(height: 10),
              _buildUsedBudgetSection(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRemainingBudgetDisplay(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    // Convert remainingBudget to a string
    final bool isNegative = remainingBudget < 0;
    final double absoluteValue = isNegative ? -remainingBudget : remainingBudget;
    final String absString = absoluteValue.toStringAsFixed(2);

    // Adjust big font size based on length
    double fontSize = MediaQuery.of(context).size.width * 0.15;
    if (absString.length > 9) {
      fontSize = MediaQuery.of(context).size.width * 0.12;
    }

    final Color? mainColor = isNegative
        ? AppColors.textColor[themeMode]
        : AppColors.textColor[themeMode];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Currency label
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
        // If negative, show a small sign, then the big number
        if (isNegative) ...[
          Text(
            '-',
            style: GoogleFonts.urbanist(
              color: mainColor,
              fontSize: fontSize * 0.4, // half the size for the sign
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        Text(
          absString, // the absolute value
          style: GoogleFonts.urbanist(
            color: mainColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildUsedBudgetSection(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    final double totalBudget = usedBudget + remainingBudget;
    final bool isExceeded = usedBudget > totalBudget;

    // "Used Budget" label
    final labelContainer = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.budgetLabelBackground[themeMode],
      ),
      child: Text(
        'Used Budget',
        style: GoogleFonts.poppins(
          color: AppColors.alttextColor[themeMode],
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
    );

    // The used amount
    final usedBudgetContainer = Container(
      width: MediaQuery.of(context).size.width * 0.3,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.accentColor[themeMode],
      ),
      alignment: Alignment.centerRight, // Align to the right
      child: Text(
        '$currency ${usedBudget.toStringAsFixed(2)}',
        textAlign: TextAlign.right,
        style: GoogleFonts.poppins(
          color: AppColors.textColor[themeMode],
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
    );

    // Warning icon container
    final warningIconContainer = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.errorBackground[themeMode],
      ),
      child: Icon(
        Icons.warning_amber_rounded,
        size: 17,
        color: AppColors.errorIcon[themeMode],
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        labelContainer,
        usedBudgetContainer,
        if (isExceeded) ...[
          const SizedBox(width: 0),
          warningIconContainer,
        ],
      ],
    );
  }
}