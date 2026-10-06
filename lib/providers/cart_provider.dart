import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CartItem {
  final dynamic id;
  final dynamic productId;
  final dynamic variantId;

  final String name;
  final String variant;
  final String unit;

  final double price;
  final int qty;

  final String image;

  const CartItem({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.name,
    required this.variant,
    required this.unit,
    required this.price,
    required this.qty,
    required this.image,
  });

  factory CartItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return CartItem(
      id: json['item_id'] ?? json['id'],
      productId: json['product_id'],
      variantId: json['variant_id'],
      name: json['name']?.toString() ?? '',
      variant: json['variant']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'weight',
      price: double.tryParse(
            json['price']?.toString() ?? '0',
          ) ??
          0,
      qty: int.tryParse(
            json['qty']?.toString() ?? '0',
          ) ??
          0,
      image: json['image']?.toString() ?? '',
    );
  }

  CartItem copyWith({
    int? qty,
  }) {
    return CartItem(
      id: id,
      productId: productId,
      variantId: variantId,
      name: name,
      variant: variant,
      unit: unit,
      price: price,
      qty: qty ?? this.qty,
      image: image,
    );
  }
}

class CartProvider extends ChangeNotifier {
  AuthProvider? _authProvider;

  List<CartItem> _items = [];

  bool _loading = false;
  bool _isUpdating = false;

  String? _error;

  // ============================================================
  // FREE DELIVERY CONFIG
  // ============================================================

  static const double _freeDeliveryThreshold = 299;
  static const double _deliveryFeeAmount = 40;

  // ============================================================
  // GETTERS
  // ============================================================

  List<CartItem> get items =>
      List.unmodifiable(_items);

  bool get loading => _loading;

  bool get isUpdating =>
      _isUpdating;

  String? get error => _error;

  int get itemCount {
    return _items.fold(
      0,
      (sum, item) => sum + item.qty,
    );
  }

  int get uniqueItems =>
      _items.length;

  bool get isEmpty =>
      _items.isEmpty;

  double get subtotal {
    return _items.fold(
      0,
      (sum, item) =>
          sum + (item.price * item.qty),
    );
  }

  double get deliveryFee {
    if (subtotal >= _freeDeliveryThreshold) {
      return 0;
    }

    if (subtotal <= 0) {
      return 0;
    }

    return _deliveryFeeAmount;
  }

  double get total =>
      subtotal + deliveryFee;

  double get amountForFreeDelivery {
    if (subtotal >= _freeDeliveryThreshold) {
      return 0;
    }

    return _freeDeliveryThreshold - subtotal;
  }

  // ============================================================
  // AUTH UPDATE
  // ============================================================

