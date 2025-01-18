import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spence/buttons/confirmbudget.dart';
import 'package:spence/forms/budgetform.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  BudgetScreenState createState() => BudgetScreenState();
}

class BudgetScreenState extends State<BudgetScreen> {
  double _budgetAmount = 0.0;
  String _currency = '';

  @override
  void dispose() {
    super.dispose();
  }

  void _handleBudgetSubmit(double budgetAmount, String currency) {
    setState(() {
      _budgetAmount = budgetAmount;
      _currency = currency;
    });
  }

  Future<void> _saveBudgetToFirestore(BuildContext context) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      double remainingBudget = _budgetAmount;
      double usedBudget = 0.0;
      await FirebaseFirestore.instance
          .collection('budgets')
          .doc(user.uid)
          .set({
        'monthly_budget': _budgetAmount,
        'remaining_budget': remainingBudget,
        'used_budget': usedBudget,
        'currency': _currency,
        'created_at': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showErrorSnackbar(context, 'User not logged in.');
    }
  } catch (e) {
    _showErrorSnackbar(context, 'Failed to save budget: $e');
  }
}


  // Display error messages as SnackBar
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red, // Red background
        duration: const Duration(seconds: 2), // Set duration to 2 seconds
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SvgPicture.asset(
            'assets/pattern.svg',
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.cover,
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(child: Container()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                        child: Center(
                          child: BudgetForm(
                            onSubmit: _handleBudgetSubmit,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ConfirmButton(
                              onPressed: () {
                                if (_budgetAmount > 0 && _currency.isNotEmpty) {
                                  _saveBudgetToFirestore(context);
                                } else {
                                  _showErrorSnackbar(
                                    context,
                                    'Please set a valid budget and currency.',
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 45),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: _buildBody(context),
    );
  }
}
