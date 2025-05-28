// lib/views/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_screen.dart'; // Sesuaikan path ini

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      // Navigasi ke halaman login setelah splash
      Get.off(() => const LoginScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF399918),
      body: Center(
        child: Image.asset('images/LogoBetter-nak.png', width: 300),
      ),
    );
  }
}
