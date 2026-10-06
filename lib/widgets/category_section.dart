import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.products,
    required this.selectedCategory,
    required this.onSelectCategory,
    this.onSeeAll,
  });

  final List<Product> products;

  final String? selectedCategory;

  final ValueChanged<String?>
      onSelectCategory;

  final VoidCallback? onSeeAll;

  List<CategoryModel> _buildCategories() {
    final Map<String, CategoryModel>
        map = {};

    for (final product in products) {
      if (product.status != 'active') {
        continue;
      }

      if (product.category
          .trim()
          .isEmpty) {
        continue;
      }

      if (!map.containsKey(
        product.category,
      )) {
        map[product.category] =
            CategoryModel(
          id: product.category,
          label: product.category,
          image: product.image,
        );
      }
    }

    return [
      const CategoryModel(
        id: '__all__',
        label: 'All',
        image: '',
        isAll: true,
      ),
      ...map.values,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        _buildCategories();

    if (categories.length <= 1) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            12,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Shop by Category',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF111318),
                  ),
                ),
              ),

              GestureDetector(
                onTap: onSeeAll,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color:
                        Color(0xFF65B83D),
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 116,

          child: ListView.separated(
            scrollDirection:
                Axis.horizontal,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
            ),

            itemCount:
                categories.length,

            separatorBuilder:
                (_, _) =>
                    const SizedBox(
              width: 12,
            ),

            itemBuilder:
                (context, index) {
              final category =
                  categories[index];

              final active =
                  category.isAll
                      ? selectedCategory ==
                          null
                      : selectedCategory ==
                          category.label;

              return _CategoryTile(
                category: category,
                active: active,
                onTap: () {
                  if (category.isAll) {
                    onSelectCategory(null);
                    return;
                  }

                  if (selectedCategory ==
                      category.label) {
                    onSelectCategory(null);
                  } else {
                    onSelectCategory(
                      category.label,
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryTile
    extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.active,
    required this.onTap,
  });

  final CategoryModel category;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: SizedBox(
        width: 82,

        child: Column(
          children: [
            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 180,
              ),

              width: 70,
              height: 70,

              decoration:
                  BoxDecoration(
                color: active
                    ? const Color(
                        0xFFEAF7E3,
                      )
                    : Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),

                border: Border.all(
                  color: active
                      ? const Color(
                          0xFF65B83D,
                        )
                      : const Color(
                          0xFFEDEDED,
                        ),

                  width:
                      active ? 2 : 1,
                ),
              ),

              child:
                  category.isAll
                      ? const Icon(
                          Icons
                              .grid_view_rounded,
                          size: 30,
                          color:
                              Color(0xFF65B83D),
                        )
                      : ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            19,
                          ),
                          child:
                              Image.network(
                            category.image,

                            fit: BoxFit.cover,

                            width:
                                double.infinity,

                            height:
                                double.infinity,

                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const Icon(
                                Icons
                                    .image_outlined,
                                color:
                                    Colors.grey,
                              );
                            },
                          ),
                        ),
            ),

            const SizedBox(height: 7),

            Text(
              category.label,

              maxLines: 1,

              overflow:
                  TextOverflow.ellipsis,

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontSize: 12.5,

                fontWeight: active
                    ? FontWeight.w700
                    : FontWeight.w500,

                color: active
                    ? const Color(
                        0xFF65B83D,
                      )
                    : const Color(
                        0xFF333333,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}