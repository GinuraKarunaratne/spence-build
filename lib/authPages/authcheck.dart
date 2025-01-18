import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spence/authPages/login.dart';
import 'package:spence/mainPages/home.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
        
          if (snapshot.hasData) {
            return HomeScreen();            
          } 
          
          else {
            
            return LoginScreen();
        }
      },
    )
    );

    

  }
}
