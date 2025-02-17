import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spence/otherPages/addexpense.dart';
import 'package:spence/otherPages/addrecurring.dart';
import './mainPages/home.dart';
import './authPages/login.dart';
import './authPages/signup.dart';
import './authPages/budget.dart';
import './mainPages/analysis.dart';
import './mainPages/reports.dart';
import './mainPages/recurring.dart';
import './authPages/authcheck.dart';
import './otherPages/allexpenses.dart';
import './services/monthlyupdate.dart';
import 'package:workmanager/workmanager.dart';
import './services/recurringprocess.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final userId = inputData?['userId'];

    if (userId != null) {
      await processRecurringExpenses(userId);
    }

    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    final String userId = currentUser.uid;

    await checkAndUpdateMonthlyBudget();

    await Workmanager().initialize(callbackDispatcher);

    Workmanager().registerPeriodicTask(
      "checkRecurringExpenses",
      "checkRecurringExpensesTask",
      inputData: {'userId': userId},
      frequency: const Duration(hours: 24),
    );
  } else {
    debugPrint("No user is currently logged in. Skipping background task setup.");
  }

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: const Color.fromARGB(0, 242, 242, 242),
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 815),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            textTheme: GoogleFonts.poppinsTextTheme(),
            scaffoldBackgroundColor: const Color(0xFFF2F2F2),
          ),
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
            '/addrecurring': (context) => const AddRecurringScreen(),
          },
          home: child,
        );
      },
    );
  }
}