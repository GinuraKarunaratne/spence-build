  import 'package:firebase_core/firebase_core.dart';
  import 'package:flutter/material.dart';
  import 'package:spence/otherPages/addexpense.dart';
  import './mainPages/home.dart';
  import './authPages/login.dart';
  import './authPages/signup.dart';
  import './authPages/budget.dart';
  import './mainPages/analysis.dart';
  import './mainPages/reports.dart';
  import './mainPages/recurring.dart';
  import './authPages/authcheck.dart';
  import './otherPages/allexpenses.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    runApp(const MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/authcheck',
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/budget': (context) => const BudgetScreen(),
          '/analysis': (context) => const AnalysisScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/recurring': (context) => const RecurringScreen(),
          '/authcheck': (context) => const AuthCheck(),
          '/addexpense': (context) => const ExpenseScreen(),
          '/allexpenses': (context) => const AllExpensesScreen(),
        },
      );
    }
  }
