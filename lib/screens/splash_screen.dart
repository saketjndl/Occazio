import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSplashSequence();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel(); // Cancel any running timer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startSplashSequence(shortDelay: true); // Faster check on resume
    }
  }

  void _startSplashSequence({bool shortDelay = false}) {
    // Cancel any existing timer
    _timer?.cancel();

    _timer = Timer(Duration(seconds: shortDelay ? 2 : 5), () {
      if (!mounted) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint("SplashScreen: User not logged in → /login");
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        debugPrint("SplashScreen: User is logged in → /main");
        Navigator.pushReplacementNamed(context, '/main');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoWidth = screenWidth * 0.8;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo/occaziologo1.png',
                width: logoWidth,
                fit: BoxFit.contain,
                semanticLabel: 'Occazio Logo',
              ),
              const SizedBox(height: 15),
              const Text(
                'EVENT MANAGEMENT',
                style: TextStyle(
                  fontSize: 16,
                  letterSpacing: 2.5,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 60),
              const SpinKitChasingDots(
                color: Colors.white,
                size: 50.0,
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
