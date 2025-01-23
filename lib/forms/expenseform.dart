import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ExpenseForm extends StatefulWidget {
  final void Function({
    String? title,
    String? amount,
    String? category,
    DateTime? date,
  }) onFormDataChange;

  final String initialTitle;
  final String initialAmount;

  const ExpenseForm({
    super.key,
    required this.onFormDataChange,
    this.initialTitle = '',
    this.initialAmount = '',
  });

  @override
  ExpenseFormState createState() => ExpenseFormState();
}

class ExpenseFormState extends State<ExpenseForm> {
  late final TextEditingController titleController;
  late final TextEditingController amountController;
  late final TextEditingController dateController;
  String _selectedCategory = 'Food & Grocery';
  DateTime selectedDate = DateTime.now();

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
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: const Color(0xFFCCF20D),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            scaffoldBackgroundColor: const Color(0xFFf2f2f2),
            dialogBackgroundColor: const Color(0xFFf2f2f2),
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green).copyWith(
              primary: const Color(0xFF000000),
              secondary: const Color(0xFFCCF20D),
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
  }) {
    return Row(
      children: [
        _buildLabel(label),
        Expanded(
          child: Container(
            height: 36,
            decoration: const BoxDecoration(color: Color(0xFFCCF20D)),
            child: TextFormField(
              controller: controller,
              keyboardType: inputType,
              cursorColor: Colors.black,
              maxLines: 1,
              readOnly: isReadOnly,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: contentPadding ?? const EdgeInsets.fromLTRB(14, 0, 14, 10),
                suffixIcon: suffixIcon,
              ),
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.black),
              onChanged: (_) => _triggerParentUpdate(),
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Row(
      children: [
        _buildLabel('Expense Category'),
        Expanded(
          child: Container(
            height: 37,
            decoration: const BoxDecoration(color: Color(0xFFCCF20D)),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1C1B1F)),
              iconSize: 18,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(14, 0, 12, 10),
              ),
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.black),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                  _triggerParentUpdate();
                });
              },
              items: categories.map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: GoogleFonts.poppins(fontSize: 10, color: Colors.black)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Container(
      width: 132,
      height: 37,
      decoration: const BoxDecoration(color: Color(0xFFF8FDDB)),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.black,
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
    return Container(
      width: 325,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadows: [
          BoxShadow(color: const Color.fromARGB(255, 209, 209, 209), blurRadius: 1),
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
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
            _buildInputField('Expense Title', TextInputType.text, controller: titleController),
            const SizedBox(height: 12),
            _buildInputField('Expense Amount', TextInputType.number, controller: amountController),
            const SizedBox(height: 12),
            _buildCategoryField(),
            const SizedBox(height: 12),
            _buildInputField(
              'Expense Date',
              TextInputType.none,
              controller: dateController,
              isReadOnly: true,
              suffixIcon: const Icon(Icons.calendar_month_outlined, size: 15, color: Colors.black),
              onTap: () => _selectDate(context),
              contentPadding: const EdgeInsets.fromLTRB(14, 5, 14, 10),
            ),
            const SizedBox(height: 20),
            Text(
              '* You can leave Expense Date empty to record today. Recorded expenses can\'t be undone and will be continued for the rest of the month.',
              textAlign: TextAlign.justify,
              style: GoogleFonts.poppins(
                color: Colors.black38,
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