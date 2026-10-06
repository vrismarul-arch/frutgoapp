import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

// ============================================================
// ORDER PLACED SCREEN
// ============================================================
//
// Full-screen confirmation shown right after an order is placed
// (replaces the old AlertDialog). Shows order summary + lets the
// user share the order details via the native share sheet.
// ============================================================

class OrderPlacedScreen extends StatelessWidget {
  const OrderPlacedScreen({
    super.key,
    required this.order,
    required this.bookingTime,
  });

  // Full order map returned by the backend (response['order']).
  final Map<String, dynamic> order;

  // Exact moment the order was placed (used for the display date/time).
  final DateTime bookingTime;

  // =========================================================
  // COLORS
  // =========================================================

  static const Color green = Color(0xFF65B83D);
  static const Color dark = Color(0xFF252525);
  static const Color grey = Color(0xFF777777);
  static const Color background = Color(0xFFF7F7F7);

  // =========================================================
  // FORMATTING HELPERS
  // =========================================================

  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDisplayTime(DateTime date) {
    int hour12 = date.hour % 12;

    if (hour12 == 0) {
      hour12 = 12;
    }

    final String minute = date.minute.toString().padLeft(2, '0');
    final String period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour12:$minute $period';
  }

  // =========================================================
  // BUILD SHARE TEXT
  // =========================================================

  String _buildShareText() {
    final String orderId = order['id']?.toString() ?? '';

    final List<dynamic> items =
        (order['items'] is List) ? order['items'] as List : [];

    final buffer = StringBuffer();

    buffer.writeln('🛒 Frutgo Order Confirmation');
    buffer.writeln('');

    if (orderId.isNotEmpty) {
      buffer.writeln('Order ID: #$orderId');
    }

    buffer.writeln('Delivery: ${_formatDisplayDate(bookingTime)}');
    buffer.writeln('Booked at: ${_formatDisplayTime(bookingTime)}');
    buffer.writeln('Payment: Cash on Delivery');
    buffer.writeln('');

    if (items.isNotEmpty) {
      buffer.writeln('Items:');

      for (final dynamic item in items) {
        if (item is Map) {
          final String name = item['name']?.toString() ?? '';
          final String variant = item['variant']?.toString() ?? '';
          final dynamic qty = item['qty'] ?? 1;

          buffer.writeln(
            '- $name${variant.isNotEmpty ? ' ($variant)' : ''} x$qty',
          );
        }
      }

      buffer.writeln('');
    }

    final dynamic total = order['total'];

    if (total != null) {
      buffer.writeln('Total: ₹$total');
    }

    return buffer.toString();
  }

  // =========================================================
  // SHARE
  // =========================================================

  void _handleShare(BuildContext context) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;

    SharePlus.instance.share(
      ShareParams(
        text: _buildShareText(),
        subject: 'Frutgo Order Confirmation',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final String orderId = order['id']?.toString() ?? '';

    final List<dynamic> items =
        (order['items'] is List) ? order['items'] as List : [];

    final dynamic subtotal = order['subtotal'];
    final dynamic deliveryFee = order['delivery_fee'];
    final dynamic total = order['total'];

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // =================================================
            // SCROLLABLE CONTENT
            // =================================================

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 12),

                  // ---------------------------------------------
                  // SUCCESS ICON
                  // ---------------------------------------------

                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F8ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: green,
                        size: 64,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      'Order Placed!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: dark,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Center(
                    child: Text(
                      'Your order has been placed successfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: grey, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ---------------------------------------------
                  // ORDER SUMMARY CARD
                  // ---------------------------------------------

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8DF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (orderId.isNotEmpty) ...[
                          _summaryRow('Order ID', '#$orderId'),
                          const Divider(height: 20),
                        ],
                        _summaryRow(
                          'Delivery',
                          _formatDisplayDate(bookingTime),
                        ),
                        const SizedBox(height: 10),
                        _summaryRow(
                          'Booked at',
                          _formatDisplayTime(bookingTime),
                        ),
                        const SizedBox(height: 10),
                        _summaryRow('Payment', 'Cash on Delivery'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ---------------------------------------------
                  // ITEMS CARD
                  // ---------------------------------------------

                  if (items.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8DF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Items',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: dark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...items.map((dynamic item) {
                            if (item is! Map) return const SizedBox.shrink();

                            final String name =
                                item['name']?.toString() ?? '';
                            final String variant =
                                item['variant']?.toString() ?? '';
                            final dynamic qty = item['qty'] ?? 1;
                            final dynamic price = item['price'];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (variant.isNotEmpty)
                                          Text(
                                            variant,
                                            style: const TextStyle(
                                              color: grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'x$qty',
                                    style: const TextStyle(color: grey),
                                  ),
                                  const SizedBox(width: 12),
                                  if (price != null)
                                    Text(
                                      '₹$price',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ---------------------------------------------
                  // TOTAL CARD
                  // ---------------------------------------------

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8DF)),
                    ),
                    child: Column(
                      children: [
                        if (subtotal != null)
                          _priceRow('Subtotal', subtotal),
                        if (deliveryFee != null) ...[
                          const SizedBox(height: 8),
                          _priceRow('Delivery Fee', deliveryFee),
                        ],
                        if (total != null) ...[
                          const Divider(height: 24),
                          _priceRow('Total', total, bold: true),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // =================================================
            // BOTTOM ACTIONS
            // =================================================

            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8DF)),
                ),
              ),
              child: Row(
                children: [
                  // -------------------------------------------
                  // SHARE
                  // -------------------------------------------

                  Expanded(
                    child: Builder(
                      builder: (shareContext) {
                        return OutlinedButton.icon(
                          onPressed: () => _handleShare(shareContext),
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: green,
                            side: const BorderSide(color: green),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // -------------------------------------------
                  // CONTINUE SHOPPING
                  // -------------------------------------------

                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Continue Shopping',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SUMMARY ROW
  // =========================================================

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: grey, fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    );
  }

  // =========================================================
  // PRICE ROW
  // =========================================================

  Widget _priceRow(String title, dynamic amount, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: bold ? 17 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          '₹$amount',
          style: TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}