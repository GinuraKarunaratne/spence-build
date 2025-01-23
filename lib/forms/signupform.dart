import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupForm extends StatefulWidget {
  final Function(String fullName, String email, String password, String country) onSubmit;

  const SignupForm({super.key, required this.onSubmit});

  @override
  SignupFormState createState() => SignupFormState();
}

class SignupFormState extends State<SignupForm> {
  String _selectedCountry = 'Sri Lanka';
  String fullName = '', email = '', password = '';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _createAccount() async {
    if (fullNameController.text.isEmpty) {
      _showSnackBar('Please enter Full Name');
      return;
    }
    if (emailController.text.isEmpty) {
      _showSnackBar('Please enter Email Address');
      return;
    }
    if (passwordController.text.isEmpty) {
      _showSnackBar('Please enter Password');
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      try {
        // Create user in Firebase Auth
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final userId = userCredential.user?.uid;
        if (userId == null) throw Exception("Failed to retrieve user ID");

        // Save user details to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fullName': fullName,
          'email': email,
          'country': _selectedCountry,
          'createdAt': DateTime.now(),
        });

        // Redirect to /budget
        Navigator.pushNamed(context, '/budget');
      } catch (e) {
        // Show error with SnackBar
        _showSnackBar('Error: ${e.toString()}');
      }
    }
  }

  Widget _buildInputField(String label, TextInputType inputType, {TextEditingController? controller}) {
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
              obscureText: label == 'Password',
              cursorColor: Colors.black,
              maxLines: 1,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(14, 0, 14, 10),
              ),
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.black),
              validator: (value) => value?.isEmpty ?? true ? 'This field cannot be empty' : null,
              onSaved: (value) {
                if (label == 'Full Name') fullName = value ?? '';
                if (label == 'Email Address') email = value ?? '';
                if (label == 'Password') password = value ?? '';
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryField() {
    return Row(
      children: [
        _buildLabel('Country'),
        Expanded(
          child: Container(
            height: 37,
            decoration: const BoxDecoration(color: Color(0xFFCCF20D)),
            child: DropdownButtonFormField<String>(
              value: _selectedCountry,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1C1B1F)),
              iconSize: 18,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(14, 0, 12, 10),
              ),
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.black),
              validator: (value) => value == null ? 'Please select a country' : null,
              onChanged: (newValue) {
                setState(() {
                  _selectedCountry = newValue!;
                });
              },
              items: [
                'Armenia', 'Australia', 'Brazil', 'Canada', 'China', 'France', 'Germany', 'India', 'Indonesia',
                'Italy', 'Japan', 'Malaysia', 'New Zealand', 'Pakistan', 'Philippines', 'Russia', 'Saudi Arabia',
                'Singapore', 'South Africa', 'South Korea', 'Spain', 'Sri Lanka', 'Thailand', 'United Kingdom',
                'United States'
              ].map((value) {
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
      width: 115,
      height: 37,
      decoration: const BoxDecoration(color: Color(0xFFF8FDDB)),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: Text(label, style: GoogleFonts.poppins(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w400)),
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
        shadows: const [
          BoxShadow(color: Color.fromARGB(255, 209, 209, 209), blurRadius: 1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 28.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join Spence Today', style: GoogleFonts.poppins(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w500)),
              const SizedBox(height: 30),
              _buildInputField('Full Name', TextInputType.name, controller: fullNameController),
              const SizedBox(height: 12),
              _buildInputField('Email Address', TextInputType.emailAddress, controller: emailController),
              const SizedBox(height: 12),
              _buildCountryField(),
              const SizedBox(height: 12),
              _buildInputField('Password', TextInputType.visiblePassword, controller: passwordController),
              const SizedBox(height: 20),
              Text(
                '* Passwords entered, usernames collected, and email addresses provided will be securely stored. '
                'Your information will remain private and used for account-related purposes.',
                textAlign: TextAlign.justify,
                style: GoogleFonts.poppins(color: Colors.black38, fontSize: 9, fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createAccount,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFCCF20D),
                  padding: const EdgeInsets.symmetric(horizontal: 78.5, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(700)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_alt_outlined, size: 18, color: Color(0xFF1C1B1F)),
                    const SizedBox(width: 7),
                    Text('Create An Account', style: GoogleFonts.poppins(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}