import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

// Web-ல Google Identity Services தன் own button-ஐ render பண்ணும்,
// custom UI-ல இருந்து trigger பண்ண முடியாது. `loading`/`onPressed`
// signature match-க்காக மட்டும் வெச்சிருக்கோம், இங்க unused.
// AuthProvider.webSignInEvents stream மூலம் sign-in complete ஆனது தெரியும்.
Widget buildGoogleSignInButton({
  required bool loading,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: Center(child: web.renderButton()),
  );
}