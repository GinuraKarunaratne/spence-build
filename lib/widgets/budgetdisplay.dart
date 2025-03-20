import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class BudgetDisplay extends StatefulWidget {
  const BudgetDisplay({super.key});

  @override
  BudgetDisplayState createState() => BudgetDisplayState();
}

class BudgetDisplayState extends State<BudgetDisplay>
    with SingleTickerProviderStateMixin {
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
    } else {
      // Handle user not logged in scenario
    }
  }

  Future<void> _fetchBudgetData(String userId) async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('budgets')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          remainingBudget = docSnapshot['remaining_budget']?.toDouble() ?? 0.0;
          usedBudget = docSnapshot['used_budget']?.toDouble() ?? 0.0;
          currency = docSnapshot['currency'] ?? 'Rs';
        });
      } else {
        setState(() {
          remainingBudget = 0.0;
          usedBudget = 0.0;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('budgets')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitThreeBounce(
              color: AppColors.spinnerColor[themeMode],
              size: 40.0,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(
                color: AppColors.errorColor[themeMode],
              ),
            ),
          );
        }

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

        var budgetData = snapshot.data!;
        remainingBudget = budgetData['remaining_budget']?.toDouble() ?? 0.0;
        usedBudget = budgetData['used_budget']?.toDouble() ?? 0.0;
        currency = budgetData['currency'] ?? 'Rs';

        return Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRemainingBudgetDisplay(),
              _buildUsedBudgetSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRemainingBudgetDisplay() {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    double fontSize = MediaQuery.of(context).size.width * 0.15;
    if (remainingBudget.toString().length > 9) {
      fontSize = MediaQuery.of(context).size.width * 0.12;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
        Text(
          remainingBudget.toStringAsFixed(2),
          style: GoogleFonts.urbanist(
            color: AppColors.textColor[themeMode],
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildUsedBudgetSection() {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
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
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.3,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.accentColor[themeMode],
          ),
          alignment: Alignment.centerRight,
          child: Text(
            '$currency ${usedBudget.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              color: AppColors.textColor[themeMode],
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}