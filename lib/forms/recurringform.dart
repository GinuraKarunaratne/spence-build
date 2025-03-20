import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecurringForm extends StatefulWidget {
  final void Function({
    String? title,
    String? amount,
    String? category,
    DateTime? date,
    String? repeatInterval,
  }) onFormDataChange;

  final String initialTitle;
  final String initialAmount;
  final String initialInterval;

  const RecurringForm({
    super.key,
    required this.onFormDataChange,
    this.initialTitle = '',
    this.initialAmount = '',
    this.initialInterval = '1 Month',
  });

  @override
  RecurringFormState createState() => RecurringFormState();
}

class RecurringFormState extends State<RecurringForm> {
  late final TextEditingController titleController;
  late final TextEditingController amountController;
  late final TextEditingController dateController;
  String _selectedCategory = 'Recurring Payments';
  DateTime selectedDate = DateTime.now();
  String repeatInterval = '1 Month';

  static const List<String> categories = [
    'Food & Grocery',
    'Transportation',
    'Entertainment',
    'Recurring Payments',
    'Shopping',
    'Other Expenses'
  ];

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.initialTitle);
    amountController = TextEditingController(text: widget.initialAmount);
    dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(selectedDate),
    );
    repeatInterval = widget.initialInterval;

    _triggerParentUpdate();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    dateController.dispose();
    super.dispose();
  }

  void _triggerParentUpdate() {
    widget.onFormDataChange(
      title: titleController.text,
      amount: amountController.text,
      category: _selectedCategory,
      date: selectedDate,
      repeatInterval: repeatInterval,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final themeMode = Provider.of<ThemeProvider>(context, listen: false).themeMode;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: AppColors.accentColor[themeMode],
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            scaffoldBackgroundColor: AppColors.primaryBackground[themeMode],
            dialogBackgroundColor: AppColors.primaryBackground[themeMode],
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green).copyWith(
              primary: AppColors.textColor[themeMode],
              secondary: AppColors.accentColor[themeMode],
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
        _triggerParentUpdate();
      });
    }
  }

  Widget _buildInputField(
    String label,
    TextInputType inputType, {
    required TextEditingController controller,
    bool isReadOnly = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
    EdgeInsets? contentPadding,
    required ThemeMode themeMode,
  }) {
    return Row(
      children: [
        _buildLabel(label, themeMode),
        Expanded(
          child: Container(
            height: 36.h,
            decoration: BoxDecoration(color: AppColors.accentColor[themeMode]),
            child: TextFormField(
              controller: controller,
              keyboardType: inputType,
              cursorColor: AppColors.textColor[themeMode],
              maxLines: 1,
              readOnly: isReadOnly,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: contentPadding ?? EdgeInsets.fromLTRB(14.w, 0, 14.w, 10.h),
                suffixIcon: suffixIcon,
              ),
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
                color: AppColors.textColor[themeMode],
              ),
              onChanged: (_) => _triggerParentUpdate(),
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField(ThemeMode themeMode) {
    return Row(
      children: [
        _buildLabel('Expense Category', themeMode),
        Expanded(
          child: Container(
            height: 37.h,
            decoration: BoxDecoration(color: AppColors.accentColor[themeMode]),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.iconColor[themeMode],
                size: 18.w,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(14.w, 0, 12.w, 10.h),
              ),
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
                color: AppColors.textColor[themeMode],
              ),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                  _triggerParentUpdate();
                });
              },
              items: categories.map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      color: AppColors.textColor[themeMode],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label, ThemeMode themeMode) {
    return Container(
      width: 132.w,
      height: 37.h,
      decoration: BoxDecoration(color: AppColors.budgetLabelBackground[themeMode]),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 14.w),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.alttextColor[themeMode],
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return Container(
      width: 325.w,
      decoration: ShapeDecoration(
        color: AppColors.whiteColor[themeMode],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        shadows: [
          BoxShadow(
            color: AppColors.budgetShadowColor[themeMode]!,
            blurRadius: 1.r,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 28.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ' Recurring Expense',
              style: GoogleFonts.poppins(
                color: AppColors.textColor[themeMode],
                fontSize: 17.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 30.h),
            _buildInputField(
              'Expense Title',
              TextInputType.text,
              controller: titleController,
              themeMode: themeMode,
            ),
            SizedBox(height: 12.h),
            _buildInputField(
              'Expense Amount',
              TextInputType.number,
              controller: amountController,
              themeMode: themeMode,
            ),
            SizedBox(height: 12.h),
            _buildCategoryField(themeMode),
            SizedBox(height: 12.h),
            _buildInputField(
              'Expense Date',
              TextInputType.none,
              controller: dateController,
              isReadOnly: true,
              suffixIcon: Icon(
                Icons.calendar_month_outlined,
                size: 15.w,
                color: AppColors.textColor[themeMode],
              ),
              onTap: () => _selectDate(context),
              contentPadding: EdgeInsets.fromLTRB(14.w, 5.h, 14.w, 10.h),
              themeMode: themeMode,
            ),
            SizedBox(height: 20.h),
            Text(
              '* Expenses are set to recur every 1 month by default. Recurring amount will be added to your expenses on the start of the day. Change the default interval below',
              textAlign: TextAlign.justify,
              style: GoogleFonts.poppins(
                color: AppColors.budgetNoteColor[themeMode],
                fontSize: 9.sp,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}