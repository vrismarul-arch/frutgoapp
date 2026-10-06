import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final cartProvider = context.watch<CartProvider>();

    final user = authProvider.user;

    // =========================================================
    // USER NAME
    // =========================================================

    final String userName =
        user != null && user.name.trim().isNotEmpty
            ? user.name.trim()
            : 'User';

    // =========================================================
    // USER AVATAR
    // =========================================================

    final String? avatar =
        user != null && user.avatar.trim().isNotEmpty
            ? user.avatar.trim()
            : null;

    // =========================================================
    // REAL CART COUNT
    // =========================================================

    final int cartCount = cartProvider.itemCount;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [

          // =====================================================
          // PROFILE AVATAR
          // =====================================================

          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/profile',
              );
            },
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    const Color(0xFFEAF5E5),
                border: Border.all(
                  color:
                      const Color(0xFFE5E5E5),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: avatar != null
                    ? Image.network(
                        avatar,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return _avatarFallback(
                            userName,
                          );
                        },
                      )
                    : _avatarFallback(
                        userName,
                      ),
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // =====================================================
          // WELCOME + USER NAME
          // =====================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [

                const Text(
                  'Welcome Back',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w400,
                    color:
                        Color(0xFF8A8A8A),
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Row(
                  children: [

                    Flexible(
                      child: Text(
                        userName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Color(0xFF151515),
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    const Text(
                      '👋',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // =====================================================
          // CART
          // =====================================================

          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/cart',
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [

                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      const BoxDecoration(
                    color:
                        Color(0xFFF8F8F8),
                    shape:
                        BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons
                        .shopping_bag_outlined,
                    size: 27,
                    color:
                        Color(0xFF171717),
                  ),
                ),

                // =================================================
                // REAL CART BADGE
                // =================================================

                if (cartCount > 0)
                  Positioned(
                    right: -3,
                    top: -4,
                    child: Container(
                      constraints:
                          const BoxConstraints(
                        minWidth: 19,
                        minHeight: 19,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 5,
                      ),
                      decoration:
                          const BoxDecoration(
                        color:
                            Color(0xFF65B83D),
                        shape:
                            BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$cartCount',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // AVATAR FALLBACK
  // ===========================================================

  Widget _avatarFallback(
    String name,
  ) {
    final String firstLetter =
        name.isNotEmpty
            ? name[0].toUpperCase()
            : 'U';

    return Container(
      width: 54,
      height: 54,
      color:
          const Color(0xFFEAF5E5),
      alignment:
          Alignment.center,
      child: Text(
        firstLetter,
        style:
            const TextStyle(
          fontSize: 22,
          fontWeight:
              FontWeight.bold,
          color:
              Color(0xFF3F8F26),
        ),
      ),
    );
  }
}