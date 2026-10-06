import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // Keep splash screen visible for 1.2 seconds.
    await Future.delayed(
      const Duration(milliseconds: 1200),
    );

    if (!mounted) return;

    final authProvider =
        context.read<AuthProvider>();

    // Logged-in user → Home
    if (authProvider.user != null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    }

    // Not logged in → Login
    else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF65B83D),

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            // =================================================
            // FRUTGO LOGO
            // No container
            // No white circle
            // No shadow
            // No unwanted padding
            // =================================================

           Center(
  child: Container(
    width: 140,
    height: 140,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
    ),
    padding: const EdgeInsets.all(14),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.contain,
      ),
    ),
  ),
),
            const SizedBox(
              height: 18,
            ),

            // =================================================
            // APP NAME
            // =================================================

            // const Text(
            //   'Frutgo',
            //   style: TextStyle(
            //     color: Colors.white,
            //     fontSize: 34,
            //     fontWeight: FontWeight.w800,
            //     letterSpacing: -0.8,
            //   ),
            // ),

            const SizedBox(
              height: 6,
            ),

            // =================================================
            // TAGLINE
            // =================================================

            const Text(
              'Freshness delivered to you',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            // =================================================
            // LOADING
            // =================================================

            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}