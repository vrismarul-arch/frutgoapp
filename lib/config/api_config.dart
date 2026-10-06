import 'env.dart';

class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    return Env.apiBaseUrl;
  }

  // =========================================================
  // AUTH
  // =========================================================

  static String get authBaseUrl {
    return '$baseUrl/users/auth';
  }

  static String get signupUrl {
    return '$authBaseUrl/signup';
  }

  static String get loginUrl {
    return '$authBaseUrl/login';
  }

  static String get googleLoginUrl {
    return '$authBaseUrl/google';
  }

  static String get meUrl {
    return '$authBaseUrl/me';
  }

  // =========================================================
  // PRODUCTS
  // =========================================================

  static String get productsUrl {
    return '$baseUrl/admin/products';
  }

  // =========================================================
  // CART
  // =========================================================

  static String get cartUrl {
    return '$baseUrl/cart';
  }

  // =========================================================
  // ORDERS
  // =========================================================

  static String get ordersUrl {
    return '$baseUrl/orders';
  }
}