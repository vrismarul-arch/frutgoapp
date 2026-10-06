import 'dart:async';

import 'package:flutter/material.dart';

class BannerSlide {
  final int id;
  final String image;
  final String alt;

  const BannerSlide({
    required this.id,
    required this.image,
    required this.alt,
  });
}

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    this.slides = const [
      BannerSlide(
        id: 1,
        image: 'assets/banners/1.png',
        alt: 'Promotional banner 1',
      ),
      BannerSlide(
        id: 2,
        image: 'assets/banners/2.png',
        alt: 'Promotional banner 2',
      ),
      BannerSlide(
        id: 3,
        image: 'assets/banners/3.png',
        alt: 'Promotional banner 3',
      ),
    ],
    this.autoplay = true,
    this.autoplayDuration = const Duration(seconds: 4),
  });

  final List<BannerSlide> slides;
  final bool autoplay;
  final Duration autoplayDuration;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _pageController;

  Timer? _timer;

  int _currentIndex = 0;

  final Map<int, bool> _loadedImages = {};

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    if (widget.autoplay && widget.slides.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void didUpdateWidget(covariant BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Restart/stop autoplay if the config actually changed.
    if (widget.autoplay != oldWidget.autoplay ||
        widget.autoplayDuration != oldWidget.autoplayDuration ||
        widget.slides.length != oldWidget.slides.length) {
      _timer?.cancel();

      if (widget.autoplay && widget.slides.length > 1) {
        _startAutoPlay();
      }
    }
  }

  // =====================================================
  // AUTO PLAY
  // =====================================================

  void _startAutoPlay() {
    _timer?.cancel();

    _timer = Timer.periodic(
      widget.autoplayDuration,
      (_) {
        if (!mounted) return;

        if (!_pageController.hasClients) return;

        if (widget.slides.isEmpty) return;

        int nextIndex = _currentIndex + 1;

        if (nextIndex >= widget.slides.length) {
          nextIndex = 0;
        }

        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(
            milliseconds: 600,
          ),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  // =====================================================
  // IMAGE LOADED
  // =====================================================

  void _markImageLoaded(int id) {
    if (!mounted) return;

    if (_loadedImages[id] == true) return;

    setState(() {
      _loadedImages[id] = true;
    });
  }

  // =====================================================
  // RESPONSIVE HELPERS
  // =====================================================

  /// Returns a banner height that scales with screen width, so the
  /// carousel looks right on small phones, large phones, and tablets.
  double _bannerHeight(double screenWidth) {
    // Keep a roughly 16:9-ish banner, but clamp so it never gets
    // too short on tiny phones or too tall on large/tablet screens.
    final double proportional = screenWidth * 0.62;
    return proportional.clamp(180.0, 320.0);
  }

  /// Horizontal padding between the slider and the screen edge,
  /// scaled down slightly on narrow screens.
  double _horizontalMargin(double screenWidth) {
    if (screenWidth < 340) return 4;
    if (screenWidth < 400) return 6;
    return 8;
  }

  /// Dot indicator size scales a touch on very small/large screens.
  double _dotHeight(double screenWidth) {
    if (screenWidth < 340) return 5;
    if (screenWidth > 600) return 7;
    return 6;
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();

    super.dispose();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the layout's available width (falls back to the
        // MediaQuery screen width if constraints are unbounded).
        final double screenWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        final double bannerHeight = _bannerHeight(screenWidth);
        final double hMargin = _horizontalMargin(screenWidth);
        final double dotHeight = _dotHeight(screenWidth);
        final double dotSpacing = screenWidth < 340 ? 10 : 14;
        final double dotBottom = bannerHeight * 0.06;

        return Container(
          width: double.infinity,

          margin: const EdgeInsets.symmetric(
            vertical: 20,
          ),

          child: Stack(
            children: [
              // =================================================
              // BANNER SLIDER
              // =================================================

              SizedBox(
                height: bannerHeight,

                child: PageView.builder(
                  controller: _pageController,

                  itemCount: widget.slides.length,

                  onPageChanged: (index) {
                    if (!mounted) return;

                    setState(() {
                      _currentIndex = index;
                    });
                  },

                  itemBuilder: (context, index) {
                    final slide = widget.slides[index];

                    final bool isLoaded =
                        _loadedImages[slide.id] ?? false;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: hMargin,
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),

                        child: Container(
                          width: double.infinity,
                          height: double.infinity,

                          color: const Color(0xFFF1F5F9),

                          child: Semantics(
                            image: true,
                            label: slide.alt,
                            child: Stack(
                              fit: StackFit.expand,

                              children: [
                                // =================================
                                // LOADING SKELETON
                                // =================================

                                if (!isLoaded) const BannerSkeleton(),

                                // =================================
                                // IMAGE
                                // =================================

                                AnimatedOpacity(
                                  opacity: isLoaded ? 1.0 : 0.0,

                                  duration: const Duration(
                                    milliseconds: 300,
                                  ),

                                  child: Image.asset(
                                    slide.image,

                                    width: double.infinity,
                                    height: double.infinity,

                                    fit: BoxFit.cover,

                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return Container(
                                        color: const Color(0xFFF1F5F9),
                                        child: const Center(
                                          child: Icon(
                                            Icons
                                                .image_not_supported_outlined,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },

                                    frameBuilder: (
                                      context,
                                      child,
                                      frame,
                                      wasSynchronouslyLoaded,
                                    ) {
                                      if (frame != null ||
                                          wasSynchronouslyLoaded) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          _markImageLoaded(slide.id);
                                        });
                                      }

                                      return child;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // =================================================
              // DOTS
              // =================================================

              Positioned(
                left: hMargin + 20,
                bottom: dotBottom,

                child: Row(
                  children: List.generate(
                    widget.slides.length,
                    (index) {
                      final bool isActive = index == _currentIndex;

                      return AnimatedContainer(
                        duration: const Duration(
                          milliseconds: 250,
                        ),

                        margin: EdgeInsets.symmetric(
                          horizontal: dotSpacing / 2 - dotHeight / 2,
                        ),

                        width: isActive ? dotHeight * 3.3 : dotHeight,

                        height: dotHeight,

                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: isActive ? 1.0 : 0.6,
                          ),

                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =======================================================
// SKELETON
// =======================================================

class BannerSkeleton extends StatefulWidget {
  const BannerSkeleton({
    super.key,
  });

  @override
  State<BannerSkeleton> createState() => _BannerSkeletonState();
}

class _BannerSkeletonState extends State<BannerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1200,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,

      builder: (context, child) {
        final double position = (_controller.value * 2) - 1;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                position - 1,
                0,
              ),
              end: Alignment(
                position + 1,
                0,
              ),
              colors: const [
                Color(0xFFE5E7EB),
                Color(0xFFF3F4F6),
                Color(0xFFE5E7EB),
              ],
            ),
          ),
        );
      },
    );
  }
}