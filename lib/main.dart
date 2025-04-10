import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:spence/otherPages/editprofile.dart';
import 'package:spence/otherPages/notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for persistence
import 'theme/theme.dart';
import 'theme/theme_provider.dart';
import 'otherPages/addexpense.dart';
import 'otherPages/addrecurring.dart';
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
import 'otherpages/editbudget.dart';

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

  // Check if reminders have already been scheduled
  final prefs = await SharedPreferences.getInstance();
  final bool remindersScheduled = prefs.getBool('remindersScheduled') ?? false;

  if (!remindersScheduled) {
    // Morning message pool (7 variations)
    List<String> morningMessages = [
      'Good morning! Kick off the day with a budget check.',
      'Rise and shine! Time to peek at your expenses.',
      'Morning! Log yesterday’s spending to stay sharp.',
      'Hello there! A quick budget glance keeps you in control.',
      'Good morning! Make today a win for your wallet.',
      'Wake up! Your budget’s calling for some love.',
      'Morning vibe: Track your cash to rule the day.',
    ];

    // Noon message pool (7 variations)
    List<String> noonMessages = [
      'It’s lunchtime! Did you log your morning expenses?',
      'Midday check: How’s your spending game today?',
      'Lunch break! Time to catch up on morning buys.',
      'Noon nudge: Keep that budget fresh and updated.',
      'Halfway there! Peek at your expenses now.',
      'Lunchtime ping: Don’t skip tracking your spends.',
      'Midday memo: Log your morning cash flow.',
    ];

    // Evening message pool (7 variations)
    List<String> eveningMessages = [
      'Evening time! Log today’s expenses quick.',
      'Night check-in: Update your budget before chilling.',
      'Day’s end! Record your spending to stay on track.',
      'Evening nudge: Don’t sleep on logging your expenses.',
      'Night alert: Keep your budget tight before bed.',
      'Before you unwind, jot down today’s spends.',
      'End-of-day tip: Track expenses for a clear tomorrow.',
    ];

    // Schedule the reminders with the message pools
    NotificationService.scheduleDailyReminder(
      1,
      'Morning Reminder',
      morningMessages,
      const TimeOfDay(hour: 7, minute: 30),
    );
    NotificationService.scheduleDailyReminder(
      2,
      'Noon Reminder',
      noonMessages,
      const TimeOfDay(hour: 12, minute: 0),
    );
    NotificationService.scheduleDailyReminder(
      3,
      'Evening Reminder',
      eveningMessages,
      const TimeOfDay(hour: 17, minute: 25),
    );

    // Mark reminders as scheduled
    await prefs.setBool('remindersScheduled', true);
  }

  // Initialize Workmanager for background tasks
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
                '/editprofile': (context) => const EditProfile(),
                '/editbudget': (context) => EditBudget(),
              },
              builder: (context, child) {
                final themeMode = Provider.of<ThemeProvider>(context).themeMode;
                final overlayStyle = themeMode == ThemeMode.light
                    ? SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.dark,
                        statusBarBrightness: Brightness.dark,
                      )
                    : SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.light,
                        statusBarBrightness: Brightness.light,
                      );
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