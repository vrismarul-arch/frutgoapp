import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  // =========================================================
  // TOKEN
  // =========================================================

  Future<String?> _getUserToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('userToken');

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token.trim();
  }

  // =========================================================
  // USER HEADERS
  // =========================================================

  Future<Map<String, String>> _userHeaders() async {
    final token = await _getUserToken();

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // =========================================================
  // ADMIN HEADERS
  // =========================================================

  Future<Map<String, String>> _adminHeaders() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('adminToken');

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    return headers;
  }

  // =========================================================
  // COMMON RESPONSE HANDLER
  // =========================================================

  Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request failed (${response.statusCode})';

      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
      }

      throw Exception(message);
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return {};
  }

  // =========================================================
  // PRODUCTS
  // =========================================================

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final url = '${Env.apiBaseUrl}/admin/products';

    final response = await http.get(
      Uri.parse(url),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load products (${response.statusCode})',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      return [];
    }

    if (decoded is! Map) {
      return [];
    }

    final rawProducts = decoded['products'];

    if (rawProducts is! List) {
      return [];
    }

    return rawProducts
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // =========================================================
  // OFFER PRODUCTS
  // =========================================================

  Future<List<Map<String, dynamic>>> fetchOfferProducts() async {
    final products = await fetchProducts();

    return products.where((product) {
      final status = '${product['status'] ?? ''}'.trim().toLowerCase();

      final active = status.isEmpty || status == 'active';

      if (!active) {
        return false;
      }

      final isSpecialOffer = product['is_special_offer'] == true;

      final discount = _toDouble(product['discount_percent']);

      return isSpecialOffer && discount > 0;
    }).toList();
  }

  // =========================================================
  // USER SIGNUP
  // =========================================================

  Future<Map<String, dynamic>> signupUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = '${Env.apiBaseUrl}/users/auth/signup';

    final response = await http.post(
      Uri.parse(url),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final data = _handleResponse(response);

    await _saveTokenFromResponse(data);

    return data;
  }

  // =========================================================
  // USER LOGIN
  // =========================================================

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final url = '${Env.apiBaseUrl}/users/auth/login';

    final response = await http.post(
      Uri.parse(url),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = _handleResponse(response);

    await _saveTokenFromResponse(data);

    return data;
  }

  // =========================================================
  // GOOGLE LOGIN
  // =========================================================

  Future<Map<String, dynamic>> googleLoginUser(String credential) async {
    final url = '${Env.apiBaseUrl}/users/auth/google';

    final response = await http.post(
      Uri.parse(url),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'credential': credential,
      }),
    );

    final data = _handleResponse(response);

    await _saveTokenFromResponse(data);

    return data;
  }

  // =========================================================
  // CURRENT USER
  // =========================================================

  Future<Map<String, dynamic>> fetchMe() async {
    final url = '${Env.apiBaseUrl}/users/auth/me';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    return _handleResponse(response);
  }

  // =========================================================
  // SAVED ADDRESSES
  // =========================================================

  Future<Map<String, dynamic>> getAddresses() async {
    final url = '${Env.apiBaseUrl}/addresses';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    return _handleResponse(response);
  }

  // =========================================================
  // GET SINGLE ADDRESS
  // =========================================================

  Future<Map<String, dynamic>> getAddressById(dynamic id) async {
    final url = '${Env.apiBaseUrl}/addresses/$id';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    return _handleResponse(response);
  }

  // =========================================================
  // ADD ADDRESS
  // =========================================================

  Future<Map<String, dynamic>> addAddress(
    Map<String, dynamic> address,
  ) async {
    final url = '${Env.apiBaseUrl}/addresses';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(address),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // UPDATE ADDRESS
  // =========================================================

  Future<Map<String, dynamic>> updateAddress(
    dynamic id,
    Map<String, dynamic> address,
  ) async {
    final url = '${Env.apiBaseUrl}/addresses/$id';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(address),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // DELETE ADDRESS
  // =========================================================

  Future<Map<String, dynamic>> deleteAddress(dynamic id) async {
    final url = '${Env.apiBaseUrl}/addresses/$id';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );

    return _handleResponse(response);
  }

  // =========================================================
  // CART - GET
  // =========================================================

  Future<Map<String, dynamic>> fetchCart() async {
    final url = '${Env.apiBaseUrl}/cart';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    return _handleResponse(response);
  }

  // =========================================================
  // CART - ADD
  // =========================================================

  Future<Map<String, dynamic>> addToCart(
    dynamic productId,
    dynamic variantId,
    int qty,
  ) async {
    final url = '${Env.apiBaseUrl}/cart';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({
        'productId': productId,
        'variantId': variantId,
        'qty': qty,
      }),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // CART - UPDATE
  // =========================================================

  Future<Map<String, dynamic>> updateCartItem(
    dynamic itemId,
    int qty,
  ) async {
    final url = '${Env.apiBaseUrl}/cart/$itemId';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({'qty': qty}),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // CART - REMOVE
  // =========================================================

  Future<Map<String, dynamic>> removeCartItem(dynamic itemId) async {
    final url = '${Env.apiBaseUrl}/cart/$itemId';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );

    return _handleResponse(response);
  }

  // =========================================================
  // CART - CLEAR
  // =========================================================

  Future<Map<String, dynamic>> clearCart() async {
    final url = '${Env.apiBaseUrl}/cart';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );

    return _handleResponse(response);
  }

  // =========================================================
  // PLACE ORDER
  // =========================================================

  Future<Map<String, dynamic>> placeOrder(
    Map<String, dynamic> orderDetails,
  ) async {
    final url = '${Env.apiBaseUrl}/orders';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(orderDetails),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // FETCH MY ORDERS
  // =========================================================

  Future<Map<String, dynamic>> fetchMyOrders() async {
    final url = '${Env.apiBaseUrl}/orders';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    return _handleResponse(response);
  }

  // =========================================================
  // FETCH SINGLE ORDER
  // =========================================================

  Future<Map<String, dynamic>> fetchOrderById(dynamic id) async {
    final url = '${Env.apiBaseUrl}/orders/$id';

    final headers = await _userHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('User token missing. Please login again.');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    return _handleResponse(response);
  }

  // =========================================================
  // ADMIN LOGIN
  // =========================================================

  Future<Map<String, dynamic>> loginAdmin({
    required String email,
    required String password,
  }) async {
    final url = '${Env.apiBaseUrl}/admin/login';

    final response = await http.post(
      Uri.parse(url),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = _handleResponse(response);

    await _saveAdminTokenFromResponse(data);

    return data;
  }

  // =========================================================
  // ADMIN ME
  // =========================================================

  Future<Map<String, dynamic>> fetchAdminMe() async {
    final url = '${Env.apiBaseUrl}/admin/me';

    final headers = await _adminHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('Admin token missing. Please login again.');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    return _handleResponse(response);
  }

  // =========================================================
  // ADMIN PRODUCT BY ID
  // =========================================================

  Future<Map<String, dynamic>> fetchAdminProductById(dynamic id) async {
    final url = '${Env.apiBaseUrl}/admin/products/$id';

    final headers = await _adminHeaders();

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    return _handleResponse(response);
  }

  // =========================================================
  // SAVE USER TOKEN
  // =========================================================

  Future<void> _saveTokenFromResponse(Map<String, dynamic> data) async {
    final token = _extractToken(data);

    if (token == null || token.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('userToken', token);
  }

  // =========================================================
  // SAVE ADMIN TOKEN
  // =========================================================

  Future<void> _saveAdminTokenFromResponse(
    Map<String, dynamic> data,
  ) async {
    final token = _extractToken(data);

    if (token == null || token.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('adminToken', token);
  }

  // =========================================================
  // EXTRACT TOKEN
  // =========================================================

  String? _extractToken(Map<String, dynamic> data) {
    final possibleToken = data['token'];

    if (possibleToken != null &&
        possibleToken.toString().trim().isNotEmpty) {
      return possibleToken.toString().trim();
    }

    final accessToken = data['accessToken'];

    if (accessToken != null &&
        accessToken.toString().trim().isNotEmpty) {
      return accessToken.toString().trim();
    }

    final jwt = data['jwt'];

    if (jwt != null && jwt.toString().trim().isNotEmpty) {
      return jwt.toString().trim();
    }

    return null;
  }

  // =========================================================
  // LOGOUT USER
  // =========================================================

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('userToken');
  }

  // =========================================================
  // LOGOUT ADMIN
  // =========================================================

  Future<void> logoutAdmin() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('adminToken');
  }

  // =========================================================
  // NUMBER
  // =========================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}