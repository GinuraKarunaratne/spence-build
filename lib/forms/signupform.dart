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

  Future<void> _createAccount() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInputField(String label, TextInputType inputType,
      {TextEditingController? controller}) {
    return Row(
      children: [
        _buildLabel(label),
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFFCCF20D)),
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
              validator: (value) =>
                  value?.isEmpty ?? true ? 'This field cannot be empty' : null,
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
            decoration: BoxDecoration(color: const Color(0xFFCCF20D)),
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
                  'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Antigua and Barbuda',
                  'Argentina', 'Armenia', 'Australia', 'Austria', 'Azerbaijan', 'Bahamas', 
                  'Bahrain', 'Bangladesh', 'Barbados', 'Belarus', 'Belgium', 'Belize', 'Benin', 
                  'Bhutan', 'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei', 
                  'Bulgaria', 'Burkina Faso', 'Burundi', 'Cabo Verde', 'Cambodia', 'Cameroon', 
                  'Canada', 'Central African Republic', 'Chad', 'Chile', 'China', 'Colombia', 
                  'Comoros', 'Congo (Congo-Brazzaville)', 'Congo (Democratic Republic) (Congo-Kinshasa)', 
                  'Costa Rica', 'Croatia', 'Cuba', 'Cyprus', 'Czech Republic (Czechia)', 'Denmark', 
                  'Djibouti', 'Dominica', 'Dominican Republic', 'Ecuador', 'Egypt', 'El Salvador', 
                  'Equatorial Guinea', 'Eritrea', 'Estonia', 'Eswatini', 'Ethiopia', 'Fiji', 
                  'Finland', 'France', 'Gabon', 'Gambia', 'Georgia', 'Germany', 'Ghana', 'Greece', 
                  'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana', 'Haiti', 'Honduras', 
                  'Hungary', 'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel', 
                  'Italy', 'Jamaica', 'Japan', 'Jordan', 'Kazakhstan', 'Kenya', 'Kiribati', 'Korea (North)', 
                  'Korea (South)', 'Kuwait', 'Kyrgyzstan', 'Laos', 'Latvia', 'Lebanon', 'Lesotho', 
                  'Liberia', 'Libya', 'Liechtenstein', 'Lithuania', 'Luxembourg', 'Madagascar', 
                  'Malawi', 'Malaysia', 'Maldives', 'Mali', 'Malta', 'Marshall Islands', 'Mauritania', 
                  'Mauritius', 'Mexico', 'Micronesia', 'Moldova', 'Monaco', 'Mongolia', 'Montenegro', 
                  'Morocco', 'Mozambique', 'Myanmar (Burma)', 'Namibia', 'Nauru', 'Nepal', 'Netherlands', 
                  'New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'North Macedonia', 'Norway', 'Oman', 
                  'Pakistan', 'Palau', 'Panama', 'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 
                  'Poland', 'Portugal', 'Qatar', 'Romania', 'Russia', 'Rwanda', 'Saint Kitts and Nevis', 
                  'Saint Lucia', 'Saint Vincent and the Grenadines', 'Samoa', 'San Marino', 'Sao Tome and Principe', 
                  'Saudi Arabia', 'Senegal', 'Serbia', 'Seychelles', 'Sierra Leone', 'Singapore', 
                  'Slovakia', 'Slovenia', 'Solomon Islands', 'Somalia', 'South Africa', 'South Sudan', 
                  'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden', 'Switzerland', 'Syria', 'Taiwan', 
                  'Tajikistan', 'Tanzania', 'Thailand', 'Timor-Leste', 'Togo', 'Tonga', 'Trinidad and Tobago', 
                  'Tunisia', 'Turkey', 'Turkmenistan', 'Tuvalu', 'Uganda', 'Ukraine', 'United Arab Emirates', 
                  'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan', 'Vanuatu', 'Vatican City', 
                  'Venezuela', 'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe',
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
      decoration: BoxDecoration(color: const Color(0xFFF8FDDB)),
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
        shadows: [
          BoxShadow(color: const Color.fromARGB(255, 209, 209, 209), blurRadius: 1),
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