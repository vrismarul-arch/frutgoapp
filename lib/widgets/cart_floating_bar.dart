import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';

class CartFloatingBar extends StatelessWidget {
  const CartFloatingBar({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final cart =
        context.watch<CartProvider>();

    if (cart.itemCount <= 0 ||
        cart.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleItems =
        cart.items.take(3).toList();

    return GestureDetector(
      behavior:
          HitTestBehavior.opaque,

      onTap: () {
        Navigator.pushNamed(
          context,
          '/cart',
        );
      },

      child: Container(
        height: 62,

        margin:
            const EdgeInsets.symmetric(
          horizontal: 18,
        ),

        constraints:
            const BoxConstraints(
          maxWidth: 285,
        ),

        decoration: BoxDecoration(
          // =====================================================
          // LIGHT GREEN GLASS
          // =====================================================

          color:
              const Color(0xFF65B83D)
                  .withValues(
            alpha: 0.92,
          ),

          borderRadius:
              BorderRadius.circular(18),

          // =====================================================
          // GLASS BORDER
          // =====================================================

          border: Border.all(
            color:
                Colors.white.withValues(
              alpha: 0.28,
            ),
            width: 1,
          ),

          // =====================================================
          // SOFT MORPHIC SHADOW
          // =====================================================

          boxShadow: [
            BoxShadow(
              color:
                  const Color(
                0xFF65B83D,
              ).withValues(
                alpha: 0.22,
              ),
              blurRadius: 18,
              spreadRadius: 1,
              offset:
                  const Offset(0, 6),
            ),

            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.08,
              ),
              blurRadius: 10,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          children: [
            const SizedBox(
              width: 18,
            ),

            // ===================================================
            // CART TEXT
            // ===================================================

            Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'CART',

                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                    height: 1,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  '${cart.itemCount} '
                  '${cart.itemCount == 1 ? 'ITEM' : 'ITEMS'}',

                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(
              width: 12,
            ),

            // ===================================================
            // PRODUCT IMAGES
            // ===================================================

            Expanded(
              child: SizedBox(
                height: 45,

                child: Stack(
                  clipBehavior:
                      Clip.none,

                  children: [
                    for (
                      int index = 0;
                      index <
                          visibleItems.length;
                      index++
                    )
                      Positioned(
                        left:
                            index * 30,
                        top: 2,

                        child:
                            _CartThumbnail(
                          image:
                              visibleItems[
                                      index]
                                  .image,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ===================================================
            // ARROW
            // ===================================================

            Container(
              width: 44,
              height: 44,

              margin:
                  const EdgeInsets.only(
                right: 8,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.white
                        .withValues(
                  alpha: 0.16,
                ),

                shape:
                    BoxShape.circle,

                border:
                    Border.all(
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.18,
                  ),
                  width: 1,
                ),
              ),

              child:
                  const Icon(
                Icons
                    .chevron_right_rounded,

                color:
                    Colors.white,

                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================================
// CART THUMBNAIL
// ===============================================================

class _CartThumbnail
    extends StatelessWidget {
  const _CartThumbnail({
    required this.image,
  });

  final String image;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 43,
      height: 43,

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(9),

        border:
            Border.all(
          color:
              Colors.white,
          width: 2,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.12,
            ),
            blurRadius: 5,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(7),

        child: image.isNotEmpty
            ? Image.network(
                image,

                fit:
                    BoxFit.cover,

                errorBuilder:
                    (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons
                        .shopping_bag,

                    color:
                        Color(
                      0xFF65B83D,
                    ),

                    size: 23,
                  );
                },
              )
            : const Icon(
                Icons
                    .shopping_bag,

                color:
                    Color(
                  0xFF65B83D,
                ),

                size: 23,
              ),
      ),
    );
  }
}