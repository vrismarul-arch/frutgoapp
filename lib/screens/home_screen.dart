import 'package:flutter/material.dart';

import '../widgets/home_header.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/product_section.dart';
import '../widgets/benefits_strip.dart';
import '../widgets/promo_slider.dart';
import '../widgets/brand_footer.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/cart_floating_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onNavigationTap(int index) {
    if (index == 0) {
      if (_currentIndex != 0) {
        setState(() {
          _currentIndex = 0;
        });
      }
      return;
    }

    if (index == 1) {
      Navigator.pushNamed(
        context,
        '/cart',
      );
      return;
    }

    if (index == 2) {
      Navigator.pushNamed(
        context,
        '/orders',
      );
      return;
    }

    if (index == 3) {
      Navigator.pushNamed(
        context,
        '/profile',
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const _HomeContent(),

            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: const Align(
                alignment: Alignment.center,
                child: CartFloatingBar(),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar:
          AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onNavigationTap,
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(
          child: HomeHeader(),
        ),

        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding:
                const EdgeInsets.fromLTRB(
              18,
              0,
              18,
              18,
            ),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFF4F5F3),
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color:
                      const Color(0xFFE9EBE8),
                ),
              ),
              child: const TextField(
                decoration:
                    InputDecoration(
                  hintText:
                      'Search fruits, vegetables & more',
                  hintStyle: TextStyle(
                    color:
                        Color(0xFF999D99),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color:
                        Color(0xFF666A66),
                  ),
                  suffixIcon: Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color:
                        Color(0xFF65B83D),
                  ),
                  border:
                      InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: BannerCarousel(),
        ),

        const SliverToBoxAdapter(
          child: ProductSection(),
        ),

        const SliverToBoxAdapter(
          child: BenefitsStrip(),
        ),

        const SliverToBoxAdapter(
          child: PromoSlider(
            title: 'Special Offers',
          ),
        ),

        const SliverToBoxAdapter(
          child: BrandFooter(),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(
            height: 120,
          ),
        ),
      ],
    );
  }
}