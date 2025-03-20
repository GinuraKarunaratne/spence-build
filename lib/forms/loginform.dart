import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    TextInputType inputType, {
    bool isPassword = false,
    EdgeInsets? contentPadding,
    required ThemeMode themeMode,
  }) {
    return Row(
      children: [
        _buildLabel(label, themeMode),
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentColor[themeMode],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: inputType,
              obscureText: isPassword && !_isPasswordVisible,
              cursorColor: AppColors.textColor[themeMode],
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: contentPadding ?? const EdgeInsets.fromLTRB(14, 0, 14, 10),
                suffixIcon: isPassword
                    ? GestureDetector(
                        onTap: () => setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        }),
                        child: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.iconColor[themeMode],
                          size: 15,
                        ),
                      )
                    : null,
              ),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textColor[themeMode],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, ThemeMode themeMode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: AppColors.whiteColor[themeMode],
            fontSize: 12,
          ),
        ),
        backgroundColor: AppColors.errorColor[themeMode],
      ),
    );
  }

  Future<void> _login() async {
    final themeMode = Provider.of<ThemeProvider>(context, listen: false).themeMode;

    if (_emailController.text.isEmpty) {
      _showSnackBar('Please enter Email Address', themeMode);
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showSnackBar('Please enter Password', themeMode);
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      _showSnackBar('Login failed: ${e.toString()}', themeMode);
    }
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
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back',
              style: GoogleFonts.poppins(
                color: AppColors.textColor[themeMode],
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 25),
            _buildInputField(
              'Email Address',
              _emailController,
              TextInputType.emailAddress,
              themeMode: themeMode,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              'Password',
              _passwordController,
              TextInputType.text,
              isPassword: true,
              contentPadding: const EdgeInsets.fromLTRB(14, 5, 14, 10),
              themeMode: themeMode,
            ),
            const SizedBox(height: 20),
            Text(
              '* All previous analytics and records can be accessed after login. You will be redirected to Home Page after verification.',
              textAlign: TextAlign.justify,
              style: GoogleFonts.poppins(
                color: AppColors.budgetNoteColor[themeMode],
                fontSize: 9,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.accentColor[themeMode],
                padding: const EdgeInsets.symmetric(horizontal: 85, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(700),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 18,
                    color: AppColors.iconColor[themeMode],
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Login to Account',
                    style: GoogleFonts.poppins(
                      color: AppColors.textColor[themeMode],
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}