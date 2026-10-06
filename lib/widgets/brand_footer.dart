import 'package:flutter/material.dart';

class BrandFooter extends StatefulWidget {
  const BrandFooter({
    super.key,
  });

  @override
  State<BrandFooter> createState() =>
      _BrandFooterState();
}

class _BrandFooterState
    extends State<BrandFooter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _heartAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,

      child: SlideTransition(
        position: _slideAnimation,

        child: Container(
          width: double.infinity,

          margin: const EdgeInsets.only(
            top: 10,
          ),

          padding: const EdgeInsets.fromLTRB(
            24,
            42,
            24,
            45,
          ),

          decoration: const BoxDecoration(
            color: Color(0xFFF1F3F3),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // =========================================
              // BRAND
              // =========================================

              Text(
                'frutgo',
                style: TextStyle(
                  fontSize: 56,
                  height: 0.95,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: -2.5,
                  color:
                      const Color(0xFFB6B8B9),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // =========================================
              // TAGLINE
              // =========================================

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center,

                children: [
                  const Flexible(
                    child: Text(
                      'Freshness crafted with ',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.25,
                        fontWeight:
                            FontWeight.w400,
                        color:
                            Color(0xFF858889),
                      ),
                    ),
                  ),

                  // HEART
                 ScaleTransition(
  scale: _heartAnimation,
  child: const Padding(
    padding: EdgeInsets.symmetric(
      horizontal: 3,
    ),
    child: Icon(
      Icons.favorite,
      size: 22,
      color: Color(0xFFF97801),
    ),
  ),
),

                  const Flexible(
                    child: Text(
                      ' for every home',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.25,
                        fontWeight:
                            FontWeight.w400,
                        color:
                            Color(0xFF858889),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 25,
              ),

              // =========================================
              // SMALL DIVIDER
              // =========================================

              Container(
                height: 1,
                color:
                    const Color(0xFFE0E2E2),
              ),

              const SizedBox(
                height: 20,
              ),

              // =========================================
              // FOOTER TEXT
              // =========================================

              const Text(
                'Fresh groceries. Fast delivery. Better living.',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      Color(0xFF9A9C9D),
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}