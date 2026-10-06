import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/env.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  AuthService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static bool _googleInitialized = false;

  static Future<void> initializeGoogle() async {
    if (_googleInitialized) return;

    if (kIsWeb) {
      await _googleSignIn.initialize(
        clientId: Env.googleWebClientId,
      );
    } else {
      await _googleSignIn.initialize(
        serverClientId: Env.googleWebClientId,
      );
    }

    _googleInitialized = true;
  }

  static Future<UserModel> signInWithGoogle() async {
    await initializeGoogle();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw Exception(
        'Google sign-in is not supported on this platform.',
      );
    }

    late final GoogleSignInAccount account;

    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      debugPrint(
        'GoogleSignInException: ${e.code} - ${e.description}',
      );

      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Sign in cancelled');
      }

      throw Exception(
        'DEBUG INFO -> code: ${e.code}, desc: ${e.description}, '
        'clientId: ${Env.googleWebClientId}',
      );
    }

    return _completeGoogleLogin(account);
  }

  static Future<UserModel> signInWithGoogleWebAccount(
    GoogleSignInAccount account,
  ) async {
    await initializeGoogle();

    return _completeGoogleLogin(account);
  }

  static Future<UserModel> _completeGoogleLogin(
    GoogleSignInAccount account,
  ) async {
    final GoogleSignInAuthentication auth = account.authentication;

    final String? idToken = auth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Google did not return an ID token. '
        'Make sure the client ID configured is your WEB client ID, '
        'not the Android client ID.',
      );
    }

    final data = await ApiService.instance.googleLoginUser(idToken);

    final rawUser = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : data;

    return UserModel.fromJson(rawUser);
  }

  static Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final data = await ApiService.instance.loginUser(
      email: email,
      password: password,
    );

    final rawUser = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : data;

    return UserModel.fromJson(rawUser);
  }

  static Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await ApiService.instance.signupUser(
      name: name,
      email: email,
      password: password,
    );

    final rawUser = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : data;

    return UserModel.fromJson(rawUser);
  }

  static Future<UserModel> fetchMe() async {
    final data = await ApiService.instance.fetchMe();

    final rawUser = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : data;

    return UserModel.fromJson(rawUser);
  }

  static Future<void> logout() async {
    try {
      if (_googleInitialized) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Google sign out error: $e');
    }

    await ApiService.instance.logoutUser();
    await StorageService.clearAuth();
  }
}