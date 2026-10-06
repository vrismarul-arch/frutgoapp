import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../screens/special_offers_page.dart';

class PromoSlider extends StatefulWidget {
  const PromoSlider({
    super.key,
    this.title = "Today's Special Offers",
  });

  final String title;

  @override
  State<PromoSlider> createState() =>
      _PromoSliderState();
}

class _PromoSliderState
    extends State<PromoSlider> {
  late final PageController _pageController;

  Timer? _autoPlayTimer;

  int _currentIndex = 0;

  bool _isLoading = true;

  String? _errorMessage;

  List<Map<String, dynamic>> _offers =
      [];

  @override
  void initState() {
    super.initState();

    _pageController =
        PageController(
      viewportFraction: 0.88,
    );

    _loadOffers();
  }

  // =====================================================
  // LOAD OFFERS
  // =====================================================

  Future<void> _loadOffers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final offers =
          await ApiService.instance
              .fetchOfferProducts();

      if (!mounted) {
        return;
      }

      setState(() {
        _offers = offers;
        _isLoading = false;
        _currentIndex = 0;
      });

      _startAutoPlay();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;

        _errorMessage =
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }
  }

  // =====================================================
  // AUTO PLAY
  // =====================================================

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();

    if (_offers.length <= 1) {
      return;
    }

    _autoPlayTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (!_pageController.hasClients ||
            _offers.isEmpty) {
          return;
        }

        final nextIndex =
            (_currentIndex + 1) %
                _offers.length;

        _pageController.animateToPage(
          nextIndex,
          duration:
              const Duration(
            milliseconds: 600,
          ),
          curve:
              Curves.easeInOutCubic,
        );
      },
    );
  }

  // =====================================================
  // OPEN SPECIAL OFFERS PAGE
  // =====================================================

  void _openOffers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SpecialOffersPage(),
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _autoPlayTimer?.cancel();

    _pageController.dispose();

    super.dispose();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    // ---------------------------------------------------
    // LOADING
    // ---------------------------------------------------

    if (_isLoading) {
      return const _PromoLoading();
    }

    // ---------------------------------------------------
    // ERROR
    // ---------------------------------------------------

    if (_errorMessage != null) {
      return _PromoError(
        message: _errorMessage!,
        onRetry: _loadOffers,
      );
    }

    // ---------------------------------------------------
    // NO OFFERS
    // ---------------------------------------------------

    if (_offers.isEmpty) {
      return const SizedBox.shrink();
    }

    // ---------------------------------------------------
    // CONTENT
    // ---------------------------------------------------

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // =================================================
        // HEADER
        // =================================================

        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF202420),
                  ),
                ),
              ),

              // VIEW ALL
              GestureDetector(
                onTap: _openOffers,
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style:
                            TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Color(
                            0xFF65B83D,
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 4,
                      ),

                      Icon(
                        Icons
                            .arrow_forward_ios_rounded,
                        size: 11,
                        color:
                            Color(
                          0xFF65B83D,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // =================================================
        // SLIDER
        // =================================================

        SizedBox(
          height: 205,
          child: PageView.builder(
            controller:
                _pageController,
            itemCount:
                _offers.length,
            physics:
                const BouncingScrollPhysics(),
            onPageChanged:
                (index) {
              if (!mounted) {
                return;
              }

              setState(() {
                _currentIndex =
                    index;
              });
            },
            itemBuilder:
                (
              context,
              index,
            ) {
              return AnimatedBuilder(
                animation:
                    _pageController,
                builder:
                    (
                  context,
                  child,
                ) {
                  double scale = 1.0;

                  if (_pageController
                      .hasClients) {
                    final page =
                        _pageController
                                .page ??
                            _currentIndex;

                    final distance =
                        (page - index)
                            .abs();

                    scale =
                        (1 -
                                distance *
                                    0.045)
                            .clamp(
                      0.94,
                      1.0,
                    );
                  }

                  return Transform.scale(
                    scale: scale,
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 6,
                        vertical: 5,
                      ),
                      child:
                          _SpecialOfferCard(
                        product:
                            _offers[index],
                        onTap:
                            _openOffers,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        // =================================================
        // DOTS
        // =================================================

        _PromoIndicator(
          count: _offers.length,
          currentIndex:
              _currentIndex,
        ),

        const SizedBox(
          height: 14,
        ),
      ],
    );
  }
}

// =========================================================
// SPECIAL OFFER CARD
// =========================================================

class _SpecialOfferCard
    extends StatelessWidget {
  const _SpecialOfferCard({
    required this.product,
    required this.onTap,
  });

  final Map<String, dynamic> product;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String name =
        _string(product['name']);

    final String category =
        _string(product['category']);

    final String image =
        _string(product['image']);

    final double price =
        _price(product);

    final int discount =
        _discount(product);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            18,
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.08,
              ),
              blurRadius: 14,
              offset:
                  const Offset(
                0,
                4,
              ),
            ),
          ],
        ),

        clipBehavior:
            Clip.antiAlias,

        child: Stack(
          fit: StackFit.expand,
          children: [
            // =============================================
            // IMAGE
            // =============================================

            image.isNotEmpty
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const
                          _ImagePlaceholder();
                    },
                  )
                : const
                    _ImagePlaceholder(),

            // =============================================
            // DARK GRADIENT
            // =============================================

            Positioned.fill(
              child: DecoratedBox(
                decoration:
                    BoxDecoration(
                  gradient:
                      LinearGradient(
                    begin:
                        Alignment.topCenter,
                    end:
                        Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black
                          .withValues(
                        alpha: 0.82,
                      ),
                    ],
                    stops: const [
                      0.35,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),

            // =============================================
            // OFFER BADGE
            // =============================================

            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF65B83D,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                ),
                child: Text(
                  '$discount% OFF',
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),

            // =============================================
            // OFFER ICON
            // =============================================

            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: 0.94,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons
                      .local_offer_rounded,
                  size: 19,
                  color:
                      Color(
                    0xFF65B83D,
                  ),
                ),
              ),
            ),

            // =============================================
            // PRODUCT DETAILS
            // =============================================

            Positioned(
              left: 15,
              right: 15,
              bottom: 14,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  if (category
                      .isNotEmpty)
                    Text(
                      category,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          TextStyle(
                        color: Colors
                            .white
                            .withValues(
                          alpha: 0.78,
                        ),
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    name.isEmpty
                        ? 'Special Offer'
                        : name,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Row(
                    children: [
                      Text(
                        price > 0
                            ? '₹${price.toStringAsFixed(0)}'
                            : 'Special Price',
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      if (discount > 0)
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .white
                                .withValues(
                              alpha: 0.18,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              5,
                            ),
                          ),
                          child:
                              const Text(
                            'Special Price',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // STRING
  // =====================================================

  String _string(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim();
  }

  // =====================================================
  // DISCOUNT
  // =====================================================

  int _discount(
    Map<String, dynamic> product,
  ) {
    final value =
        product['discount_percent'];

    if (value is num) {
      return value.round();
    }

    return int.tryParse(
          '$value',
        ) ??
        0;
  }

  // =====================================================
  // PRICE
  // =====================================================

  double _price(
    Map<String, dynamic> product,
  ) {
    final variants =
        product['variants'];

    if (variants is List &&
        variants.isNotEmpty) {
      final first =
          variants.first;

      if (first is Map) {
        final value =
            first['price'];

        if (value is num) {
          return value.toDouble();
        }

        return double.tryParse(
              '$value',
            ) ??
            0;
      }
    }

    final value =
        product['price'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          '$value',
        ) ??
        0;
  }
}

// =========================================================
// IMAGE PLACEHOLDER
// =========================================================

class _ImagePlaceholder
    extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      color:
          const Color(0xFFEFF2ED),
      alignment:
          Alignment.center,
      child:
          const Icon(
        Icons
            .image_not_supported_outlined,
        size: 38,
        color:
            Color(0xFF9AA099),
      ),
    );
  }
}

// =========================================================
// LOADING
// =========================================================

class _PromoLoading
    extends StatelessWidget {
  const _PromoLoading();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            10,
          ),
          child: Container(
            width: 210,
            height: 22,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFE3E7E1,
              ),
              borderRadius:
                  BorderRadius.circular(
                6,
              ),
            ),
          ),
        ),

        Container(
          height: 205,
          margin:
              const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFE3E7E1,
            ),
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
          child:
              const Center(
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
              color:
                  Color(0xFF65B83D),
            ),
          ),
        ),

        const SizedBox(
          height: 15,
        ),
      ],
    );
  }
}

