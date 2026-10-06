import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const Color green = Color(0xFF65B83D);

  // ==========================================================
  // ROUTE NAMES — same order as the nav items below
  // index 0 = Home, 1 = Cart, 2 = Profile
  // ==========================================================
  static const List<String> _routes = [
    '/home',
    '/cart',
    '/profile',
  ];

  // ==========================================================
  // HANDLE TAP — updates index AND navigates to the route
  // ==========================================================
  void _handleTap(BuildContext context, int index) {
    onTap(index);

    if (index == currentIndex) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      _routes[index],
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    final int cartCount = cart.itemCount;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            border: const Border(
              top: BorderSide(
                color: Color(0xFFEAEDE8),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,

              // ---- PROFILE ROUTE FIX ----
              onTap: (index) => _handleTap(context, index),

              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: green,
              unselectedItemColor: const Color(0xFF929692),
              selectedFontSize: 11,
              unselectedFontSize: 10,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              showUnselectedLabels: true,
              enableFeedback: true,
              items: [
                // =================================================
                // HOME
                // =================================================
                const BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Icon(Icons.home_outlined, size: 25),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Icon(Icons.home_rounded, size: 25),
                  ),
                  label: 'Home',
                ),

                // =================================================
                // CART
                // =================================================
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: _CartIcon(
                      count: cartCount,
                      active: false,
                    ),
                  ),
                  activeIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: _CartIcon(
                      count: cartCount,
                      active: true,
                    ),
                  ),
                  label: 'Cart',
                ),

                // =================================================
                // PROFILE
                // =================================================
                const BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 25,
                    ),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Icon(
                      Icons.person_rounded,
                      size: 25,
                    ),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// CART ICON
// =================================================================

class _CartIcon extends StatelessWidget {
  const _CartIcon({
    required this.count,
    required this.active,
  });

  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 29,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ======================================================
          // CART ICON
          // ======================================================
          Icon(
            active
                ? Icons.shopping_cart_rounded
                : Icons.shopping_cart_outlined,
            size: 25,
            color: active
                ? const Color(0xFF65B83D)
                : const Color(0xFF929692),
          ),

          // ======================================================
          // BADGE
          // ======================================================
          if (count > 0)
            Positioned(
              right: -5,
              top: -7,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF65B83D),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}