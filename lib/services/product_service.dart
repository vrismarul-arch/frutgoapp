import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/product_model.dart';

class ProductService {
  ProductService._();

  // ==========================================================
  // FETCH ALL PRODUCTS
  // GET /admin/products
  // ==========================================================

  static Future<List<Product>> fetchProducts({
    String search = '',
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/admin/products',
    ).replace(
      queryParameters: search.trim().isEmpty
          ? null
          : {
              'search': search.trim(),
            },
    );

    final response = await http.get(uri);

    final data = _handleResponse(response);

    // Backend can return:
    // {
    //   "products": [...]
    // }
    //
    // OR:
    // {
    //   "data": [...]
    // }
    //
    // OR directly:
    // [...]

    dynamic rawList;

    if (data is Map<String, dynamic>) {
      rawList =
          data['products'] ??
          data['data'] ??
          [];
    } else if (data is List) {
      rawList = data;
    } else {
      rawList = [];
    }

    if (rawList is! List) {
      return [];
    }

    return rawList
        .whereType<Map>()
        .map(
          (item) => Product.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ==========================================================
  // FETCH PRODUCT BY ID
  // GET /admin/products/:id
  // ==========================================================

  static Future<Product> fetchProduct(
    String id,
  ) async {
    if (id.trim().isEmpty) {
      throw Exception(
        'Product ID is required',
      );
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/products/${id.trim()}',
      ),
    );

    final data = _handleResponse(response);

    dynamic rawProduct;

    if (data is Map<String, dynamic>) {
      rawProduct =
          data['product'] ?? data;
    } else {
      rawProduct = data;
    }

    if (rawProduct is! Map) {
      throw Exception(
        'Invalid product response',
      );
    }

    return Product.fromJson(
      Map<String, dynamic>.from(
        rawProduct,
      ),
    );
  }

  // ==========================================================
  // RESPONSE HANDLER
  // ==========================================================

  static dynamic _handleResponse(
    http.Response response,
  ) {
    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      if (data is Map) {
        throw Exception(
          data['message'] ??
              'Failed to load products',
        );
      }

      throw Exception(
        'Request failed: ${response.statusCode}',
      );
    }

    return data;
  }
}