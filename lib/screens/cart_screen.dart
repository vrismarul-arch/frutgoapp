import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
  });

  @override
  State<CartScreen> createState() =>
      _CartScreenState();
}

class _CartScreenState
    extends State<CartScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) return;

      context
          .read<CartProvider>()
          .loadCart();
    });
  }

  // =============================================================
  // MONEY
  // =============================================================

  String _money(double value) {
    return '₹${value.toStringAsFixed(0)}';
  }

  // =============================================================
  // BACK NAVIGATION
  // =============================================================

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // No previous route on the stack (e.g. CartScreen was pushed
      // with pushReplacementNamed / pushNamedAndRemoveUntil, or is
      // the initial route) — fall back to home instead of doing
      // nothing / throwing.
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Consumer<CartProvider>(
      builder: (
        context,
        cart,
        child,
      ) {
        return Scaffold(
          backgroundColor:
              const Color(0xFFF6F7F6),

          appBar: AppBar(
            backgroundColor:
                Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,

            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
              ),
              onPressed: () {
                _handleBack(context);
              },
            ),

            title: const Text(
              'Your Cart',
              style: TextStyle(
                color:
                    Color(0xFF151515),
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            actions: [
              if (!cart.isEmpty)
                TextButton(
                  onPressed:
                      cart.isUpdating
                          ? null
                          : _clearCart,
                  child:
                      const Text(
                    'Clear',
                    style: TextStyle(
                      color:
                          Color(
                        0xFF65B83D,
                      ),
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          body: _buildBody(
            context,
            cart,
          ),
        );
      },
    );
  }

  // =============================================================
  // BODY
  // =============================================================

  Widget _buildBody(
    BuildContext context,
    CartProvider cart,
  ) {
    if (cart.loading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              Color(0xFF65B83D),
        ),
      );
    }

    if (cart.error != null) {
      return _ErrorView(
        message: cart.error!,
        onRetry: () {
          cart.loadCart();
        },
      );
    }

    if (cart.isEmpty) {
      return const _EmptyCart();
    }

    return Column(
      children: [
        Expanded(
          child:
              RefreshIndicator(
            color:
                const Color(
              0xFF65B83D,
            ),
            onRefresh:
                cart.loadCart,
            child: ListView(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                16,
                16,
                16,
                20,
              ),
              children: [
                _DeliveryBanner(
                  amount: cart
                      .amountForFreeDelivery,
                ),

                const SizedBox(
                  height: 14,
                ),

                Text(
                  '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF181818),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                ...cart.items.map(
                  (item) => Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      bottom: 10,
                    ),
                    child:
                        _CartItemCard(
                      item: item,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                _SummaryCard(
                  cart: cart,
                  money: _money,
                ),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),

        _CheckoutBar(
          cart: cart,
          money: _money,
          onCheckout: () {
            Navigator.pushNamed(
              context,
              '/checkout',
            );
          },
        ),
      ],
    );
  }

  // =============================================================
  // CLEAR CART
  // =============================================================

  Future<void> _clearCart() async {
    final cart =
        context.read<CartProvider>();

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Clear cart?',
          ),
          content: const Text(
            'All items will be removed from your cart.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF65B83D,
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Clear',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted ||
        confirmed != true) {
      return;
    }

    try {
      await cart.clearCart();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }
}

// =============================================================
// CART ITEM
// =============================================================

class _CartItemCard
    extends StatelessWidget {
  const _CartItemCard({
    required this.item,
  });

  final CartItem item;

  @override
  Widget build(
    BuildContext context,
  ) {
    final cart =
        context.watch<CartProvider>();

    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              const Color(0xFFEAEAEA),
        ),
      ),
      child: Row(
        children: [
          _ProductImage(
            image: item.image,
            name: item.name,
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF181818),
                  ),
                ),

                if (item.variant
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    item.variant,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Color(
                        0xFF858A85,
                      ),
                    ),
                  ),
                ],

                const SizedBox(
                  height: 9,
                ),

                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF181818),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Row(
                  children: [
                    _QtyButton(
                      icon:
                          Icons.remove,
                      onTap:
                          cart.isUpdating
                              ? null
                              : () {
                                  if (item
                                          .qty >
                                      1) {
                                    cart.updateQty(
                                      item.id,
                                      item.qty -
                                          1,
                                    );
                                  } else {
                                    cart.removeItem(
                                      item.id,
                                    );
                                  }
                                },
                    ),

                    SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          '${item.qty}',
                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ),
                    ),

                    _QtyButton(
                      icon:
                          Icons.add,
                      onTap:
                          cart.isUpdating
                              ? null
                              : () {
                                  cart.updateQty(
                                    item.id,
                                    item.qty +
                                        1,
                                  );
                                },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          IconButton(
            onPressed:
                cart.isUpdating
                    ? null
                    : () {
                        cart.removeItem(
                          item.id,
                        );
                      },
            icon:
                const Icon(
              Icons.delete_outline,
              color:
                  Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// PRODUCT IMAGE
// =============================================================

class _ProductImage
    extends StatelessWidget {
  const _ProductImage({
    required this.image,
    required this.name,
  });

  final String image;
  final String name;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 92,
      height: 92,
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF5F7F4),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: image.isNotEmpty
          ? Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder:
                  (
                context,
                error,
                stackTrace,
              ) {
                return _fallback();
              },
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return const Center(
      child: Icon(
        Icons
            .shopping_basket_outlined,
        size: 32,
        color:
            Color(0xFF65B83D),
      ),
    );
  }
}

// =============================================================
// QUANTITY BUTTON
// =============================================================

class _QtyButton
    extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(
        8,
      ),
      child: Container(
        width: 30,
        height: 30,
        decoration:
            BoxDecoration(
          color:
              const Color(0xFFF2F5F0),
          borderRadius:
              BorderRadius.circular(
            8,
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: onTap == null
              ? Colors.grey
              : const Color(
                  0xFF222222,
                ),
        ),
      ),
    );
  }
}

