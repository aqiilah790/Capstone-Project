import 'package:capstone_project/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone_project/login.dart';
import 'package:capstone_project/home.dart'; // Ganti dengan halaman BottomNavigationBar kamu

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          if (snapshot.data == true) {
            return const MainNavigation(); // masuk ke halaman utama dengan navbar
          } else {
            return const Login(); // jika belum login
          }
        }
      },
    );
  }
}