  void updateAuth(
    AuthProvider authProvider,
  ) {
    final previousUser =
        _authProvider?.user;

    _authProvider =
        authProvider;

    final currentUser =
        authProvider.user;

    // User logged in for the first time.
    //
    // We intentionally do NOT call loadCart() here.
    // main.dart will call refreshCart() after authentication
    // has completely finished restoring the token.
    if (currentUser != null &&
        previousUser == null) {
      return;
    }

    // User logged out.
    if (currentUser == null &&
        previousUser != null) {
      _items = [];
      _error = null;
      notifyListeners();
    }
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> _getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      'userToken',
    );
  }

  // ============================================================
  // REFRESH CART
  // ============================================================

  Future<void> refreshCart() async {
    final user =
        _authProvider?.user;

    if (user == null) {
      _items = [];
      _error = null;
      notifyListeners();
      return;
    }

    final token =
        await _getToken();

    if (token == null ||
        token.isEmpty) {
      _items = [];
      _error = null;
      notifyListeners();
      return;
    }

    debugPrint(
      'FRUTGO CART: Refreshing cart API...',
    );

    await loadCart();

    debugPrint(
      'FRUTGO CART: Cart refresh completed.',
    );
  }

  // ============================================================
  // LOAD CART
  // ============================================================

  Future<void> loadCart() async {
    final user =
        _authProvider?.user;

    final token =
        await _getToken();

    if (user == null ||
        token == null ||
        token.isEmpty) {
      _items = [];
      _error = null;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;

    notifyListeners();

    try {
      debugPrint(
        'FRUTGO CART: GET /cart',
      );

      final data =
          await ApiService.instance.fetchCart();

      final rawItems =
          data['items'];

      if (rawItems is List) {
        _items = rawItems
            .whereType<Map>()
            .map(
              (item) =>
                  CartItem.fromJson(
                Map<String, dynamic>.from(
                  item,
                ),
              ),
            )
            .toList();
      } else {
        _items = [];
      }

      debugPrint(
        'FRUTGO CART: Loaded ${_items.length} unique items',
      );
    } catch (e) {
      _error = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      debugPrint(
        'FRUTGO CART ERROR: $_error',
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ADD ITEM
  // ============================================================

  Future<void> addItem({
    required dynamic productId,
    required dynamic variantId,
    int qty = 1,
  }) async {
    final user =
        _authProvider?.user;

    final token =
        await _getToken();

    if (user == null ||
        token == null ||
        token.isEmpty) {
      throw Exception(
        'Please login to add items to cart',
      );
    }

    if (qty <= 0) {
      throw Exception(
        'Quantity must be greater than 0',
      );
    }

    _isUpdating = true;
    _error = null;

    notifyListeners();

    try {
      final data =
          await ApiService.instance.addToCart(
        productId,
        variantId,
        qty,
      );

      _setItemsFromResponse(
        data,
      );
    } catch (e) {
      _error = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // ============================================================
  // UPDATE QUANTITY
  // ============================================================

  Future<void> updateQty(
    dynamic itemId,
    int newQty,
  ) async {
    if (newQty < 0) {
      throw Exception(
        'Quantity cannot be negative',
      );
    }

    final index =
        _items.indexWhere(
      (item) => item.id == itemId,
    );

    if (index == -1) {
      throw Exception(
        'Item not found in cart',
      );
    }

    final previousItems =
        List<CartItem>.from(
      _items,
    );

    _isUpdating = true;

    // Optimistic update.
    if (newQty == 0) {
      _items.removeAt(index);
    } else {
      _items[index] =
          _items[index].copyWith(
        qty: newQty,
      );
    }

    notifyListeners();

    try {
      if (newQty == 0) {
        final data =
            await ApiService.instance
                .removeCartItem(
          itemId,
        );

        _setItemsFromResponse(
          data,
        );
      } else {
        final data =
            await ApiService.instance
                .updateCartItem(
          itemId,
          newQty,
        );

        _setItemsFromResponse(
          data,
        );
      }
    } catch (e) {
      _items = previousItems;

      notifyListeners();

      await loadCart();

      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REMOVE ITEM
  // ============================================================

  Future<void> removeItem(
    dynamic itemId,
  ) async {
    await updateQty(
      itemId,
      0,
    );
  }

  // ============================================================
  // CLEAR CART
  // ============================================================

  Future<void> clearCart() async {
    if (_items.isEmpty) {
      return;
    }

    final previousItems =
        List<CartItem>.from(
      _items,
    );

    _items = [];
    _isUpdating = true;

    notifyListeners();

    try {
      await ApiService.instance
          .clearCart();
    } catch (e) {
      _items = previousItems;

      notifyListeners();

      await loadCart();

      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // ============================================================
  // SET ITEMS FROM API RESPONSE
  // ============================================================

  void _setItemsFromResponse(
    Map<String, dynamic> data,
  ) {
    final rawItems =
        data['items'];

    if (rawItems is! List) {
      _items = [];
      return;
    }

    _items = rawItems
        .whereType<Map>()
        .map(
          (item) =>
              CartItem.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList();
  }

  // ============================================================
  // GET ITEM QUANTITY
  // ============================================================

  int getItemQuantity(
    dynamic productId,
    dynamic variantId,
  ) {
    for (final item in _items) {
      if (item.productId == productId &&
          item.variantId == variantId) {
        return item.qty;
      }
    }

    return 0;
  }

  // ============================================================
  // GET CART ITEM
  // ============================================================

  CartItem? getCartItem(
    dynamic productId,
    dynamic variantId,
  ) {
    for (final item in _items) {
      if (item.productId == productId &&
          item.variantId == variantId) {
        return item;
      }
    }

    return null;
  }
}