// =============================================================
// DELIVERY BANNER
// =============================================================

class _DeliveryBanner
    extends StatelessWidget {
  const _DeliveryBanner({
    required this.amount,
  });

  final double amount;

  @override
  Widget build(
    BuildContext context,
  ) {
    final free =
        amount <= 0;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFEAF7E3),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons
                .local_shipping_outlined,
            color:
                Color(0xFF65B83D),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              free
                  ? 'You unlocked FREE delivery!'
                  : 'Add ₹${amount.toStringAsFixed(0)} more for FREE delivery',
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF3F6E2A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// SUMMARY
// =============================================================

class _SummaryCard
    extends StatelessWidget {
  const _SummaryCard({
    required this.cart,
    required this.money,
  });

  final CartProvider cart;
  final String Function(
    double,
  ) money;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              const Color(0xFFEAEAEA),
        ),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Subtotal',
            value:
                money(cart.subtotal),
          ),

          const SizedBox(
            height: 10,
          ),

          _SummaryRow(
            label: 'Delivery Fee',
            value:
                cart.deliveryFee == 0
                    ? 'FREE'
                    : money(
                        cart.deliveryFee,
                      ),
            valueColor:
                cart.deliveryFee == 0
                    ? const Color(
                        0xFF65B83D,
                      )
                    : null,
          ),

          const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical: 14,
            ),
            child: Divider(
              height: 1,
            ),
          ),

          _SummaryRow(
            label: 'Total',
            value:
                money(cart.total),
            bold: true,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// SUMMARY ROW
// =============================================================

class _SummaryRow
    extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize:
                  bold ? 16 : 14,
              fontWeight: bold
                  ? FontWeight.w800
                  : FontWeight.w500,
              color:
                  const Color(
                0xFF555955,
              ),
            ),
          ),
        ),

        Text(
          value,
          style: TextStyle(
            fontSize:
                bold ? 17 : 14,
            fontWeight:
                FontWeight.w800,
            color:
                valueColor ??
                    const Color(
                      0xFF171717,
                    ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// CHECKOUT BAR
// =============================================================

class _CheckoutBar
    extends StatelessWidget {
  const _CheckoutBar({
    required this.cart,
    required this.money,
    required this.onCheckout,
  });

  final CartProvider cart;
  final String Function(
    double,
  ) money;
  final VoidCallback onCheckout;

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.08,
              ),
              blurRadius: 12,
              offset:
                  const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF858A85),
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  money(cart.total),
                  style:
                      const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(
              child: SizedBox(
                height: 50,
                child:
                    ElevatedButton(
                  onPressed:
                      cart.isUpdating
                          ? null
                          : onCheckout,
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF65B83D,
                    ),
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        13,
                      ),
                    ),
                  ),
                  child:
                      const Text(
                    'Proceed to Checkout',
                    style:
                        TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// EMPTY CART
// =============================================================

class _EmptyCart
    extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFFEAF7E3),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .shopping_bag_outlined,
                size: 48,
                color:
                    Color(0xFF65B83D),
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            const Text(
              'Your cart is empty',
              style:
                  TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Add fresh fruits & veggies\nto get started',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 14,
                color:
                    Color(0xFF858A85),
                height: 1.5,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            SizedBox(
              height: 48,
              child:
                  ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF65B83D,
                  ),
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 28,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                child:
                    const Text(
                  'Start Shopping',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// ERROR VIEW
// =============================================================

class _ErrorView
    extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 50,
              color:
                  Colors.redAccent,
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Colors.redAccent,
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            ElevatedButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}