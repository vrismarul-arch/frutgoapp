import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _loading = true;
  bool _guest = false;
  String? _lastError;

  // =========================================================
  // GETTERS
  // =========================================================

  UserModel? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  bool get isGuest => _guest;
  String? get lastError => _lastError;

  bool get isLoggedIn {
    return _token != null && _token!.isNotEmpty && _user != null;
  }

  bool get isAuthenticated {
    return isLoggedIn || _guest;
  }

  // Web-ல Google Identity Services தன் own button-ஐ render பண்ணும்
  // (google_sign_in_button_web.dart), so UI-ல இருந்து நேரடியா
  // trigger பண்ண முடியாது. இந்த stream மூலம் sign-in complete
  // ஆனதை கேட்கணும். Mobile/desktop-ல kIsWeb false, so null.
  Stream<GoogleSignInAuthenticationEvent>? get webSignInEvents {
    if (kIsWeb) {
      return GoogleSignIn.instance.authenticationEvents;
    }
    return null;
  }

  // =========================================================
  // INIT
  // =========================================================

  AuthProvider() {
    initialize();
  }

  Future<void> initialize() async {
    _loading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      final guest = await StorageService.isGuest();

      if (token == null || token.isEmpty) {
        _token = null;
        _user = null;
        _guest = guest;
        return;
      }

      _token = token;
      _guest = false;

      try {
        _user = await AuthService.fetchMe();
      } catch (_) {
        await StorageService.clearAuth();
        _token = null;
        _user = null;
        _guest = false;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // LOGIN (email/password or Google — pass token + user)
  // =========================================================

  Future<void> loginWithToken({
    required String token,
    required UserModel user,
  }) async {
    await StorageService.saveToken(token);
    await StorageService.removeGuest();

    _token = token;
    _user = user;
    _guest = false;

    notifyListeners();
  }

  // =========================================================
  // GOOGLE SIGN IN — mobile path (custom button calls this directly)
  // =========================================================

  Future<void> signInWithGoogle() async {
    final user = await AuthService.signInWithGoogle();
    final token = await StorageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Login succeeded but token was not saved.');
    }

    await loginWithToken(token: token, user: user);
  }

  // =========================================================
  // GOOGLE SIGN IN — web path (triggered by webSignInEvents
  // listener in LoginScreen, not by a direct button press)
  // =========================================================

  Future<void> handleWebGoogleSignIn(
    GoogleSignInAuthenticationEvent event,
  ) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) {
      return;
    }

    try {
      final user = await AuthService.signInWithGoogleWebAccount(event.user);
      final token = await StorageService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Login succeeded but token was not saved.');
      }

      await loginWithToken(token: token, user: user);
    } catch (e) {
      _lastError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  void clearLastError() {
    _lastError = null;
  }

  // =========================================================
  // GUEST
  // =========================================================

  Future<void> continueAsGuest() async {
    await StorageService.removeToken();
    await StorageService.setGuest(true);

    _token = null;
    _user = null;
    _guest = true;

    notifyListeners();
  }

  // =========================================================
  // REFRESH USER
  // =========================================================

  Future<void> refreshUser() async {
    if (_token == null || _token!.isEmpty) {
      return;
    }

    try {
      _user = await AuthService.fetchMe();
      notifyListeners();
    } catch (_) {
      await logout();
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    await AuthService.logout();

    _token = null;
    _user = null;
    _guest = false;

    notifyListeners();
  }
}