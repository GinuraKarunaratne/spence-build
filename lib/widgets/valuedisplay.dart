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

    if (userId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('budgets').doc(userId).snapshots(),
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

  Widget _buildEditableBudget(BuildContext context, double monthlyBudget, String currency) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
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
            // Update on every change
            onChanged: (value) {
              final newBudget = double.tryParse(value) ?? monthlyBudget;
              widget.onBudgetChanged(newBudget);
            },
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

  Widget _buildMonthlyBudgetDisplay(BuildContext context, double monthlyBudget, String currency) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    final bool isNegative = monthlyBudget < 0;
    final double absoluteValue = isNegative ? -monthlyBudget : monthlyBudget;
    final String absString = absoluteValue.toStringAsFixed(2);

    double fontSize = MediaQuery.of(context).size.width * 0.15;
    if (absString.length > 9) {
      fontSize = MediaQuery.of(context).size.width * 0.12;
    }

    final Color? mainColor = AppColors.textColor[themeMode];

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
        if (isNegative)
          Text(
            '-',
            style: GoogleFonts.urbanist(
              color: mainColor,
              fontSize: fontSize * 0.4,
              fontWeight: FontWeight.w400,
            ),
          ),
        Text(
          absString,
          style: GoogleFonts.urbanist(
            color: mainColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
