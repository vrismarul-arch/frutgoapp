import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static String get apiBaseUrl {
    final value = dotenv.env['API_BASE_URL']?.trim();

    if (value == null || value.isEmpty) {
      throw Exception('API_BASE_URL is missing in .env');
    }

    return value.replaceFirst(RegExp(r'/$'), '');
  }

  static String get googleWebClientId {
    final value = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();

    if (value == null || value.isEmpty) {
      throw Exception('GOOGLE_WEB_CLIENT_ID is missing in .env');
    }

    if (!value.endsWith('.apps.googleusercontent.com')) {
      throw Exception('Invalid GOOGLE_WEB_CLIENT_ID');
    }

    return value;
  }
}