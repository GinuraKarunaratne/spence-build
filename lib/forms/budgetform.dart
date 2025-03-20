import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class BudgetForm extends StatefulWidget {
  final Function(double budget, String currency) onSubmit;

  const BudgetForm({super.key, required this.onSubmit});

  @override
  BudgetFormState createState() => BudgetFormState();
}

class BudgetFormState extends State<BudgetForm> {
  String _selectedCurrency = 'LKR';
  double _monthlyBudget = 0.0;

  final List<String> _currencies = [
    'AED', 'AFN', 'ALL', 'AMD', 'ANG', 'AOA', 'ARS', 'AUD', 'AWG', 'AZN',
    'BAM', 'BBD', 'BDT', 'BGN', 'BHD', 'BIF', 'BMD', 'BND', 'BOB', 'BRL',
    'BSD', 'BTN', 'BWP', 'BYN', 'BZD', 'CAD', 'CDF', 'CHF', 'CLP', 'CNY',
    'COP', 'CRC', 'CUP', 'CVE', 'CZK', 'DJF', 'DKK', 'DOP', 'DZD', 'EGP',
    'ERN', 'ETB', 'EUR', 'FJD', 'FKP', 'FOK', 'GBP', 'GEL', 'GHS', 'GIP',
    'GMD', 'GNF', 'GTQ', 'GYD', 'HKD', 'HNL', 'HRK', 'HTG', 'HUF', 'IDR',
    'ILS', 'INR', 'IQD', 'IRR', 'ISK', 'JMD', 'JOD', 'JPY', 'KES', 'KGS',
    'KHR', 'KMF', 'KPW', 'KRW', 'KWD', 'KYD', 'KZT', 'LAK', 'LBP', 'LKR',
    'LRD', 'LSL', 'LTL', 'LVL', 'LYD', 'MAD', 'MDL', 'MGA', 'MKD', 'MMK',
    'MNT', 'MOP', 'MRO', 'MRU', 'MUR', 'MVR', 'MWK', 'MXN', 'MYR', 'MZN',
    'NAD', 'NGN', 'NIO', 'NPR', 'NZD', 'OMR', 'PAB', 'PEN', 'PGK', 'PHP',
    'PKR', 'PLN', 'PRB', 'PYG', 'QAR', 'RON', 'RSD', 'RUB', 'RWF', 'SAR',
    'SBD', 'SCR', 'SDG', 'SEK', 'SGD', 'SHP', 'SLL', 'SOS', 'SRD', 'SSP',
    'STN', 'SYP', 'SZL', 'THB', 'TJS', 'TMT', 'TND', 'TOP', 'TRY', 'TTD',
    'TWD', 'TZS', 'UAH', 'UGX', 'USD', 'UYU', 'UZS', 'VEF', 'VND', 'VUV',
    'WST', 'XAF', 'XCD', 'XOF', 'XPF', 'YER', 'ZAR', 'ZMW', 'ZWL'
  ];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _budgetController = TextEditingController();
  Timer? _debounce;

  Widget _buildInputField({
    required String label,
    required TextInputType inputType,
    required Function(String) onChanged,
    TextEditingController? controller,
    bool isCustomField = false,
    Widget? customField,
    required ThemeMode themeMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          _buildLabel(label, themeMode),
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(color: AppColors.accentColor[themeMode]),
              child: isCustomField
                  ? customField
                  : TextFormField(
                      controller: controller,
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 100), () {
                          onChanged(value);
                        });
                      },
                      keyboardType: inputType,
                      cursorColor: AppColors.textColor[themeMode],
                      maxLines: 1,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.fromLTRB(14, 0, 14, 10),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textColor[themeMode],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field cannot be empty';
                        }
                        if (inputType == TextInputType.number && double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, ThemeMode themeMode) {
    return Container(
      width: 115,
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

  Widget _buildCurrencyDropdown(ThemeMode themeMode) {
    final currentCurrency = _currencies.contains(_selectedCurrency) ? _selectedCurrency : _currencies[0];
    return _buildInputField(
      label: 'Currency',
      inputType: TextInputType.none,
      isCustomField: true,
      onChanged: (_) {},
      themeMode: themeMode,
      customField: DropdownButton<String>(
        value: currentCurrency,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.iconColor[themeMode],
        ),
        iconSize: 18,
        elevation: 1,
        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
        isExpanded: true,
        dropdownColor: AppColors.accentColor[themeMode],
        underline: const SizedBox.shrink(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: AppColors.textColor[themeMode],
        ),
        onChanged: (newValue) {
          if (newValue != null) {
            setState(() {
              _selectedCurrency = newValue;
            });
            widget.onSubmit(_monthlyBudget, _selectedCurrency);
          }
        },
        items: _currencies.map((currency) {
          return DropdownMenuItem<String>(
            value: currency,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
              child: Text(
                currency,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textColor[themeMode],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return Container(
      width: 325,
      decoration: ShapeDecoration(
        color: AppColors.whiteColor[themeMode],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadows: [
          BoxShadow(
            color: AppColors.budgetShadowColor[themeMode]!,
            blurRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 25.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Monthly Budget',
                style: GoogleFonts.poppins(
                  color: AppColors.textColor[themeMode],
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 25),
              _buildInputField(
                label: 'Monthly Budget',
                inputType: TextInputType.number,
                controller: _budgetController,
                onChanged: (value) {
                  final parsedValue = double.tryParse(value) ?? 0.0;
                  setState(() {
                    _monthlyBudget = parsedValue;
                  });
                  widget.onSubmit(_monthlyBudget, _selectedCurrency);
                },
                themeMode: themeMode,
              ),
              _buildCurrencyDropdown(themeMode),
              const SizedBox(height: 10),
              Text(
                '* This Monthly Budget amount and currency will recur every month until manually changed.',
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
      ),
    );
  }
}