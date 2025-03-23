import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class ProfileForm extends StatefulWidget {
  final String initialFullName;
  final String initialCountry;
  final String initialCurrency;
  final Future<void> Function(String fullName, String country, String currency) onSubmit;

  const ProfileForm({
    super.key,
    this.initialFullName = '',
    this.initialCountry = '',
    this.initialCurrency = '',
    required this.onSubmit,
  });

  @override
  ProfileFormState createState() => ProfileFormState();
}

class ProfileFormState extends State<ProfileForm> {
  late TextEditingController _fullNameController;
  late TextEditingController _countryController;
  late TextEditingController _currencyController;
  String _selectedCountry = 'Sri Lanka';
  String _selectedCurrency = 'LKR';

  final List<String> _countries = [
    'Armenia', 'Australia', 'Brazil', 'Canada', 'China', 'France', 'Germany', 'India', 'Indonesia',
    'Italy', 'Japan', 'Malaysia', 'New Zealand', 'Pakistan', 'Philippines', 'Russia', 'Saudi Arabia',
    'Singapore', 'South Africa', 'South Korea', 'Spain', 'Sri Lanka', 'Thailand', 'United Kingdom',
    'United States'
  ];

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

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.initialFullName);
    _countryController = TextEditingController(text: widget.initialCountry);
    _currencyController = TextEditingController(text: widget.initialCurrency);
    _selectedCountry = widget.initialCountry.isNotEmpty ? widget.initialCountry : _selectedCountry;
    _selectedCurrency = widget.initialCurrency.isNotEmpty ? widget.initialCurrency : _selectedCurrency;
  }

  @override
  void didUpdateWidget(covariant ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFullName != oldWidget.initialFullName) {
      _fullNameController.text = widget.initialFullName;
    }
    if (widget.initialCountry != oldWidget.initialCountry) {
      _countryController.text = widget.initialCountry;
      _selectedCountry = widget.initialCountry;
    }
    if (widget.initialCurrency != oldWidget.initialCurrency) {
      _currencyController.text = widget.initialCurrency;
      _selectedCurrency = widget.initialCurrency;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _countryController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void submit() {
    widget.onSubmit(
      _fullNameController.text,
      _selectedCountry,
      _selectedCurrency,
    );
  }

  void resetForm() {
    _fullNameController.clear();
    _countryController.clear();
    _currencyController.clear();
    setState(() {
      _selectedCountry = 'Sri Lanka';
      _selectedCurrency = 'LKR';
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

  Widget _buildCountryDropdown(ThemeMode themeMode) {
    return Row(
      children: [
        _buildLabel('Country', themeMode),
        Expanded(
          child: Container(
            height: 37,
            decoration: BoxDecoration(color: AppColors.accentColor[themeMode]),
            child: DropdownButtonFormField<String>(
              value: _selectedCountry,
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
                  _selectedCountry = newValue!;
                });
              },
              items: _countries.map((value) {
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

  Widget _buildCurrencyDropdown(ThemeMode themeMode) {
    return Row(
      children: [
        _buildLabel('Currency', themeMode),
        Expanded(
          child: Container(
            height: 37,
            decoration: BoxDecoration(color: AppColors.accentColor[themeMode]),
            child: DropdownButtonFormField<String>(
              value: _selectedCurrency,
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
                  _selectedCurrency = newValue!;
                });
              },
              items: _currencies.map((value) {
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
              'Edit User Profile',
              style: GoogleFonts.poppins(
                color: AppColors.textColor[themeMode],
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
            _buildInputField(
              'Full Name',
              TextInputType.text,
              controller: _fullNameController,
              themeMode: themeMode,
            ),
            const SizedBox(height: 12),
            _buildCountryDropdown(themeMode),
            const SizedBox(height: 12),
            _buildCurrencyDropdown(themeMode),
            const SizedBox(height: 20),
            Text(
              '* Usernames and other personal details will be securely stored. Rest assured, your information will be kept private and used solely for managing your account.',
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