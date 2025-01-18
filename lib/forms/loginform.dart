import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Widget _buildInputField(String label, TextEditingController controller,
      TextInputType inputType, {bool isPassword = false}) {
    return Row(
      children: [
        _buildLabel(label),
        Expanded(
          child: Container(
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFCCF20D),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: inputType,
              obscureText: isPassword && !_isPasswordVisible,
              cursorColor: Colors.black,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                suffixIcon: isPassword
                    ? GestureDetector(
                        onTap: () => setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        }),
                        child: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF1C1B1F),
                          size: 15,
                        ),
                      )
                    : null,
              ),
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  void _login() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  Widget _buildLabel(String label) {
    return Container(
      width: 115,
      height: 37,
      decoration: const BoxDecoration(color: Color(0xFFF8FDDB)),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: Text(
            label,
            style: GoogleFonts.poppins(
                color: Colors.black, fontSize: 10, fontWeight: FontWeight.w400),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadows: const [
          BoxShadow(
            color: Color.fromARGB(255, 209, 209, 209),
            blurRadius: 1,
            offset: Offset(0, 0),
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
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 25),
            _buildInputField(
                'Email Address', _emailController, TextInputType.emailAddress),
            const SizedBox(height: 12),
            _buildInputField(
                'Password', _passwordController, TextInputType.text,
                isPassword: true),
            const SizedBox(height: 20),
            Text(
              '* All previous analytics and records can be accessed after login. You will be redirected to Home Page after verification.',
              textAlign: TextAlign.justify,
              style: GoogleFonts.poppins(
                color: Colors.black38,
                fontSize: 9,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFCCF20D),
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
                    color: const Color(0xFF1C1B1F),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Login to Account',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
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
