import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';
import 'package:spence/services/ml_services.dart';

class ExpenseForm extends StatefulWidget {
  final String initialTitle;
  final String initialAmount;
  final Future<void> Function(String title, String amount, String category, DateTime date) onSubmit;

  const ExpenseForm({
    super.key,
    this.initialTitle = '',
    this.initialAmount = '',
    required this.onSubmit,
  });

  @override
  ExpenseFormState createState() => ExpenseFormState();
}

class ExpenseFormState extends State<ExpenseForm> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  String _selectedCategory = 'Food & Grocery';
  DateTime _selectedDate = DateTime.now();

  static const List<String> categories = [
    'Food & Grocery',
    'Transportation',
    'Entertainment',
    'Recurring Payments',
    'Shopping',
    'Other Expenses',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _amountController = TextEditingController(text: widget.initialAmount);
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
    
    // Add listener for smart categorization
    _titleController.addListener(_onTitleChanged);
    
    // Predict category if initial title is provided
    if (widget.initialTitle.isNotEmpty) {
      _predictAndSetCategory(widget.initialTitle);
    }
  }

  void _onTitleChanged() {
    // Debounce the categorization to avoid too many predictions
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_titleController.text.isNotEmpty) {
        _predictAndSetCategory(_titleController.text);
      }
    });
  }

  void _predictAndSetCategory(String description) {
    final predictedCategory = MLServices.predictCategory(description);
    if (predictedCategory != _selectedCategory && categories.contains(predictedCategory)) {
      setState(() {
        _selectedCategory = predictedCategory;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ExpenseForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTitle != oldWidget.initialTitle) {
      _titleController.text = widget.initialTitle;
    }
    if (widget.initialAmount != oldWidget.initialAmount) {
      _amountController.text = widget.initialAmount;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final themeMode = Provider.of<ThemeProvider>(context, listen: false).themeMode;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  void submit() {
    widget.onSubmit(
      _titleController.text,
      _amountController.text,
      _selectedCategory,
      _selectedDate,
    );
  }

  void resetForm() {
    _titleController.clear();
    _amountController.clear();
    setState(() {
      _selectedCategory = 'Food & Grocery';
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    });
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
            height: 36,
            decoration: BoxDecoration(color: AppColors.accentColor[themeMode]),
            child: TextFormField(
              controller: controller,
              keyboardType: inputType,
              cursorColor: AppColors.textColor[themeMode],
              maxLines: 1,
              readOnly: isReadOnly,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: contentPadding ?? const EdgeInsets.fromLTRB(14, 0, 14, 10),
                suffixIcon: suffixIcon,
              ),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textColor[themeMode],
              ),
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
            height: 37,
            decoration: BoxDecoration(color: AppColors.accentColor[themeMode]),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.iconColor[themeMode],
                size: 18,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(14, 0, 12, 10),
              ),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textColor[themeMode],
              ),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: categories.map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
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
      width: 132,
      height: 37,
      decoration: BoxDecoration(color: AppColors.budgetLabelBackground[themeMode]),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.alttextColor[themeMode],
              fontSize: 10,
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
      width: 325,
      decoration: ShapeDecoration(
        color: AppColors.whiteColor[themeMode],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadows: [
          BoxShadow(
            color: AppColors.budgetShadowColor[themeMode]!,
            blurRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ' Record Expense',
              style: GoogleFonts.poppins(
                color: AppColors.textColor[themeMode],
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
            _buildInputField(
              'Expense Title',
              TextInputType.text,
              controller: _titleController,
              themeMode: themeMode,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              'Expense Amount',
              TextInputType.number,
              controller: _amountController,
              themeMode: themeMode,
            ),
            const SizedBox(height: 12),
            _buildCategoryField(themeMode),
            const SizedBox(height: 12),
            _buildInputField(
              'Expense Date',
              TextInputType.none,
              controller: _dateController,
              isReadOnly: true,
              suffixIcon: Icon(
                Icons.calendar_month_outlined,
                size: 15,
                color: AppColors.textColor[themeMode],
              ),
              onTap: () => _selectDate(context),
              contentPadding: const EdgeInsets.fromLTRB(14, 5, 14, 10),
              themeMode: themeMode,
            ),
            const SizedBox(height: 20),
            Text(
              '* You can leave Expense Date empty to record today. Recorded expenses can\'t be undone and will be continued for the rest of the month.',
              textAlign: TextAlign.justify,
              style: GoogleFonts.poppins(
                color: AppColors.budgetNoteColor[themeMode],
                fontSize: 9,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}