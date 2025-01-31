import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoot/screens/home_screen.dart';
import 'login_screen.dart';

class AuthStateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          return user == null ? LoginScreen() : HomeScreen();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
