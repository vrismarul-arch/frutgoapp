import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();

  static const String _tokenKey = 'userToken';
  static const String _guestKey = 'isGuest';

  // =========================================================
  // TOKEN
  // =========================================================

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token.trim();
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // =========================================================
  // GUEST
  // =========================================================

  static Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestKey) ?? false;
  }

  static Future<void> setGuest(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, value);
  }

  static Future<void> removeGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
  }

  // =========================================================
  // CLEAR ALL
  // =========================================================

  static Future<void> clearAuth() async {
    await removeToken();
    await removeGuest();
  }
}