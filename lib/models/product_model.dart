// ============================================================
// Product + ProductVariant models
//
// Handles the different field names returned by the API:
//
// price:
//   price | sellingPrice | discountedPrice | finalPrice
//
// old price:
//   oldPrice | mrp | originalPrice | compareAtPrice
//
// discount:
//   discountPercentage | discount |
//   discountPercent | discount_percent
// ============================================================

class ProductVariant {
  final String id;
  final String unit;
  final String label;
  final double price;

  const ProductVariant({
    required this.id,
    required this.unit,
    required this.label,
    required this.price,
  });

  factory ProductVariant.fromJson(
    Map<String, dynamic> json,
  ) {
    final unit =
        '${json['unit'] ?? json['unitType'] ?? 'weight'}';

    final label =
        '${json['label'] ??
            json['size'] ??
            json['weight'] ??
            (json['amount'] != null
                ? '${json['amount']}$unit'
                : unit)}';

    return ProductVariant(
      id: '${json['_id'] ?? json['id'] ?? ''}',

      unit: unit,

      label: label.isEmpty
          ? unit
          : label,

      price: _numFrom(
        json,
        [
          'price',
          'sellingPrice',
          'discountedPrice',
          'finalPrice',
        ],
      ),
    );
  }
}

// ============================================================
// Product
// ============================================================

class Product {
  final String id;
  final String name;
  final String category;
  final String image;
  final String status;

  final double rating;
  final dynamic reviews;

  final bool isSpecialOffer;
  final double discountPercent;

  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.status,
    required this.rating,
    required this.reviews,
    required this.isSpecialOffer,
    required this.discountPercent,
    required this.variants,
  });

  factory Product.fromJson(
    Map<String, dynamic> json,
  ) {
    // --------------------------------------------------------
    // VARIANTS
    // --------------------------------------------------------

    final rawVariants =
        json['variants'];

    var variants = rawVariants is List
        ? rawVariants
            .whereType<Map>()
            .map(
              (v) =>
                  ProductVariant.fromJson(
                Map<String, dynamic>.from(v),
              ),
            )
            .toList()
        : <ProductVariant>[];

    // --------------------------------------------------------
    // FALLBACK VARIANT
    //
    // If backend doesn't return variants,
    // create one from top-level product price.
    // --------------------------------------------------------

    if (variants.isEmpty) {
      variants = [
        ProductVariant(
          id:
              '${json['_id'] ?? json['id'] ?? ''}',

          unit:
              '${json['unit'] ?? 'weight'}',

          label:
              '${json['label'] ??
                  json['unit'] ??
                  'weight'}',

          price: _numFrom(
            json,
            [
              'price',
              'sellingPrice',
              'discountedPrice',
              'finalPrice',
            ],
          ),
        ),
      ];
    }

    // --------------------------------------------------------
    // DISCOUNT
    // --------------------------------------------------------

    double discountPercent =
        _numFrom(
      json,
      [
        'discountPercentage',
        'discount',
        'discountPercent',
        'discount_percent',
      ],
    );

    // If discount percentage is not available,
    // calculate it from old price and current price.

    if (discountPercent <= 0 &&
        variants.isNotEmpty) {
      final price =
          variants.first.price;

      final oldPrice =
          _numFrom(
        json,
        [
          'oldPrice',
          'mrp',
          'originalPrice',
          'compareAtPrice',
        ],
      );

      if (oldPrice > price &&
          price > 0) {
        discountPercent =
            ((oldPrice - price) /
                    oldPrice) *
                100;
      }
    }

    // --------------------------------------------------------
    // IMAGE
    // --------------------------------------------------------

    String image =
        '${json['image'] ??
            json['imageUrl'] ??
            json['thumbnail'] ??
            ''}';

    if (image.isEmpty) {
      final images =
          json['images'];

      if (images is List &&
          images.isNotEmpty) {
        image =
            images.first.toString();
      }
    }

    // --------------------------------------------------------
    // RETURN PRODUCT
    // --------------------------------------------------------

    return Product(
      id:
          '${json['_id'] ?? json['id'] ?? ''}',

      name:
          '${json['name'] ??
              json['title'] ??
              ''}',

      category:
          '${json['category'] ??
              json['categoryName'] ??
              ''}',

      image: image,

      status:
          '${json['status'] ?? ''}',

      rating:
          double.tryParse(
                '${json['rating'] ??
                    json['avgRating'] ??
                    4.5}',
              ) ??
              4.5,

      reviews:
          json['reviews'] ??
              json['reviewCount'] ??
              json['numReviews'] ??
              'New',

      isSpecialOffer:
          json['is_special_offer'] ==
                  true ||
              discountPercent > 0,

      discountPercent:
          discountPercent < 0
              ? 0
              : discountPercent,

      variants: variants,
    );
  }

  // ----------------------------------------------------------
  // Convenience getters
  // ----------------------------------------------------------

  double get startingPrice {
    if (variants.isEmpty) {
      return 0;
    }

    double lowest =
        variants.first.price;

    for (final variant in variants) {
      if (variant.price < lowest) {
        lowest = variant.price;
      }
    }

    return lowest;
  }

  ProductVariant?
      get defaultVariant {
    if (variants.isEmpty) {
      return null;
    }

    return variants.first;
  }
}

// ============================================================
// Helper
// ============================================================

double _numFrom(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];

    if (value == null) {
      continue;
    }

    final parsed =
        double.tryParse('$value');

    if (parsed != null &&
        parsed > 0) {
      return parsed;
    }
  }

  return 0;
}