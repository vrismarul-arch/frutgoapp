import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// ============================================================
// ORDER DETAILS SCREEN — Bill / Invoice style
//
// New screen only. Does not touch any existing file's logic.
// Navigated to from AllOrdersScreen by tapping an order card.
// ============================================================

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  final Map<String, dynamic> order;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  static const Color green = Color(0xFF65B83D);
  static const Color dark = Color(0xFF252525);
  static const Color grey = Color(0xFF777777);

  bool _downloading = false;
  bool _sharing = false;

  // =========================================================
  // HELPERS (same logic style as AllOrdersScreen)
  // =========================================================

  List<Map<String, dynamic>> get _items {
    final raw = widget.order['items'];
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  double get _itemsTotal {
    double sum = 0;
    for (final item in _items) {
      final price = _toDouble(item['price']);
      final qty = _toDouble(item['qty'] ?? item['quantity'] ?? 1);
      sum += price * qty;
    }
    return sum;
  }

  double get _grandTotal {
    final total = _toDouble(widget.order['total']);
    return total > 0 ? total : _itemsTotal;
  }

  String get _orderId =>
      widget.order['id']?.toString() ??
      widget.order['_id']?.toString() ??
      '-';

  String get _status =>
      widget.order['status']?.toString() ?? 'pending';

  String get _date {
    final raw = widget.order['created_at'] ??
        widget.order['createdAt'] ??
        widget.order['date'];

    if (raw == null) return '';

    try {
      final parsed = DateTime.parse(raw.toString());
      return '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/'
          '${parsed.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: dark),
        ),
        title: const Text(
          'ORDER INVOICE',
          style: TextStyle(
            color: dark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _invoiceCard(),
            const SizedBox(height: 20),
            _downloadButton(),
            const SizedBox(height: 10),
            _shareButton(),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // INVOICE CARD (on-screen bill preview)
  // =========================================================

  Widget _invoiceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- header ----
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Frutgo',
                style: TextStyle(
                  color: green,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7E3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _capitalize(_status),
                  style: const TextStyle(
                    color: green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          const Text(
            'INVOICE',
            style: TextStyle(
              color: grey,
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          _infoRow('Order ID', '#$_orderId'),
          if (_date.isNotEmpty) _infoRow('Date', _date),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          const SizedBox(height: 16),

          const Text(
            'ITEMS',
            style: TextStyle(
              color: dark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 10),

          ..._items.map(_itemRow),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          const SizedBox(height: 12),

          _infoRow(
            'Total',
            '₹${_grandTotal.toStringAsFixed(0)}',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: bold ? dark : grey,
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: dark,
              fontSize: bold ? 17 : 13,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? 'Product';
    final variant = item['variant']?.toString() ?? '';
    final qty = _toDouble(item['qty'] ?? item['quantity'] ?? 1);
    final price = _toDouble(item['price']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (variant.isNotEmpty)
                  Text(
                    variant,
                    style: const TextStyle(color: grey, fontSize: 11.5),
                  ),
                Text(
                  '${qty.toStringAsFixed(0)} x ₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(color: grey, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Text(
            '₹${(qty * price).toStringAsFixed(0)}',
            style: const TextStyle(
              color: dark,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUTTONS
  // =========================================================

  Widget _downloadButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _downloading ? null : _downloadInvoice,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _downloading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.download_rounded),
        label: Text(
          _downloading ? 'Saving...' : 'Download Invoice (PDF)',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }

  Widget _shareButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _sharing ? null : _shareInvoice,
        style: OutlinedButton.styleFrom(
          foregroundColor: green,
          side: const BorderSide(color: green),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _sharing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: green,
                ),
              )
            : const Icon(Icons.share_rounded),
        label: Text(
          _sharing ? 'Preparing...' : 'Share Invoice',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD PDF BYTES
  // =========================================================

  Future<List<int>> _buildPdfBytes() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Frutgo',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 14,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Text('Order ID: #$_orderId'),
                if (_date.isNotEmpty) pw.Text('Date: $_date'),
                pw.Text('Status: ${_capitalize(_status)}'),
                pw.SizedBox(height: 18),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Table(
                  columnWidths: const {
                    0: pw.FlexColumnWidth(4),
                    1: pw.FlexColumnWidth(1.4),
                    2: pw.FlexColumnWidth(1.6),
                    3: pw.FlexColumnWidth(1.6),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          child: pw.Text(
                            'Item',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          child: pw.Text(
                            'Qty',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          child: pw.Text(
                            'Price',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ..._items.map((item) {
                      final name = item['name']?.toString() ?? 'Product';
                      final qty = _toDouble(
                        item['qty'] ?? item['quantity'] ?? 1,
                      );
                      final price = _toDouble(item['price']);

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            child: pw.Text(name),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            child: pw.Text(qty.toStringAsFixed(0)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            child: pw.Text('Rs.${price.toStringAsFixed(0)}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            child: pw.Text(
                              'Rs.${(qty * price).toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Total: Rs.${_grandTotal.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'Thank you for shopping with Frutgo!',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // =========================================================
  // DOWNLOAD — actually saves the PDF file to the device
  // =========================================================

  Future<void> _downloadInvoice() async {
    setState(() => _downloading = true);

    try {
      final bytes = await _buildPdfBytes();
      final fileName = 'frutgo_invoice_$_orderId.pdf';

      String savedPath;

      if (Platform.isAndroid) {
        // Request storage permission on older Android versions.
        // On Android 13+ this is a no-op / auto-granted for app use.
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }

        Directory downloadsDir = Directory('/storage/emulated/0/Download');

        // Fallback if the public Downloads folder isn't reachable.
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
        }

        final file = File('${downloadsDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        savedPath = file.path;
      } else {
        // iOS / other platforms: app documents directory
        // (iOS has no public Downloads folder accessible directly).
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        savedPath = file.path;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice saved: $savedPath'),
          backgroundColor: green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save invoice: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  // =========================================================
  // SHARE — opens native share/print sheet
  // =========================================================

  Future<void> _shareInvoice() async {
    setState(() => _sharing = true);

    try {
      final bytes = await _buildPdfBytes();

      if (!mounted) return;

      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'frutgo_invoice_$_orderId.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share invoice: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}