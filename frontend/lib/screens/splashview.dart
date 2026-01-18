import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:nepalmentors/screens/login.dart';

class MySplash extends StatefulWidget {
  const MySplash({super.key});

  @override
  MySplashState createState() => MySplashState();
}

class MySplashState extends State<MySplash> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 8), () {
      Get.off(() => const LoginScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black, // Optional: Background color for padding areas
          ),
          child: Center(
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain, // Adjust as needed (contain, cover, etc.)
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
        ),
      ),
    );
  }
}