// =========================================================
// ERROR
// =========================================================

class _PromoError
    extends StatelessWidget {
  const _PromoError({
    required this.message,
    required this.onRetry,
  });

  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        18,
      ),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(
          18,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFFF0F8ED,
          ),
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons
                  .local_offer_outlined,
              size: 32,
              color:
                  Color(0xFF65B83D),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Unable to load offers',
              style:
                  TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    Colors.grey,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            TextButton(
              onPressed:
                  onRetry,
              child:
                  const Text(
                'Retry',
                style:
                    TextStyle(
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
      ),
    );
  }
}

// =========================================================
// DOT INDICATOR
// =========================================================

class _PromoIndicator
    extends StatelessWidget {
  const _PromoIndicator({
    required this.count,
    required this.currentIndex,
  });

  final int count;

  final int currentIndex;

  @override
  Widget build(
    BuildContext context,
  ) {
    if (count <= 1) {
      return const SizedBox(
        height: 7,
      );
    }

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children:
          List.generate(
        count,
        (index) {
          final active =
              index ==
                  currentIndex;

          return AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 250,
            ),
            curve:
                Curves.easeOut,
            margin:
                const EdgeInsets
                    .symmetric(
              horizontal: 3,
            ),
            width:
                active ? 22 : 7,
            height: 7,
            decoration:
                BoxDecoration(
              color: active
                  ? const Color(
                      0xFF65B83D,
                    )
                  : const Color(
                      0xFFD0D3D0,
                    ),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
          );
        },
      ),
    );
  }
}