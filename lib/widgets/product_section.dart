import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'category_section.dart';
import 'product_card.dart';

// ============================================================
// DESIGN TOKENS
// ============================================================

class _Design {
  static const Color accent = Color(0xFF65B83D);
  static const Color textDark = Color(0xFF1A1D1A);
  static const Color textMuted = Color(0xFF858A85);

  static const Color pageBg = Color(0xFFF6F7F6);
  static const Color cardBg = Colors.white;

  static const double pagePadding = 16;
  static const double sectionGap = 16;
  static const double cardRadius = 18;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
}

// ============================================================
// PRODUCT SECTION
// ============================================================

class ProductSection extends StatefulWidget {
  const ProductSection({
    super.key,
    this.title = 'Frutgo Products',
  });

  final String title;

  @override
  State<ProductSection> createState() => _ProductSectionState();
}

class _ProductSectionState extends State<ProductSection> {
  bool loading = true;
  String? error;

  List<Product> products = [];

  String? selectedCategory;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  // ============================================================
  // LOAD PRODUCTS
  // ============================================================

  Future<void> loadProducts() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final raw = await ApiService.instance.fetchProducts();

      final parsed = raw
          .map(
            (json) => Product.fromJson(json),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        products = parsed;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e
            .toString()
            .replaceFirst('Exception: ', '');

        loading = false;
      });
    }
  }

  // ============================================================
  // FILTERED PRODUCTS
  // ============================================================

  List<Product> get filteredProducts {
    if (selectedCategory == null) {
      return products;
    }

    return products
        .where(
          (product) =>
              product.category == selectedCategory,
        )
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(
          child: CircularProgressIndicator(
            color: _Design.accent,
            strokeWidth: 2.4,
          ),
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (error != null) {
      return _ErrorCard(
        message: error!,
        onRetry: loadProducts,
      );
    }

    // ==========================================================
    // EMPTY
    // ==========================================================

    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    final filtered = filteredProducts;

    // ==========================================================
    // MAIN PRODUCT SECTION
    // ==========================================================

    return Container(
      color: _Design.pageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // CATEGORY SECTION
          // ======================================================

          CategorySection(
            products: products,
            selectedCategory: selectedCategory,
            onSelectCategory: (category) {
              setState(() {
                selectedCategory = category;
              });
            },
            onSeeAll: () {
              setState(() {
                selectedCategory = null;
              });
            },
          ),

          const SizedBox(
            height: _Design.sectionGap,
          ),

          // ======================================================
          // PRODUCT SECTION
          //
          // IMPORTANT:
          // No large outer card here.
          // ======================================================

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _Design.pagePadding,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedCategory == null
                            ? widget.title
                            : '${widget.title} · $selectedCategory',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _Design.textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    _ViewAllPill(
                      onTap: () =>
                          _showAllProducts(context),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ==================================================
                // PRODUCTS
                // ==================================================

                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 24,
                    ),
                    child: Center(
                      child: Text(
                        'No products in this category yet.',
                        style: TextStyle(
                          color: _Design.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 318,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics:
                          const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder:
                          (_, _) =>
                              const SizedBox(
                        width: 12,
                      ),
                      itemBuilder:
                          (context, index) {
                        return SizedBox(
                          width: 175,
                          child: ProductCard(
                            product: filtered[index],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ============================================================
  // VIEW ALL PRODUCTS
  // ============================================================

  void _showAllProducts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllProductsPage(
          allProducts: products,
          initialCategory: selectedCategory,
        ),
      ),
    );
  }
}

// ============================================================
// VIEW ALL PILL
// ============================================================

class _ViewAllPill extends StatelessWidget {
  const _ViewAllPill({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7E3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View All',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _Design.accent,
              ),
            ),
            SizedBox(width: 3),
            Icon(
              Icons.arrow_forward,
              size: 13,
              color: _Design.accent,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR CARD
// ============================================================

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _Design.pagePadding,
        vertical: 8,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _Design.cardBg,
          borderRadius: BorderRadius.circular(
            _Design.cardRadius,
          ),
          boxShadow: _Design.cardShadow,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 10),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 14),

            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _Design.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ALL PRODUCTS PAGE
// ============================================================

class AllProductsPage extends StatefulWidget {
  const AllProductsPage({
    super.key,
    required this.allProducts,
    this.initialCategory,
  });

  final List<Product> allProducts;

  final String? initialCategory;

  @override
  State<AllProductsPage> createState() =>
      _AllProductsPageState();
}

class _AllProductsPageState
    extends State<AllProductsPage> {
  late List<CategoryModel> _categories;
  late List<String> _types;

  String? _selectedCategory;
  String? _selectedType;

  String _sort = 'Recommended';

  bool _priceDropOnly = false;

  static const List<String> _sortOptions = [
    'Recommended',
    'Price: Low to High',
    'Price: High to Low',
    'Discount: High to Low',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _categories = _buildCategories();
    _types = _buildTypes();

    _selectedCategory =
        widget.initialCategory;
  }

  // ============================================================
  // BUILD CATEGORIES
  // ============================================================

  List<CategoryModel> _buildCategories() {
    final Map<String, CategoryModel> map = {};

    for (final product in widget.allProducts) {
      if (product.status != 'active') {
        continue;
      }

      final label =
          product.category.trim();

      if (label.isEmpty) {
        continue;
      }

      if (!map.containsKey(label)) {
        map[label] = CategoryModel(
          id: label,
          label: label,
          image: product.image,
        );
      }
    }

    return map.values.toList();
  }

  // ============================================================
  // BUILD TYPES
  // ============================================================

  List<String> _buildTypes() {
    final set = <String>{};

    for (final product in widget.allProducts) {
      for (final variant in product.variants) {
        final unit = variant.unit.trim();

        if (unit.isNotEmpty) {
          set.add(unit);
        }
      }
    }

    final list = set.toList()..sort();

    return list;
  }

  // ============================================================
  // PRICE
  // ============================================================

  double _priceOf(Product product) {
    if (product.variants.isEmpty) {
      return 0;
    }

    return product.variants.first.price;
  }

  // ============================================================
  // PAGE TITLE
  // ============================================================

  String get _pageTitle {
    return _selectedCategory ?? 'All Products';
  }

  // ============================================================
  // FILTER PRODUCTS
  // ============================================================

  List<Product> get _filteredProducts {
    var result =
        widget.allProducts.where((product) {
      // Category
      if (_selectedCategory != null &&
          product.category !=
              _selectedCategory) {
        return false;
      }

      // Price drop
      if (_priceDropOnly &&
          product.discountPercent <= 0) {
        return false;
      }

      // Type
      if (_selectedType != null &&
          !product.variants.any(
            (v) => v.unit == _selectedType,
          )) {
        return false;
      }

      return true;
    }).toList();

    // ==========================================================
    // SORT
    // ==========================================================

    switch (_sort) {
      case 'Price: Low to High':
        result.sort(
          (a, b) => _priceOf(a)
              .compareTo(_priceOf(b)),
        );
        break;

      case 'Price: High to Low':
        result.sort(
          (a, b) => _priceOf(b)
              .compareTo(_priceOf(a)),
        );
        break;

      case 'Discount: High to Low':
        result.sort(
          (a, b) => b.discountPercent
              .compareTo(a.discountPercent),
        );
        break;

      default:
        break;
    }

    return result;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Design.pageBg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildSidebar(),

                  Expanded(
                    child: _buildMainContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor:
          Colors.transparent,
      foregroundColor: Colors.black,
      titleSpacing: 0,

      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
        ),
        onPressed: () =>
            Navigator.maybePop(context),
      ),

      title: Text(
        _pageTitle,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _Design.textDark,
        ),
      ),

      actions: [
        IconButton(
          icon: const Icon(
            Icons.search,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar() {
    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 84,
      color: Colors.white,
      child: ListView(
        padding:
            const EdgeInsets.symmetric(
          vertical: 6,
        ),
        children: [
          // ALL
          _buildSidebarTile(
            label: 'All',
            isAll: true,
            image: '',
            selected:
                _selectedCategory == null,
            onTap: () {
              setState(() {
                _selectedCategory = null;
              });
            },
          ),

          // CATEGORIES
          for (final category in _categories)
            _buildSidebarTile(
              label: category.label,
              isAll: false,
              image: category.image,
              selected:
                  _selectedCategory ==
                      category.label,
              onTap: () {
                setState(() {
                  _selectedCategory =
                      category.label;
                });
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SIDEBAR TILE
  // ============================================================

  Widget _buildSidebarTile({
    required String label,
    required bool isAll,
    required String image,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected
            ? _Design.pageBg
            : Colors.transparent,

        padding:
            const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 6,
        ),

        child: Column(
          children: [
            // IMAGE
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(
                        0xFFEAF7E3,
                      )
                    : const Color(
                        0xFFF6F7F6,
                      ),
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(
                        color:
                            _Design.accent,
                        width: 1.4,
                      )
                    : null,
              ),
              alignment: Alignment.center,

              child: isAll
                  ? Icon(
                      Icons
                          .grid_view_rounded,
                      size: 22,
                      color: selected
                          ? _Design.accent
                          : Colors.black45,
                    )
                  : ClipOval(
                      child: Image.network(
                        image,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Icon(
                            Icons
                                .image_outlined,
                            size: 18,
                            color:
                                Colors.grey,
                          );
                        },
                      ),
                    ),
            ),

            const SizedBox(height: 5),

            // LABEL
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? _Design.textDark
                    : _Design.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildFilterRow(),

        Expanded(
          child: _buildProductArea(),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER ROW
  // ============================================================

  Widget _buildFilterRow() {
    return Container(
      color: Colors.white,

      padding:
          const EdgeInsets.fromLTRB(
        10,
        10,
        10,
        12,
      ),

      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal,

        child: Row(
          children: [
            // FILTER ICON
            _FilterIconButton(
              onTap: _showMoreFilters,
            ),

            const SizedBox(width: 8),

            // SORT
            _FilterChip(
              label: _sort ==
                      'Recommended'
                  ? 'Sort By'
                  : _sort,
              trailingIcon:
                  Icons.keyboard_arrow_down,
              active:
                  _sort != 'Recommended',
              onTap: _showSortSheet,
            ),

            const SizedBox(width: 8),

            // PRICE DROP
            _FilterChip(
              label: 'Price Drop',
              leadingIcon:
                  Icons.trending_down,
              leadingColor:
                  _priceDropOnly
                      ? _Design.accent
                      : Colors.redAccent,
              active: _priceDropOnly,
              onTap: () {
                setState(() {
                  _priceDropOnly =
                      !_priceDropOnly;
                });
              },
            ),

            // TYPE
            if (_types.isNotEmpty) ...[
              const SizedBox(width: 8),

              _FilterChip(
                label:
                    _selectedType ??
                        'Type',
                trailingIcon:
                    Icons.keyboard_arrow_down,
                active:
                    _selectedType != null,
                onTap: _showTypeSheet,
              ),
            ],

            // CLEAR
            if (_sort != 'Recommended' ||
                _priceDropOnly ||
                _selectedType != null) ...[
              const SizedBox(width: 8),

              _FilterChip(
                label: 'Clear',
                trailingIcon:
                    Icons.close,
                onTap: () {
                  setState(() {
                    _sort =
                        'Recommended';
                    _priceDropOnly =
                        false;
                    _selectedType =
                        null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SORT BOTTOM SHEET
  // ============================================================

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Padding(
                padding:
                    EdgeInsets.all(18),
                child: Text(
                  'Sort Products',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              for (final option
                  in _sortOptions)
                ListTile(
                  title:
                      Text(option),

                  trailing:
                      _sort == option
                          ? const Icon(
                              Icons.check,
                              color:
                                  _Design.accent,
                            )
                          : null,

                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    setState(() {
                      _sort = option;
                    });
                  },
                ),

              const SizedBox(
                height: 8,
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // TYPE BOTTOM SHEET
  // ============================================================

  void _showTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding:
                    EdgeInsets.all(18),
                child: Text(
                  'Filter by Type',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              // ALL TYPES
              ListTile(
                title:
                    const Text(
                  'All Types',
                ),

                trailing:
                    _selectedType == null
                        ? const Icon(
                            Icons.check,
                            color:
                                _Design.accent,
                          )
                        : null,

                onTap: () {
                  Navigator.pop(
                    context,
                  );

                  setState(() {
                    _selectedType =
                        null;
                  });
                },
              ),

              // TYPES
              for (final type in _types)
                ListTile(
                  title:
                      Text(type),

                  trailing:
                      _selectedType ==
                              type
                          ? const Icon(
                              Icons.check,
                              color:
                                  _Design.accent,
                            )
                          : null,

                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    setState(() {
                      _selectedType =
                          type;
                    });
                  },
                ),

              const SizedBox(
                height: 8,
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // MORE FILTERS
  // ============================================================

  void _showMoreFilters() {
    bool tempPriceDrop =
        _priceDropOnly;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder:
              (
            context,
            setModalState,
          ) {
            return SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  20,
                ),

                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // PRICE DROP
                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,

                      title:
                          const Text(
                        'Price Drop Only',
                      ),

                      value:
                          tempPriceDrop,

                      activeThumbColor:
                          _Design.accent,

                      onChanged:
                          (value) {
                        setModalState(
                          () {
                            tempPriceDrop =
                                value;
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // APPLY
                    SizedBox(
                      width:
                          double.infinity,

                      child:
                          ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );

                          setState(() {
                            _priceDropOnly =
                                tempPriceDrop;
                          });
                        },

                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              _Design.accent,
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          minimumSize:
                              const Size(
                            double.infinity,
                            48,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                          ),
                        ),

                        child:
                            const Text(
                          'Apply Filters',
                        ),
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

  // ============================================================
  // PRODUCT AREA
  // ============================================================

  Widget _buildProductArea() {
    final items =
        _filteredProducts;

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No products found.',
          style: TextStyle(
            color: _Design.textMuted,
          ),
        ),
      );
    }

    return Container(
      color: _Design.pageBg,

      child: GridView.builder(
        padding:
            const EdgeInsets.fromLTRB(
          10,
          6,
          10,
          16,
        ),

        itemCount: items.length,

        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),

        itemBuilder:
            (context, index) {
          return ProductCard(
            product: items[index],
          );
        },
      ),
    );
  }
}

// ============================================================
// FILTER CHIP
// ============================================================

class _FilterChip
    extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.leadingIcon,
    this.leadingColor,
    this.trailingIcon,
    this.active = false,
    required this.onTap,
  });

  final String label;

  final IconData? leadingIcon;

  final Color? leadingColor;

  final IconData? trailingIcon;

  final bool active;

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(20),

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),

        decoration:
            BoxDecoration(
          color: active
              ? const Color(
                  0xFFEAF7E3,
                )
              : const Color(
                  0xFFF6F7F6,
                ),

          borderRadius:
              BorderRadius.circular(
            20,
          ),

          border: active
              ? Border.all(
                  color:
                      _Design.accent,
                )
              : null,
        ),

        child: Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            // LEADING ICON
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 14,
                color: leadingColor ??
                    (active
                        ? _Design.accent
                        : Colors.black87),
              ),

              const SizedBox(
                width: 4,
              ),
            ],

            // LABEL
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight:
                    FontWeight.w600,
                color: active
                    ? _Design.accent
                    : Colors.black87,
              ),
            ),

            // TRAILING ICON
            if (trailingIcon != null) ...[
              const SizedBox(
                width: 1,
              ),

              Icon(
                trailingIcon,
                size: 17,
                color: active
                    ? _Design.accent
                    : Colors.black54,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FILTER ICON BUTTON
// ============================================================

class _FilterIconButton
    extends StatelessWidget {
  const _FilterIconButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(20),

      child: Container(
        width: 36,
        height: 36,

        decoration:
            const BoxDecoration(
          color: Color(
            0xFFF6F7F6,
          ),
          shape: BoxShape.circle,
        ),

        alignment:
            Alignment.center,

        child: const Icon(
          Icons.tune,
          size: 17,
          color: Colors.black87,
        ),
      ),
    );
  }
}