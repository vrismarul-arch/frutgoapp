import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'order_details_screen.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({super.key});

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  static const Color green = Color(0xFF65B83D);
  static const Color dark = Color(0xFF252525);
  static const Color grey = Color(0xFF777777);
  static const Color background = Color(0xFFF7F7F7);

  List<Map<String, dynamic>> orders = [];

  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchOrders();
    });
  }

  Future<void> fetchOrders() async {
    final auth = context.read<AuthProvider>();

    final token = auth.token;

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Please login first';
      });

      return;
    }

    try {
      final baseUrl =
          dotenv.env['VITE_API_BASE_URL'] ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'ORDERS STATUS: ${response.statusCode}',
      );

      debugPrint(
        'ORDERS RESPONSE: ${response.body}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic decoded =
            jsonDecode(response.body);

        List<Map<String, dynamic>> result = [];

        if (decoded is List) {
          result = decoded
              .whereType<Map>()
              .map(
                (item) =>
                    Map<String, dynamic>.from(item),
              )
              .toList();
        } else if (decoded is Map) {
          if (decoded['orders'] is List) {
            result = (decoded['orders'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      Map<String, dynamic>.from(item),
                )
                .toList();
          } else if (decoded['data'] is List) {
            result = (decoded['data'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      Map<String, dynamic>.from(item),
                )
                .toList();
          }
        }

        setState(() {
          orders = result;
          loading = false;
          error = '';
        });
      } else if (response.statusCode == 401) {
        setState(() {
          loading = false;
          error = 'Session expired. Please login again.';
        });
      } else {
        setState(() {
          loading = false;
          error = 'Unable to load orders';
        });
      }
    } catch (e) {
      debugPrint('ORDERS ERROR: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Something went wrong';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: dark,
          ),
        ),

        title: const Text(
          'MY ORDERS',
          style: TextStyle(
            color: dark,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          IconButton(
            onPressed: fetchOrders,
            icon: const Icon(
              Icons.refresh_rounded,
              color: dark,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: green,
        onRefresh: fetchOrders,
        child: buildContent(),
      ),
    );
  }

  Widget buildContent() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: green,
        ),
      );
    }

    if (error.isNotEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: [
          const SizedBox(height: 180),

          const Icon(
            Icons.cloud_off_outlined,
            size: 55,
            color: grey,
          ),

          const SizedBox(height: 15),

          Center(
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: grey,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: TextButton(
              onPressed: fetchOrders,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (orders.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: const [
          SizedBox(height: 180),

          Icon(
            Icons.shopping_bag_outlined,
            size: 60,
            color: green,
          ),

          SizedBox(height: 15),

          Center(
            child: Text(
              'No orders yet',
              style: TextStyle(
                color: dark,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          SizedBox(height: 6),

          Center(
            child: Text(
              'Your orders will appear here.',
              style: TextStyle(
                color: grey,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(16),

      itemCount: orders.length,

      itemBuilder: (context, index) {
        return buildOrderCard(
          orders[index],
        );
      },
    );
  }

  Widget buildOrderCard(
    Map<String, dynamic> order,
  ) {
    final List<dynamic> items =
        order['items'] is List
            ? List<dynamic>.from(
                order['items'],
              )
            : [];

    final Map<String, dynamic> item =
        items.isNotEmpty && items.first is Map
            ? Map<String, dynamic>.from(
                items.first,
              )
            : {};

    final String name =
        item['name']?.toString() ??
            'Product';

    final String variant =
        item['variant']?.toString() ??
            '';

    final String image =
        item['image']?.toString() ??
            '';

    final String quantity =
        item['qty']?.toString() ??
            '1';

    final String status =
        order['status']?.toString() ??
            'pending';

    final String orderId =
        order['id']?.toString() ??
            '-';

    final double total =
        toDouble(order['total']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE5E5E5),
          ),
        ),

        child: Column(
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Container(
                  width: 62,
                  height: 62,

                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF3F3F3),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(12),

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
                              return const Icon(
                                Icons
                                    .shopping_basket_outlined,
                                color: green,
                              );
                            },
                          )
                        : const Icon(
                            Icons
                                .shopping_basket_outlined,
                            color: green,
                          ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(
                          color: dark,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Order #$orderId',
                        style:
                            const TextStyle(
                          color: grey,
                          fontSize: 12,
                        ),
                      ),

                      if (variant.isNotEmpty)
                        Text(
                          variant,
                          style:
                              const TextStyle(
                            color: grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                statusBadge(status),
              ],
            ),

            const SizedBox(height: 13),

            const Divider(
              height: 1,
              color: Color(0xFFE5E5E5),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF3F3F3),
                    borderRadius:
                        BorderRadius.circular(7),
                  ),

                  child: Text(
                    '${quantity}x',
                    style:
                        const TextStyle(
                      color: dark,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      color: dark,
                      fontSize: 13,
                    ),
                  ),
                ),

                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style:
                      const TextStyle(
                    color: dark,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 15,
                  color: grey,
                ),

                SizedBox(width: 5),

                Text(
                  'Tap to view order details',
                  style: TextStyle(
                    color: grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget statusBadge(String status) {
    final String value =
        status.toLowerCase();

    final bool delivered =
        value == 'delivered' ||
        value == 'completed';

    final bool cancelled =
        value == 'cancelled' ||
        value == 'canceled';

    final Color color = delivered
        ? green
        : cancelled
            ? Colors.red
            : const Color(0xFFE38A00);

    final Color bgColor = delivered
        ? const Color(0xFFEAF7E3)
        : cancelled
            ? const Color(0xFFFFEEEE)
            : const Color(0xFFFFF3DF);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        capitalize(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  double toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value.substring(1);
  }
}