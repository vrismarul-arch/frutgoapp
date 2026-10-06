import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/env.dart';
import '../providers/cart_provider.dart';

// ============================================================
// Shared design tokens — same language as product_section.dart
// so this page feels like part of the same app, not a different
// screen glued on.
// ============================================================
class _Design {
  static const Color accent = Color(0xFF65B83D);
  static const Color textDark = Color(0xFF1A1D1A);
  static const Color textMuted = Color(0xFF858A85);
  static const Color cardBg = Colors.white;
  static const Color pageBg = Color(0xFFF6F7F6);

  static const double cardRadius = 16;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
}

class SpecialOffersPage extends StatefulWidget {
  const SpecialOffersPage({super.key});

  @override
  State<SpecialOffersPage> createState() => _SpecialOffersPageState();
}

class _SpecialOffersPageState extends State<SpecialOffersPage> {
  // =====================================================
  // STATE
  // =====================================================

  bool _loading = true;
  String _error = '';

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _products = [];

  List<String> _categories = ['All'];
  Map<String, String> _categoryImages = {};

  String _selectedCategory = 'All';
  String _sort = 'Recommended';
  bool _priceDrop = false;

  final TextEditingController _searchController = TextEditingController();

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =====================================================
  // LOAD PRODUCTS
  // =====================================================

