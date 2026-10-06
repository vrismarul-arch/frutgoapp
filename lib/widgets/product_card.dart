import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  State<ProductCard> createState() =>
      _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  static const Color green =
      Color(0xFF65B83D);

  static const Color darkGreen =
      Color(0xFF3F8F26);

  Product get product => widget.product;

  int _selectedVariantIndex = 0;

  bool _busy = false;

  // ============================================================
  // SELECTED VARIANT
  // ============================================================

  ProductVariant? get selectedVariant {
    if (product.variants.isEmpty) {
      return null;
    }

    if (_selectedVariantIndex >=
        product.variants.length) {
      return product.variants.first;
    }

    return product.variants[
        _selectedVariantIndex];
  }

  // ============================================================
  // CURRENT CART QUANTITY
  // ============================================================

  int _getQuantity() {
    final variant = selectedVariant;

    if (variant == null) {
      return 0;
    }

    final cart =
        context.watch<CartProvider>();

    return cart.getItemQuantity(
      product.id,
      variant.id,
    );
  }

  // ============================================================
  // CURRENT CART ITEM
  // ============================================================

  CartItem? _getCartItem() {
    final variant = selectedVariant;

    if (variant == null) {
      return null;
    }

    final cart =
        context.read<CartProvider>();

    return cart.getCartItem(
      product.id,
      variant.id,
    );
  }

  // ============================================================
  // CHECK LOGIN
  // ============================================================

  Future<bool> _checkLogin() async {
    final auth =
        context.read<AuthProvider>();

    if (auth.user != null) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    await Navigator.pushNamed(
      context,
      '/login',
    );

    if (!mounted) {
      return false;
    }

    return context
            .read<AuthProvider>()
            .user !=
        null;
  }

  // ============================================================
  // SELECT VARIANT
  // ============================================================

  void _selectVariant(int index) {
    if (index < 0 ||
        index >= product.variants.length) {
      return;
    }

    setState(() {
      _selectedVariantIndex = index;
    });
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  Future<void> _addToCart() async {
    if (_busy) {
      return;
    }

    final loggedIn =
        await _checkLogin();

    if (!loggedIn || !mounted) {
      return;
    }

    final variant =
        selectedVariant;

    if (variant == null) {
      _showMessage(
        'This product has no variant.',
      );
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final cart =
          context.read<CartProvider>();

      await cart.addItem(
        productId: product.id,
        variantId: variant.id,
        qty: 1,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '${product.name} added to cart',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ============================================================
  // INCREASE
  // ============================================================

  Future<void> _increaseQuantity() async {
    if (_busy) {
      return;
    }

    final loggedIn =
        await _checkLogin();

    if (!loggedIn || !mounted) {
      return;
    }

    final item =
        _getCartItem();

    if (item == null) {
      await _addToCart();
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final cart =
          context.read<CartProvider>();

      await cart.updateQty(
        item.id,
        item.qty + 1,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ============================================================
  // DECREASE
  // ============================================================

  Future<void> _decreaseQuantity() async {
    if (_busy) {
      return;
    }

    final loggedIn =
        await _checkLogin();

    if (!loggedIn || !mounted) {
      return;
    }

    final item =
        _getCartItem();

    if (item == null) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final cart =
          context.read<CartProvider>();

      if (item.qty <= 1) {
        await cart.removeItem(
          item.id,
        );
      } else {
        await cart.updateQty(
          item.id,
          item.qty - 1,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR CLEANER
  // ============================================================

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          duration:
              const Duration(
            seconds: 2,
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildImage(),

          const SizedBox(
            height: 8,
          ),

          _buildProductName(),

          const SizedBox(
            height: 7,
          ),

          _buildVariants(),

          const SizedBox(
            height: 7,
          ),

          _buildPrice(),

          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildImage() {
    final quantity =
        _getQuantity();

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF6F6F6,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFEAEAEA,
                  ),
                ),
              ),
              clipBehavior:
                  Clip.antiAlias,
              child:
                  product.image
                          .trim()
                          .isEmpty
                      ? const Center(
                          child: Icon(
                            Icons
                                .image_outlined,
                            size: 40,
                            color:
                                Colors.grey,
                          ),
                        )
                      : Image.network(
                          product.image,
                          fit:
                              BoxFit.cover,
                          loadingBuilder:
                              (
                            context,
                            child,
                            progress,
                          ) {
                            if (progress ==
                                null) {
                              return child;
                            }

                            return const Center(
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color:
                                    green,
                              ),
                            );
                          },
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Center(
                              child: Icon(
                                Icons
                                    .image_outlined,
                                size: 40,
                                color:
                                    Colors.grey,
                              ),
                            );
                          },
                        ),
            ),
          ),

          // ======================================================
          // CART BUTTON
          // ======================================================

          Positioned(
            right: 8,
            bottom: 8,
            child: _busy
                ? _buildLoading()
                : quantity == 0
                    ? _buildAddButton()
                    : _buildQuantityControl(
                        quantity,
                      ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      width: 48,
      height: 40,
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        border:
            Border.all(
          color: green,
        ),
      ),
      child:
          const Center(
        child:
            SizedBox(
          width: 17,
          height: 17,
          child:
              CircularProgressIndicator(
            strokeWidth: 2,
            color: green,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADD BUTTON
  // ============================================================

  Widget _buildAddButton() {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius:
          BorderRadius.circular(
        9,
      ),
      child: InkWell(
        onTap: _addToCart,
        borderRadius:
            BorderRadius.circular(
          9,
        ),
        child: Container(
          width: 48,
          height: 40,
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              9,
            ),
            border:
                Border.all(
              color: green,
              width: 1.3,
            ),
          ),
          child:
              const Center(
            child: Icon(
              Icons.add,
              size: 21,
              color: green,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QUANTITY CONTROL
  // ============================================================

  Widget _buildQuantityControl(
    int quantity,
  ) {
    return Container(
      height: 42,
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          11,
        ),
        border:
            Border.all(
          color: green,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 7,
            offset:
                const Offset(
              0,
              2,
            ),
          ),
        ],
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          // MINUS

          InkWell(
            onTap:
                _decreaseQuantity,
            child:
                const SizedBox(
              width: 36,
              height: 42,
              child:
                  Center(
                child: Icon(
                  Icons.remove,
                  size: 18,
                  color:
                      Color(
                    0xFF202420,
                  ),
                ),
              ),
            ),
          ),

          // NUMBER

          SizedBox(
            width: 28,
            child:
                Center(
              child:
                  Text(
                '$quantity',
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(
                    0xFF171A17,
                  ),
                ),
              ),
            ),
          ),

          // PLUS

          InkWell(
            onTap:
                _increaseQuantity,
            child:
                const SizedBox(
              width: 36,
              height: 42,
              child:
                  Center(
                child: Icon(
                  Icons.add,
                  size: 18,
                  color:
                      Color(
                    0xFF202420,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT NAME
  // ============================================================

  Widget _buildProductName() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child:
          Text(
        product.name,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
        style:
            const TextStyle(
          fontSize: 14,
          fontWeight:
              FontWeight.w700,
          color:
              Color(
            0xFF191C19,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VARIANTS
  // ============================================================

  Widget _buildVariants() {
    if (product.variants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child:
          SingleChildScrollView(
        scrollDirection:
            Axis.horizontal,
        child:
            Row(
          children:
              List.generate(
            product.variants.length,
            (index) {
              final variant =
                  product.variants[
                      index];

              final selected =
                  index ==
                      _selectedVariantIndex;

              return Padding(
                padding:
                    EdgeInsets.only(
                  right:
                      index <
                              product
                                      .variants
                                      .length -
                                  1
                          ? 6
                          : 0,
                ),
                child:
                    GestureDetector(
                  onTap: () =>
                      _selectVariant(
                    index,
                  ),
                  child:
                      Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal:
                          9,
                      vertical:
                          6,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          selected
                              ? const Color(
                                  0xFFEAF7E3,
                                )
                              : const Color(
                                  0xFFF5F6F4,
                                ),
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                      border:
                          Border.all(
                        color:
                            selected
                                ? green
                                : const Color(
                                    0xFFE4E7E3,
                                  ),
                      ),
                    ),
                    child:
                        Text(
                      _variantLabel(
                        variant,
                      ),
                      style:
                          TextStyle(
                        fontSize:
                            10.5,
                        fontWeight:
                            selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                        color:
                            selected
                                ? darkGreen
                                : const Color(
                                    0xFF6E746E,
                                  ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CORRECT VARIANT LABEL
  // ============================================================

  String _variantLabel(
    ProductVariant variant,
  ) {
    final label =
        variant.label.trim();

    final unit =
        variant.unit.trim();

    if (label.isNotEmpty) {
      return label;
    }

    if (unit.isNotEmpty) {
      return unit;
    }

    return 'Option';
  }

  // ============================================================
  // PRICE
  // ============================================================

  Widget _buildPrice() {
    final variant =
        selectedVariant;

    if (variant == null) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          horizontal: 10,
        ),
        child:
            Text(
          'Price unavailable',
          style:
              TextStyle(
            fontSize: 12,
            color:
                Colors.grey,
          ),
        ),
      );
    }

    final price =
        variant.price;

    final discount =
        product.discountPercent;

    double? oldPrice;

    if (discount > 0 &&
        discount < 100 &&
        price > 0) {
      oldPrice =
          price /
              (1 -
                  discount /
                      100);
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          if (discount > 0)
            Padding(
              padding:
                  const EdgeInsets
                      .only(
                bottom: 3,
              ),
              child:
                  Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFFFEEEE,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    5,
                  ),
                ),
                child:
                    Text(
                  '${discount.toStringAsFixed(0)}% OFF',
                  style:
                      const TextStyle(
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Colors.redAccent,
                  ),
                ),
              ),
            ),

          Row(
            children: [
              Text(
                '₹${price.toStringAsFixed(0)}',
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(
                    0xFF171A17,
                  ),
                ),
              ),

              if (oldPrice != null)
                Padding(
                  padding:
                      const EdgeInsets
                          .only(
                    left: 7,
                  ),
                  child:
                      Text(
                    '₹${oldPrice.toStringAsFixed(0)}',
                    style:
                        const TextStyle(
                      fontSize: 10,
                      color:
                          Color(
                        0xFF999D99,
                      ),
                      decoration:
                          TextDecoration
                              .lineThrough,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 2,
          ),

          Text(
            _unitText(
              variant,
            ),
            style:
                const TextStyle(
              fontSize: 9.5,
              color:
                  Color(
                0xFF858A85,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UNIT TEXT
  // ============================================================

  String _unitText(
    ProductVariant variant,
  ) {
    final unit =
        variant.unit.trim();

    if (unit.isEmpty) {
      return '';
    }

    return unit;
  }
}