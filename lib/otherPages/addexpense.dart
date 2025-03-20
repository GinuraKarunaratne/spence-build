import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spence/buttons/imagerecordbutton.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/widgets/budgetdisplay.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spence/forms/expenseform.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spence/services/ocrservice.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  bool _isLoading = false;
  Map<String, String>? _ocrData;
  late final OcrService _ocrService;
  final _formKey = GlobalKey<ExpenseFormState>();

  @override
  void initState() {
    super.initState();
    _ocrService = OcrService();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcessImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final extractedData = await _ocrService.processImage(image.path);
      if (extractedData != null) {
        setState(() {
          _ocrData = extractedData;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn’t extract data from the bill')),
        );
      }
    } catch (e) {
      debugPrint("OCR Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process image')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitExpense(
      String title, String amount, String category, DateTime date) async {
    if (title.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    try {
      final double expenseAmountValue = double.parse(amount);
      final batch = FirebaseFirestore.instance.batch();

      final expenseDoc =
          FirebaseFirestore.instance.collection('expenses').doc();
      batch.set(expenseDoc, {
        'amount': expenseAmountValue,
        'category': category,
        'date': date,
        'title': title,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final totExpensesDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('totExpenses')
          .doc('summary');
      batch.set(
          totExpensesDoc,
          {
            'count': FieldValue.increment(1),
            'total_expense': FieldValue.increment(expenseAmountValue),
          },
          SetOptions(merge: true));

      final budgetDoc =
          FirebaseFirestore.instance.collection('budgets').doc(userId);
      final budgetSnapshot = await budgetDoc.get();
      if (budgetSnapshot.exists) {
        batch.update(budgetDoc, {
          'used_budget': FieldValue.increment(expenseAmountValue),
          'remaining_budget': FieldValue.increment(-expenseAmountValue),
        });
      } else {
        batch.set(budgetDoc, {
          'used_budget': expenseAmountValue,
          'remaining_budget': -expenseAmountValue,
          'total_budget': 0.0,
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense recorded successfully!')),
      );
      setState(() {
        _ocrData = null;
      });
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount format')),
      );
    } catch (e) {
      debugPrint("Submit Expense Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to record expense. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    final initialTitle = arguments?['initialTitle'] ?? '';
    final initialAmount = arguments?['initialAmount'] ?? '';

    final formInitialTitle = _ocrData?['title'] ?? initialTitle;
    final formInitialAmount = _ocrData?['amount'] ?? initialAmount;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground[themeMode],
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Row(
                      children: [
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
                              icon: Icon(Icons.arrow_back_rounded,
                                  size: 20.w,
                                  color: AppColors.textColor[themeMode]),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 70.h),
                  const BudgetDisplay(),
                  SizedBox(height: 80.h),
                  ExpenseForm(
                    key: _formKey,
                    initialTitle: formInitialTitle,
                    initialAmount: formInitialAmount,
                    onSubmit: (title, amount, category, date) async {
                      setState(() => _isLoading = true);
                      try {
                        await _submitExpense(title, amount, category, date);
                        _formKey.currentState?.resetForm();
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 30.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ImageRecordButton(onPressed: _captureAndProcessImage),
                    SizedBox(width: 11.w),
                    RecordExpenseButton(onPressed: () {
                      _formKey.currentState?.submit();
                    }),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: AppColors.overlayColor[themeMode],
                  child: Center(
                    child: LoadingIndicator(
                      indicatorType: Indicator.ballPulse,
                      colors: [
                        AppColors.accentColor[themeMode] ?? Colors.grey
                      ], // Fallback to grey if null
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