  Future<void> _loadOffers() async {
    try {
      if (mounted) {
        setState(() {
          _loading = true;
          _error = '';
        });
      }

      final url = '${Env.apiBaseUrl}/admin/products';

      final response = await http.get(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to load products (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('Invalid API response');
      }

      final rawProducts = decoded['products'];

      if (rawProducts is! List) {
        throw Exception('Products not found in API response');
      }

      // =================================================
      // CONVERT API PRODUCTS
      // =================================================

      final allProducts = rawProducts
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      // =================================================
      // ONLY SPECIAL OFFER PRODUCTS
      // =================================================

      final offers = allProducts.where(_isOfferProduct).toList();

      // =================================================
      // CATEGORY DATA
      // =================================================

      final categorySet = <String>{};
      final categoryImages = <String, String>{};

      for (final product in offers) {
        final category = _category(product);
        if (category.isEmpty) continue;

        categorySet.add(category);

        if (!categoryImages.containsKey(category)) {
          final image = _image(product);
          if (image.isNotEmpty) categoryImages[category] = image;
        }
      }

      final categories = <String>['All', ...categorySet];

      if (!mounted) return;

      setState(() {
        _allProducts = offers;
        _products = List<Map<String, dynamic>>.from(offers);
        _categories = categories;
        _categoryImages = categoryImages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // =====================================================
  // CHECK SPECIAL OFFER
  // =====================================================

  bool _isOfferProduct(Map<String, dynamic> product) {
    final status = '${product['status'] ?? ''}'.trim().toLowerCase();

    if (status.isNotEmpty && status != 'active') return false;

    final isSpecialOffer = product['is_special_offer'] == true;
    final discount = _discount(product);

    return isSpecialOffer || discount > 0;
  }

  // =====================================================
  // DISCOUNT
  // =====================================================

  double _discount(Map<String, dynamic> product) {
    final value = product['discount_percent'];
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  // =====================================================
  // PRICE
  // =====================================================

  double _price(Map<String, dynamic> product) {
    final directPrice = product['price'];
    if (directPrice is num && directPrice > 0) return directPrice.toDouble();

    final sellingPrice = product['sellingPrice'];
    if (sellingPrice is num && sellingPrice > 0) return sellingPrice.toDouble();

    final discountedPrice = product['discountedPrice'];
    if (discountedPrice is num && discountedPrice > 0) {
      return discountedPrice.toDouble();
    }

    final finalPrice = product['finalPrice'];
    if (finalPrice is num && finalPrice > 0) return finalPrice.toDouble();

    // ---- variant price ----
    final variants = product['variants'];

    if (variants is List && variants.isNotEmpty) {
      final first = variants.first;

      if (first is Map) {
        final value = first['price'];

        if (value is num && value > 0) return value.toDouble();

        final parsed = double.tryParse('$value');
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    return 0;
  }

  // =====================================================
  // OLD PRICE
  // =====================================================

  double _oldPrice(Map<String, dynamic> product) {
    final possibleOldPrices = [
      product['oldPrice'],
      product['mrp'],
      product['originalPrice'],
      product['compareAtPrice'],
    ];

    for (final value in possibleOldPrices) {
      final number = _toDouble(value);
      if (number > 0) return number;
    }

    final price = _price(product);
    final discount = _discount(product);

    if (price > 0 && discount > 0 && discount < 100) {
      return price / (1 - discount / 100);
    }

    return 0;
  }

  // =====================================================
  // NAME
  // =====================================================

  String _name(Map<String, dynamic> product) {
    return '${product['name'] ?? 'Product'}'.trim();
  }

  // =====================================================
  // CATEGORY
  // =====================================================

  String _category(Map<String, dynamic> product) {
    final category = product['category'];

    if (category is Map) {
      return '${category['name'] ?? category['title'] ?? ''}'.trim();
    }

    return '$category'.trim();
  }

  // =====================================================
  // IMAGE
  // =====================================================

  String _image(Map<String, dynamic> product) {
    final image = product['image'];

    if (image != null && '$image'.trim().isNotEmpty) {
      return '$image';
    }

    final images = product['images'];

    if (images is List && images.isNotEmpty) {
      return '${images.first}';
    }

    return '';
  }

  // =====================================================
  // VARIANTS
  // =====================================================

  List<Map<String, dynamic>> _variants(Map<String, dynamic> product) {
    final variants = product['variants'];
    if (variants is! List) return [];

    return variants
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // =====================================================
  // NUMBER
  // =====================================================

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  // =====================================================
  // APPLY FILTERS
  // =====================================================

  void _applyFilters() {
    List<Map<String, dynamic>> result =
        List<Map<String, dynamic>>.from(_allProducts);

    // ---- category ----
    if (_selectedCategory != 'All') {
      result = result.where((product) {
        return _category(product) == _selectedCategory;
      }).toList();
    }

    // ---- search ----
    final search = _searchController.text.trim().toLowerCase();

    if (search.isNotEmpty) {
      result = result.where((product) {
        final name = _name(product).toLowerCase();
        final category = _category(product).toLowerCase();
        return name.contains(search) || category.contains(search);
      }).toList();
    }

    // ---- price drop ----
    if (_priceDrop) {
      result = result.where((product) => _discount(product) > 0).toList();
    }

    // ---- sort ----
    if (_sort == 'Price: Low to High') {
      result.sort((a, b) => _price(a).compareTo(_price(b)));
    }

    if (_sort == 'Price: High to Low') {
      result.sort((a, b) => _price(b).compareTo(_price(a)));
    }

    if (_sort == 'Discount: High to Low') {
      result.sort((a, b) => _discount(b).compareTo(_discount(a)));
    }

    if (!mounted) return;

    setState(() {
      _products = result;
    });
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Design.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _filterBar(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _Design.accent,
                        strokeWidth: 2.4,
                      ),
                    )
                  : _error.isNotEmpty
                      ? _errorView()
                      : _products.isEmpty
                          ? _emptyView()
                          : _body(),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget _header() {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 27),
          ),
          const Expanded(
            child: Text(
              'Special Offers',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _Design.textDark,
                letterSpacing: -0.2,
              ),
            ),
          ),
          IconButton(
            onPressed: _showSearch,
            icon: const Icon(Icons.search_rounded, size: 27),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // FILTER BAR
  // =====================================================

  Widget _filterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterButton(
              icon: Icons.tune_rounded,
              label: '',
              onTap: _showFilters,
            ),
            const SizedBox(width: 8),
            _filterButton(
              label: _sort == 'Recommended' ? 'Sort By' : _sort,
              icon: Icons.keyboard_arrow_down_rounded,
              active: _sort != 'Recommended',
              onTap: _showSort,
            ),
            const SizedBox(width: 8),
            _filterButton(
              label: 'Price Drop',
              icon: Icons.local_offer_outlined,
              active: _priceDrop,
              onTap: () {
                setState(() => _priceDrop = !_priceDrop);
                _applyFilters();
              },
            ),
            const SizedBox(width: 8),
            _filterButton(
              label: _selectedCategory == 'All' ? 'Type' : _selectedCategory,
              icon: Icons.keyboard_arrow_down_rounded,
              active: _selectedCategory != 'All',
              onTap: _showCategories,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // FILTER BUTTON
  // =====================================================

  Widget _filterButton({
    String label = '',
    IconData? icon,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEAF6E5) : const Color(0xFFF6F7F6),
            borderRadius: BorderRadius.circular(20),
            border: active ? Border.all(color: _Design.accent) : null,
          ),
          child: Row(
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 17,
                  color: active ? _Design.accent : const Color(0xFF444844),
                ),
              if (icon != null && label.isNotEmpty) const SizedBox(width: 6),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? _Design.accent : const Color(0xFF444844),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // BODY
  // =====================================================

  Widget _body() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final sidebarWidth = width < 500
            ? 88.0
            : width < 900
                ? 108.0
                : 124.0;

        final crossAxisCount = width < 500
            ? 2
            : width < 900
                ? 3
                : 4;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _categorySidebar(sidebarWidth),
            Expanded(child: _productGrid(crossAxisCount)),
          ],
        );
      },
    );
  }

  // =====================================================
  // CATEGORY SIDEBAR
  // =====================================================

  Widget _categorySidebar(double width) {
    return Container(
      width: width,
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category == _selectedCategory;
          final image = _categoryImages[category] ?? '';

          return InkWell(
            onTap: () {
              setState(() => _selectedCategory = category);
              _applyFilters();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 5),
              decoration: BoxDecoration(
                color: selected ? _Design.pageBg : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border:
                    selected ? Border.all(color: const Color(0xFFE1E4E1)) : null,
              ),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F3),
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(color: _Design.accent, width: 1.4)
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: category == 'All'
                        ? Icon(
                            Icons.grid_view_rounded,
                            color: selected ? _Design.accent : Colors.black45,
                            size: 26,
                          )
                        : image.isNotEmpty
                            ? Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.local_offer_outlined,
                                    color:
                                        selected ? _Design.accent : Colors.black45,
                                    size: 24,
                                  );
                                },
                              )
                            : Icon(
                                Icons.local_offer_outlined,
                                color: selected ? _Design.accent : Colors.black45,
                                size: 24,
                              ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? _Design.textDark : _Design.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // PRODUCT GRID
  // =====================================================

  Widget _productGrid(int crossAxisCount) {
    final cart = context.watch<CartProvider>();

    return Container(
      color: _Design.pageBg,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 14,
          // Enough fixed height for image + name + variants +
          // discount + price + per-piece price, without overflow.
          mainAxisExtent: 288,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];

          return _ProductCard(
            product: product,
            name: _name(product),
            image: _image(product),
            price: _price(product),
            oldPrice: _oldPrice(product),
            discount: _discount(product),
            variants: _variants(product),
            cart: cart,
          );
        },
      ),
    );
  }

  // =====================================================
  // SEARCH
  // =====================================================

  void _showSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: TextField(
            autofocus: true,
            controller: _searchController,
            onChanged: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: 'Search offers...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  _searchController.clear();
                  _applyFilters();
                },
                icon: const Icon(Icons.clear),
              ),
              filled: true,
              fillColor: const Color(0xFFF4F5F3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // SORT
  // =====================================================

  void _showSort() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Sort Products',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              _sortTile('Recommended'),
              _sortTile('Discount: High to Low'),
              _sortTile('Price: Low to High'),
              _sortTile('Price: High to Low'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // SORT TILE
  // =====================================================

  Widget _sortTile(String value) {
    return ListTile(
      title: Text(value),
      trailing:
          _sort == value ? const Icon(Icons.check, color: _Design.accent) : null,
      onTap: () {
        Navigator.pop(context);
        setState(() => _sort = value);
        _applyFilters();
      },
    );
  }

  // =====================================================
  // CATEGORY SHEET
  // =====================================================

  void _showCategories() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: _categories.map((category) {
              return ListTile(
                title: Text(category),
                trailing: category == _selectedCategory
                    ? const Icon(Icons.check, color: _Design.accent)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedCategory = category);
                  _applyFilters();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // =====================================================
  // FILTER SHEET
  // =====================================================

  void _showFilters() {
    bool tempPriceDrop = _priceDrop;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Price Drop Only'),
                      value: tempPriceDrop,
                      activeThumbColor: _Design.accent,
                      onChanged: (value) {
                        setModalState(() => tempPriceDrop = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() => _priceDrop = tempPriceDrop);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Design.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // ERROR VIEW
  // =====================================================

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _Design.cardBg,
            borderRadius: BorderRadius.circular(_Design.cardRadius),
            boxShadow: _Design.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 50, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Unable to load offers',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOffers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Design.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // EMPTY VIEW
  // =====================================================

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF6E5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                size: 36,
                color: _Design.accent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No special offers',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'New offers will appear here',
              style: TextStyle(color: _Design.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// PRODUCT CARD
// =========================================================

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.name,
    required this.image,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.variants,
    required this.cart,
  });

  final Map<String, dynamic> product;
  final String name;
  final String image;
  final double price;
  final double oldPrice;
  final double discount;
  final List<Map<String, dynamic>> variants;
  final CartProvider cart;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _selectedVariant = 0;

  // =====================================================
  // PRODUCT / VARIANT IDS
  // =====================================================

  dynamic get _productId =>
      widget.product['_id'] ?? widget.product['id'];

  dynamic get _variantId {
    if (widget.variants.isEmpty) return null;
    if (_selectedVariant >= widget.variants.length) return null;
    final variant = widget.variants[_selectedVariant];
    return variant['_id'] ?? variant['id'];
  }

  int get _quantity =>
      widget.cart.getItemQuantity(_productId, _variantId);

  // =====================================================
  // SELECTED PRICE
  // =====================================================

  double get _selectedPrice {
    if (widget.variants.isEmpty) return widget.price;
    if (_selectedVariant >= widget.variants.length) return widget.price;

    final value = widget.variants[_selectedVariant]['price'];

    if (value is num) return value.toDouble();

    return double.tryParse('$value') ?? widget.price;
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final selectedPrice = _selectedPrice;

    final oldPrice = widget.discount > 0 && widget.discount < 100
        ? selectedPrice / (1 - widget.discount / 100)
        : widget.oldPrice;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _Design.cardBg,
        borderRadius: BorderRadius.circular(_Design.cardRadius),
        boxShadow: _Design.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =================================================
          // IMAGE
          // =================================================

          Stack(
            children: [
              Container(
                height: 132,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.image.isNotEmpty
                    ? Image.network(
                        widget.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) {
                          return const _ProductImagePlaceholder();
                        },
                      )
                    : const _ProductImagePlaceholder(),
              ),

              // ---- wishlist ----
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border_rounded,
                    size: 16,
                    color: Color(0xFF777B77),
                  ),
                ),
              ),

              // ---- discount badge ----
              if (widget.discount > 0)
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF269B63),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.discount.round()}% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

              // ---- add / quantity stepper ----
              Positioned(
                right: 5,
                bottom: 5,
                child: _quantity == 0
                    ? GestureDetector(
                        onTap: () async {
                          try {
                            await widget.cart.addItem(
                              productId: _productId,
                              variantId: _variantId,
                              qty: 1,
                            );
                            if (context.mounted) _showAddedMessage(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceFirst('Exception: ', ''),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF75A8F0),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 26,
                            color: Color(0xFF1165D8),
                          ),
                        ),
                      )
                    : Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: _Design.accent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StepperIcon(
                              icon: Icons.remove,
                              onTap: () async {
                                final cartItem = widget.cart.getCartItem(
                                  _productId,
                                  _variantId,
                                );
                                if (cartItem == null) return;
                                try {
                                  await widget.cart.updateQty(
                                    cartItem.id,
                                    _quantity - 1,
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceFirst('Exception: ', ''),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            SizedBox(
                              width: 22,
                              child: Text(
                                '$_quantity',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            _StepperIcon(
                              icon: Icons.add,
                              onTap: () async {
                                final cartItem = widget.cart.getCartItem(
                                  _productId,
                                  _variantId,
                                );
                                if (cartItem == null) return;
                                try {
                                  await widget.cart.updateQty(
                                    cartItem.id,
                                    _quantity + 1,
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceFirst('Exception: ', ''),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // =================================================
          // PRODUCT NAME
          // =================================================

          Text(
            widget.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: _Design.textDark,
            ),
          ),

          const SizedBox(height: 5),

          // =================================================
          // VARIANTS
          // =================================================

          if (widget.variants.isNotEmpty)
            SizedBox(
              height: 27,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.variants.length,
                separatorBuilder: (context, index) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final variant = widget.variants[index];
                  final label = '${variant['label'] ?? ''}';
                  final selected = index == _selectedVariant;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedVariant = index);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFEAF7E3) : const Color(0xFFF6F7F6),
                        borderRadius: BorderRadius.circular(6),
                        border: selected ? Border.all(color: _Design.accent) : null,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: selected ? _Design.accent : const Color(0xFF555955),
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 5),

          // =================================================
          // DISCOUNT
          // =================================================

          if (widget.discount > 0)
            Text(
              '${widget.discount.round()}% OFF',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF269B63),
              ),
            ),

          const SizedBox(height: 3),

          // =================================================
          // PRICE
          // =================================================

          Row(
            children: [
              Text(
                '₹${selectedPrice.round()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _Design.textDark,
                ),
              ),
              if (oldPrice > selectedPrice) ...[
                const SizedBox(width: 5),
                Text(
                  '₹${oldPrice.round()}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 2),

          // =================================================
          // PRICE PER PIECE
          // =================================================

          Text(
            selectedPrice > 0
                ? '₹${(selectedPrice / 4).toStringAsFixed(1)}/piece'
                : 'Special price',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: _Design.textMuted),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ADDED MESSAGE
  // =====================================================

  void _showAddedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.name} added to cart'),
        duration: const Duration(seconds: 1),
        backgroundColor: _Design.accent,
      ),
    );
  }
}

// =========================================================
// STEPPER ICON
// =========================================================

class _StepperIcon extends StatelessWidget {
  const _StepperIcon({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

// =========================================================
// IMAGE PLACEHOLDER
// =========================================================

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F2EF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey,
        size: 32,
      ),
    );
  }
}