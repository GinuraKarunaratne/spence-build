import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'theme/theme.dart';
import 'theme/theme_provider.dart';
import 'otherPages/addexpense.dart';
import 'otherPages/addrecurring.dart';
import 'otherPages/notifications.dart';
import 'mainPages/home.dart';
import 'authPages/login.dart';
import 'authPages/signup.dart';
import 'authPages/budget.dart';
import 'mainPages/analysis.dart';
import 'mainPages/reports.dart';
import 'mainPages/recurring.dart';
import 'authPages/authcheck.dart';
import 'otherPages/allexpenses.dart';
import 'services/monthlyupdate.dart';
import 'services/recurringprocess.dart';

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
  await NotificationService.init();

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

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
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
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
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
              builder: (context, child) {
                // Access the current theme mode from ThemeProvider
                final themeMode = Provider.of<ThemeProvider>(context).themeMode;

                // Define the SystemUiOverlayStyle based on the theme mode
                final overlayStyle = themeMode == ThemeMode.light
                    ? SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.dark, // Dark icons for light mode
                        statusBarBrightness: Brightness.dark, // Dark text for iOS
                      )
                    : SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.light, // White icons for dark mode
                        statusBarBrightness: Brightness.light, // White text for iOS
                      );

                // Wrap the app with AnnotatedRegion to apply the style
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: overlayStyle,
                  child: child!,
                );
              },
              home: child,
            );
          },
        );
      },
    );
  }
}