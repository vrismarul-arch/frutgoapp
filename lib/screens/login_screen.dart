import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _googleLoading = false;
  String? _errorMessage;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _webSignInSub;

  @override
  void initState() {
    super.initState();

    // Web-ல Google தன் button-ஐ தானே render பண்றதால, sign-in complete
    // ஆனதை stream மூலம் கேட்கணும். Mobile-ல webSignInEvents null,
    // so இந்த listen() call effect இல்லாம போகும்.
    final auth = context.read<AuthProvider>();
    _webSignInSub = auth.webSignInEvents?.listen(_onWebSignInEvent);
  }

  @override
  void dispose() {
    _webSignInSub?.cancel();
    super.dispose();
  }

  Future<void> _onWebSignInEvent(GoogleSignInAuthenticationEvent event) async {
    final auth = context.read<AuthProvider>();

    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });

    try {
      await auth.handleWebGoogleSignIn(event);

      if (!mounted) return;

      if (auth.isLoggedIn) {
        _onSignInSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _googleLoading = false;
        });
      }
    }
  }

  void _onSignInSuccess() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  // =========================================================
  // GOOGLE SIGN IN — mobile path
  // =========================================================

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      await auth.signInWithGoogle();

      if (!mounted) return;
      _onSignInSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _googleLoading = false;
        });
      }
    }
  }

  // =========================================================
  // GUEST
  // =========================================================

  Future<void> _handleContinueAsGuest() async {
    final auth = context.read<AuthProvider>();
    await auth.continueAsGuest();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FBEF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),

              Image.asset('assets/login.png', height: 220, fit: BoxFit.contain),

              const SizedBox(height: 28),

              const Text(
                'Welcome to Frutgo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Fresh fruits and groceries, delivered\n'
                'to your doorstep in minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
              ),

              const SizedBox(height: 20),

              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE7E4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),

              buildGoogleSignInButton(
                loading: _googleLoading,
                onPressed: _handleGoogleSignIn,
              ),

              const SizedBox(height: 18),

              TextButton(
                onPressed: _googleLoading ? null : _handleContinueAsGuest,
                child: const Text(
                  'Continue as Guest',
                  style: TextStyle(
                    color: Color(0xFF65B83D),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'By continuing, you agree to our Terms and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black38),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}